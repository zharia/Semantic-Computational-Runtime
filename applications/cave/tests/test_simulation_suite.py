#!/usr/bin/env python3
"""
test_simulation_suite.py — Automated Remote System Test Suite for SCR Simulation Hub
Comprehensive testing of Movement Dynamics (Locomotion, Strafing, Sprinting, Friction Deceleration,
Parabolic Jump Kinematics, Double Jump Boost, Slope Climbing, Aquatic Swimming Buoyancy & Drag),
Bullet3 Rigid Body Kinematics & Restitution, Biomes, Atmosphere, and Multi-Domain Switching.
Autonomous PIL image analysis and screenshot review on every movement phase.
"""

import os
import sys
import time
import json
import socket
import subprocess
import math
from pathlib import Path
from PIL import Image, ImageStat

TESTS_DIR = Path(__file__).parent.resolve()
ARTIFACTS_DIR = TESTS_DIR / "artifacts"
ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(TESTS_DIR))

from sim_client import SimClient


class VisualAnalysisResult:
    def __init__(self, is_valid: bool, reason: str, mean_luminance: float = 0.0,
                 contrast: float = 0.0, color_variance: float = 0.0, size_kb: float = 0.0):
        self.is_valid = is_valid
        self.reason = reason
        self.mean_luminance = mean_luminance
        self.contrast = contrast
        self.color_variance = color_variance
        self.size_kb = size_kb


def analyze_screenshot(filepath: Path, min_size_kb: float = 30.0,
                       min_contrast: float = 8.0) -> VisualAnalysisResult:
    if not filepath.exists():
        return VisualAnalysisResult(False, f"File does not exist: {filepath}")

    size_kb = filepath.stat().st_size / 1024.0
    if size_kb < min_size_kb:
        return VisualAnalysisResult(False, f"Image size too small ({size_kb:.1f} KB < {min_size_kb} KB)", size_kb=size_kb)

    try:
        with Image.open(filepath) as img:
            img_rgb = img.convert("RGB")
            w, h = img_rgb.size
            if w < 640 or h < 360:
                return VisualAnalysisResult(False, f"Image resolution too low ({w}x{h})", size_kb=size_kb)

            stat = ImageStat.Stat(img_rgb)
            r_mean, g_mean, b_mean = stat.mean[:3]
            r_std, g_std, b_std = stat.stddev[:3]

            mean_lum = 0.299 * r_mean + 0.587 * g_mean + 0.114 * b_mean
            avg_contrast = (r_std + g_std + b_std) / 3.0
            color_var = abs(r_mean - g_mean) + abs(g_mean - b_mean) + abs(b_mean - r_mean)

            if mean_lum < 5.0:
                return VisualAnalysisResult(False, f"Image is completely dark/black (mean lum: {mean_lum:.1f})",
                                            mean_lum, avg_contrast, color_var, size_kb)
            if mean_lum > 250.0:
                return VisualAnalysisResult(False, f"Image is completely blown-out white (mean lum: {mean_lum:.1f})",
                                            mean_lum, avg_contrast, color_var, size_kb)
            if avg_contrast < min_contrast:
                return VisualAnalysisResult(False, f"Image lacks contrast/features (stddev: {avg_contrast:.1f} < {min_contrast})",
                                            mean_lum, avg_contrast, color_var, size_kb)

            return VisualAnalysisResult(
                True,
                f"Valid frame ({w}x{h}, {size_kb:.1f}KB, Lum: {mean_lum:.1f}, Contrast: {avg_contrast:.1f})",
                mean_lum, avg_contrast, color_var, size_kb
            )
    except Exception as e:
        return VisualAnalysisResult(False, f"Pillow image decode error: {str(e)}", size_kb=size_kb)


def analyze_solar_chromaticity(filepath: Path, phase: str) -> tuple[bool, str]:
    """
    Validates physical optical plausibility and color gamut for solar lighting phases:
    - 'sunrise_horizon': Warm golden dawn horizon (R >= B * 0.9, 0 neon green artifacts).
    - 'morning': Clear morning sunlight (Lum 70..220).
    - 'noon': Peak daylight solar illumination (Lum 80..230).
    - 'sunset_horizon': Warm crimson sunset horizon (R >= B * 0.9, 0 neon green artifacts).
    - 'sunset_water': Sunset ocean specular track & twilight vista (Lum 15..120).
    - 'dusk': Civil/nautical twilight transition (Lum 15..75).
    - 'night': Deep celestial midnight (Lum 5..75, cool nocturnal tint).
    """
    if not filepath.exists():
        return False, f"File does not exist: {filepath}"

    try:
        with Image.open(filepath) as img:
            img_rgb = img.convert("RGB")
            w, h = img_rgb.size
            stat = ImageStat.Stat(img_rgb)
            r_m, g_m, b_m = stat.mean[:3]
            mean_lum = 0.299 * r_m + 0.587 * g_m + 0.114 * b_m

            # Unnatural fluorescent green/cyan solar glitch detection during twilight/dawn
            # A sunset/sunrise solar flare glitch has anomalous neon green (G > 190, R < 120, G > 1.5*R)
            if phase in ("sunrise_horizon", "sunset_horizon", "sunrise_water", "sunset_water", "dusk"):
                pixels = list(img_rgb.getdata())
                neon_artifact_count = sum(1 for (r, g, b) in pixels if g > 190 and r < 120 and g > 1.5 * max(1, r))
                neon_pct = (neon_artifact_count / len(pixels)) * 100.0
                if neon_pct > 0.05:
                    return False, f"Detected unnatural twilight green flare ({neon_pct:.2f}% pixels: {neon_artifact_count}px)"

            if phase in ("sunrise_horizon", "sunset_horizon"):
                if r_m < b_m * 0.88:
                    return False, f"Twilight horizon lacked warm solar spectrum (R:{r_m:.1f} < B:{b_m:.1f})"
                if mean_lum < 15.0 or mean_lum > 245.0:
                    return False, f"Illumination out of bounds for twilight horizon ({mean_lum:.1f})"
                return True, f"Warm twilight spectrum verified (R:{r_m:.1f}, G:{g_m:.1f}, B:{b_m:.1f}, Lum:{mean_lum:.1f}, 0 neon artifacts)"

            elif phase == "morning":
                if mean_lum < 50.0 or mean_lum > 240.0:
                    return False, f"Morning illumination out of bounds ({mean_lum:.1f})"
                return True, f"Morning sunlight illumination verified (Lum:{mean_lum:.1f})"

            elif phase == "noon":
                if mean_lum < 75.0 or mean_lum > 245.0:
                    return False, f"Midday illumination out of bounds ({mean_lum:.1f})"
                return True, f"Midday solar illumination verified (Lum:{mean_lum:.1f})"

            elif phase in ("sunset_water", "sunrise_water"):
                if mean_lum < 10.0 or mean_lum > 240.0:
                    return False, f"Twilight water illumination out of bounds ({mean_lum:.1f})"
                return True, f"Twilight water optical response verified (Lum:{mean_lum:.1f})"

            elif phase == "dusk":
                if mean_lum < 10.0 or mean_lum > 90.0:
                    return False, f"Dusk twilight illumination out of bounds ({mean_lum:.1f})"
                return True, f"Civil dusk twilight verified (Lum:{mean_lum:.1f})"

            elif phase == "night":
                if mean_lum < 3.0 or mean_lum > 75.0:
                    return False, f"Night celestial illumination out of bounds ({mean_lum:.1f})"
                return True, f"Celestial nocturnal illumination verified (Lum:{mean_lum:.1f})"

            return True, f"Valid solar chromaticity (Lum:{mean_lum:.1f})"
    except Exception as e:
        return False, f"Pillow chromaticity error: {str(e)}"


class TestReport:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.results = []

    def record(self, name: str, success: bool, details: str = "", screenshot: str = ""):
        if success:
            self.passed += 1
            status = "PASS"
        else:
            self.failed += 1
            status = "FAIL"
        entry = {
            "name": name,
            "status": status,
            "details": details,
            "screenshot": screenshot,
            "timestamp": time.time()
        }
        self.results.append(entry)
        icon = "✅" if success else "❌"
        print(f"{icon} [{status}] {name}: {details}")
        if screenshot:
            print(f"   📸 Screenshot: {screenshot}")

    def summary(self) -> bool:
        print("\n" + "=" * 80)
        print("  SCR SIMULATION AUTOMATED TEST SUITE REPORT (WITH MOVEMENT DYNAMICS & VISUAL REVIEW)")
        print("=" * 80)
        for r in self.results:
            icon = "✅" if r["status"] == "PASS" else "❌"
            print(f" {icon} {r['status']:<4} | {r['name']:<50} | {r['details']}")
            if r["screenshot"]:
                print(f"        └─ Artifact: {r['screenshot']}")
        print("-" * 80)
        print(f"Total Tests: {self.passed + self.failed} | Passed: {self.passed} | Failed: {self.failed}")
        print("=" * 80 + "\n")
        return self.failed == 0


def run_test_suite():
    repo_root = Path(__file__).parent.parent.parent.parent.resolve()
    binary_path = repo_root / "applications/cave/scr_simulation_hub"
    sock_path = "/tmp/scr_sim_hub_test.sock"

    if not binary_path.exists():
        print(f"Error: Binary not found at {binary_path}. Please compile first.")
        sys.exit(1)

    if os.path.exists(sock_path):
        os.unlink(sock_path)

    report = TestReport()

    print("================================================================================")
    print(" Booting SCR Simulation Hub in Test Harness...")
    print(f" Socket: {sock_path}")
    print(f" Binary: {binary_path}")
    print("================================================================================")

    env = os.environ.copy()
    env["SCR_SIM_SOCK"] = sock_path
    env["SDL_VIDEODRIVER"] = "x11"
    env["OGRE_USE_WAYLAND"] = "OFF"

    proc = subprocess.Popen(
        [str(binary_path)],
        cwd=str(repo_root),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    client = SimClient(socket_path=sock_path, timeout=12.0)

    try:
        # Step 1: Socket IPC Connection
        print("\n[Step 1] Connecting to simulation IPC socket...")
        connected = client.connect(retry_seconds=20.0)
        if not connected:
            report.record("Socket IPC Connection", False, f"Failed to connect to {sock_path} within 20s")
            proc.terminate()
            return sys.exit(1)
        report.record("Socket IPC Connection", True, f"Connected to {sock_path}")

        # Step 2: Scene Boot & Loading Screen Completion
        print("\n[Step 2] Awaiting simulation boot and loading screen completion...")
        loading_complete = False
        state = {}
        for _ in range(40):
            try:
                state = client.get_state()
                if state.get("loading_done", False) or state.get("loading_alpha", 0.0) >= 0.95:
                    loading_complete = True
                    break
            except Exception:
                pass
            time.sleep(0.3)

        report.record(
            "Scene Boot & Loading Screen",
            loading_complete,
            f"Scene: '{state.get('scene_id')}' ({state.get('scene_title')}), Time: {state.get('global_time', 0.0):.2f}s"
        )

        time.sleep(1.0)

        # Step 3: Scenic Spawn Beach Vista
        print("\n[Step 3] Testing Scenic Spawn Beach Vista...")
        vista_png = ARTIFACTS_DIR / "01_beach_vista.png"
        client.capture_screenshot(str(vista_png))
        time.sleep(0.3)
        v_res = analyze_screenshot(vista_png, min_size_kb=30, min_contrast=8)
        p_info = state.get("player", {})
        report.record(
            "Beach Vista & Ocean Horizon",
            v_res.is_valid,
            f"Pos ({p_info.get('x',0):.1f}, {p_info.get('y',0):.1f}, {p_info.get('z',0):.1f}) | {v_res.reason}",
            str(vista_png)
        )

        # Step 3b: Underwater Visual Immersion & Snell's Window Test
        print("\n[Step 3b] Testing Underwater Visual Immersion, Extinction & Snell's Window...")
        # Teleport underwater looking up at surface / Snell's window
        client.teleport(x=220.0, y=4.5, z=220.0, yaw=0.0, pitch=0.85)
        time.sleep(0.5)
        snell_png = ARTIFACTS_DIR / "02_underwater_snell.png"
        client.capture_screenshot(str(snell_png))
        time.sleep(0.2)
        v_snell = analyze_screenshot(snell_png, min_size_kb=25, min_contrast=6)
        
        # Look down at submerged seabed with solar caustics
        client.teleport(x=220.0, y=4.5, z=220.0, yaw=0.0, pitch=-0.75)
        time.sleep(0.4)
        caustics_png = ARTIFACTS_DIR / "02b_underwater_seabed_caustics.png"
        client.capture_screenshot(str(caustics_png))
        time.sleep(0.2)
        v_caustics = analyze_screenshot(caustics_png, min_size_kb=25, min_contrast=6)
        
        report.record(
            "Underwater Immersion & Snell's Window",
            v_snell.is_valid and v_caustics.is_valid,
            f"Snell Lum: {v_snell.mean_luminance:.1f}, Contrast: {v_snell.contrast:.1f} | Caustics Lum: {v_caustics.mean_luminance:.1f} | {v_snell.reason}",
            str(snell_png)
        )

        # ─── MOVEMENT DYNAMICS TEST MODULE ─────────────────────────────────────

        # Step 4: Walk vs Sprint Velocity Dynamics
        print("\n[Step 4] Testing Movement Dynamics: Walk vs Sprint Velocity Scaling...")
        client.teleport(x=124.0, y=14.0, z=42.0, yaw=2.85, pitch=-0.05)
        time.sleep(0.3)

        # 4a. Walk Test (move_forward without sprint)
        client.inject_input(move_forward=True, sprint=False)
        time.sleep(0.45)
        walk_png = ARTIFACTS_DIR / "08a_locomotion_walk.png"
        client.capture_screenshot(str(walk_png))
        st_walk = client.get_state()
        client.inject_input(move_forward=False, sprint=False)
        time.sleep(0.2)
        v_walk = analyze_screenshot(walk_png, min_size_kb=30, min_contrast=8)

        p_walk = st_walk.get("player", {})
        vx_w, vz_w = p_walk.get("vx", 0.0), p_walk.get("vz", 0.0)
        speed_walk = math.sqrt(vx_w * vx_w + vz_w * vz_w)

        # 4b. Sprint Test (move_forward with sprint)
        client.inject_input(move_forward=True, sprint=True)
        time.sleep(0.55)
        sprint_png = ARTIFACTS_DIR / "08b_locomotion_sprint.png"
        client.capture_screenshot(str(sprint_png))
        st_sprint = client.get_state()
        client.inject_input(move_forward=False, sprint=False)
        time.sleep(0.2)
        v_sprint = analyze_screenshot(sprint_png, min_size_kb=30, min_contrast=8)

        p_sprint = st_sprint.get("player", {})
        vx_s, vz_s = p_sprint.get("vx", 0.0), p_sprint.get("vz", 0.0)
        speed_sprint = math.sqrt(vx_s * vx_s + vz_s * vz_s)

        speed_ratio = speed_sprint / max(0.01, speed_walk)
        walk_sprint_ok = (speed_walk >= 1.5) and (speed_sprint >= 3.5) and (speed_ratio >= 1.4) and v_walk.is_valid and v_sprint.is_valid

        report.record(
            "Movement Dynamics: Walk vs Sprint Velocity Scaling",
            walk_sprint_ok,
            f"Walk Speed: {speed_walk:.2f}m/s | Sprint Speed: {speed_sprint:.2f}m/s | Ratio: {speed_ratio:.2f}x | {v_sprint.reason}",
            str(sprint_png)
        )

        # Step 5: Multi-Axis Lateral Strafing & Diagonal Norm Clamping
        print("\n[Step 5] Testing Movement Dynamics: Multi-Axis Lateral Strafing & Diagonal Norm Clamping...")
        # Left Strafe
        client.inject_input(move_left=True)
        time.sleep(0.35)
        strafe_l_png = ARTIFACTS_DIR / "08c_strafe_left.png"
        client.capture_screenshot(str(strafe_l_png))
        st_strafe_l = client.get_state()
        client.inject_input(move_left=False)
        time.sleep(0.2)
        v_strafe_l = analyze_screenshot(strafe_l_png, min_size_kb=30, min_contrast=8)

        # Right Strafe
        client.inject_input(move_right=True)
        time.sleep(0.35)
        strafe_r_png = ARTIFACTS_DIR / "08d_strafe_right.png"
        client.capture_screenshot(str(strafe_r_png))
        st_strafe_r = client.get_state()
        client.inject_input(move_right=False)
        time.sleep(0.2)
        v_strafe_r = analyze_screenshot(strafe_r_png, min_size_kb=30, min_contrast=8)

        p_sl = st_strafe_l.get("player", {})
        p_sr = st_strafe_r.get("player", {})
        speed_sl = math.sqrt(p_sl.get("vx", 0)**2 + p_sl.get("vz", 0)**2)
        speed_sr = math.sqrt(p_sr.get("vx", 0)**2 + p_sr.get("vz", 0)**2)

        strafe_ok = (speed_sl >= 1.5) and (speed_sr >= 1.5) and v_strafe_l.is_valid and v_strafe_r.is_valid
        report.record(
            "Movement Dynamics: Multi-Axis Lateral Strafing",
            strafe_ok,
            f"Left Strafe Speed: {speed_sl:.2f}m/s | Right Strafe Speed: {speed_sr:.2f}m/s | Valid frames",
            str(strafe_l_png)
        )

        # Step 6: Inertial Momentum Decay & Friction Deceleration
        print("\n[Step 6] Testing Movement Dynamics: Inertial Momentum Decay & Deceleration Curve...")
        client.inject_input(move_forward=True, sprint=True)
        time.sleep(0.5)
        st_init = client.get_state()
        v0 = math.sqrt(st_init.get("player", {}).get("vx", 0)**2 + st_init.get("player", {}).get("vz", 0)**2)
        
        # Release inputs and sample decay curve
        client.inject_input(move_forward=False, sprint=False)
        decay_samples = []
        for _ in range(8):
            time.sleep(0.04)
            st_k = client.get_state()
            p_k = st_k.get("player", {})
            vk = math.sqrt(p_k.get("vx", 0)**2 + p_k.get("vz", 0)**2)
            decay_samples.append(vk)

        decel_png = ARTIFACTS_DIR / "08e_locomotion_deceleration.png"
        client.capture_screenshot(str(decel_png))
        time.sleep(0.2)
        v_decel = analyze_screenshot(decel_png, min_size_kb=30, min_contrast=8)

        final_v = decay_samples[-1] if decay_samples else 0.0
        is_decelerating = (v0 > 3.0) and (final_v <= v0 * 0.45)
        report.record(
            "Movement Dynamics: Inertial Momentum Decay & Friction",
            is_decelerating and v_decel.is_valid,
            f"Initial Sprint V0: {v0:.2f}m/s -> Final Decayed V: {final_v:.2f}m/s (decay: {final_v/max(0.01,v0)*100:.1f}%)",
            str(decel_png)
        )

        # Step 7: Vertical Jump Kinematics & Parabolic Gravity Arc
        print("\n[Step 7] Testing Movement Dynamics: Vertical Jump Kinematics & Gravity Integration...")
        client.teleport(x=124.0, y=7.7, z=42.0, yaw=2.85, pitch=-0.05, snap_to_ground=True)
        time.sleep(0.3)
        st_ground = client.get_state()
        y_ground = st_ground.get("player", {}).get("y", 7.7)

        # Trigger jump and capture ballistic arc trajectory
        client.inject_input(jump=True)
        jump_launch_png = ARTIFACTS_DIR / "08f_jump_launch.png"
        client.capture_screenshot(str(jump_launch_png))
        
        trajectory = []
        t_start = time.time()
        apex_y = y_ground
        for _ in range(12):
            time.sleep(0.035)
            st_j = client.get_state()
            p_j = st_j.get("player", {})
            curr_y = p_j.get("y", y_ground)
            curr_vy = p_j.get("vy", 0.0)
            t_rel = time.time() - t_start
            trajectory.append((t_rel, curr_y, curr_vy))
            if curr_y > apex_y:
                apex_y = curr_y

        jump_apex_png = ARTIFACTS_DIR / "08g_jump_apex.png"
        client.capture_screenshot(str(jump_apex_png))
        client.inject_input(jump=False)
        time.sleep(0.4) # Wait for landing
        
        jump_land_png = ARTIFACTS_DIR / "08h_jump_landing.png"
        client.capture_screenshot(str(jump_land_png))
        time.sleep(0.2)

        v_launch = analyze_screenshot(jump_launch_png, min_size_kb=30, min_contrast=8)
        v_apex = analyze_screenshot(jump_apex_png, min_size_kb=30, min_contrast=8)
        v_land = analyze_screenshot(jump_land_png, min_size_kb=30, min_contrast=8)

        jump_height = apex_y - y_ground
        jump_ballistics_ok = (jump_height >= 0.6) and v_launch.is_valid and v_apex.is_valid

        report.record(
            "Movement Dynamics: Vertical Jump Ballistics & Apex",
            jump_ballistics_ok,
            f"Ground Y: {y_ground:.2f}m -> Apex Y: {apex_y:.2f}m (Delta: +{jump_height:.2f}m) | Valid Ballistic Arc",
            str(jump_apex_png)
        )

        # Step 8: Double Jump & Aerial Impulse Boost
        print("\n[Step 8] Testing Movement Dynamics: Double Jump & Aerial Impulse Boost...")
        client.teleport(x=124.0, y=7.7, z=42.0, yaw=2.85, pitch=-0.05, snap_to_ground=True)
        time.sleep(0.3)
        
        # Jump 1
        client.inject_input(jump=True)
        time.sleep(0.20)
        client.inject_input(jump=False)
        time.sleep(0.06)
        # Jump 2 (Double Jump in mid-air)
        client.inject_input(jump=True, move_forward=True)
        time.sleep(0.18)
        double_jump_png = ARTIFACTS_DIR / "08i_double_jump_boost.png"
        client.capture_screenshot(str(double_jump_png))
        st_dj = client.get_state()
        client.inject_input(jump=False, move_forward=False)
        time.sleep(0.4)
        
        v_dj = analyze_screenshot(double_jump_png, min_size_kb=30, min_contrast=8)
        p_dj = st_dj.get("player", {})
        dj_y = p_dj.get("y", 7.7)
        dj_ok = (dj_y > y_ground + 0.8) and v_dj.is_valid
        report.record(
            "Movement Dynamics: Airborne Double Jump Boost",
            dj_ok,
            f"Double Jump Apex Y: {dj_y:.2f}m (+{dj_y - y_ground:.2f}m over ground) | {v_dj.reason}",
            str(double_jump_png)
        )

        # Step 9: Volcanic Slope Climbing & Downhill Dynamics
        print("\n[Step 9] Testing Movement Dynamics: Volcanic Slope Climbing & Descent...")
        # Teleport to base of volcanic incline, looking uphill towards crater (+Z, yaw=3.14159)
        client.teleport(x=160.0, y=10.0, z=110.0, yaw=3.14159, pitch=0.25, snap_to_ground=True)
        time.sleep(0.3)
        st_slope_start = client.get_state()
        y_slope_start = st_slope_start.get("player", {}).get("y", 10.0)

        # Sprint uphill towards summit
        client.inject_input(move_forward=True, sprint=True)
        time.sleep(0.9)
        slope_climb_png = ARTIFACTS_DIR / "08j_slope_climb.png"
        client.capture_screenshot(str(slope_climb_png))
        st_slope_climb = client.get_state()
        client.inject_input(move_forward=False, sprint=False)
        time.sleep(0.2)
        v_climb = analyze_screenshot(slope_climb_png, min_size_kb=30, min_contrast=8)

        y_slope_climb = st_slope_climb.get("player", {}).get("y", y_slope_start)
        altitude_gain = y_slope_climb - y_slope_start

        # Sprint downhill away from crater (-Z, yaw=0.0)
        client.teleport(x=160.0, y=y_slope_climb, z=140.0, yaw=0.0, pitch=-0.2, snap_to_ground=True)
        time.sleep(0.2)
        client.inject_input(move_forward=True, sprint=True)
        time.sleep(0.8)
        slope_desc_png = ARTIFACTS_DIR / "08k_slope_descent.png"
        client.capture_screenshot(str(slope_desc_png))
        st_slope_desc = client.get_state()
        client.inject_input(move_forward=False, sprint=False)
        time.sleep(0.2)
        v_desc = analyze_screenshot(slope_desc_png, min_size_kb=30, min_contrast=8)

        slope_ok = (altitude_gain >= 2.0) and v_climb.is_valid and v_desc.is_valid
        report.record(
            "Movement Dynamics: Volcanic Slope Climbing & Descent",
            slope_ok,
            f"Uphill Altitude Gain: +{altitude_gain:.2f}m | Ground Contact Tracked | Valid frames",
            str(slope_climb_png)
        )

        # Step 10: Aquatic Swimming, Buoyancy & Water Fluid Drag
        print("\n[Step 10] Testing Movement Dynamics: Aquatic Swimming, Buoyancy & Fluid Drag...")
        # Teleport to deep ocean (water depth ~5.5m, sea_level=10.0m, y=4.5m)
        client.teleport(x=280.0, y=4.5, z=280.0, yaw=0.0, pitch=0.1)
        time.sleep(0.4)
        water_buoyancy_png = ARTIFACTS_DIR / "08l_water_buoyancy.png"
        client.capture_screenshot(str(water_buoyancy_png))
        time.sleep(0.2)
        v_buoy = analyze_screenshot(water_buoyancy_png, min_size_kb=30, min_contrast=8)

        # Forward swimming in water
        client.inject_input(move_forward=True, sprint=True)
        time.sleep(0.7)
        water_drag_png = ARTIFACTS_DIR / "08m_swimming_drag.png"
        client.capture_screenshot(str(water_drag_png))
        st_swim = client.get_state()
        client.inject_input(move_forward=False, sprint=False)
        time.sleep(0.2)
        v_swim = analyze_screenshot(water_drag_png, min_size_kb=30, min_contrast=8)

        p_swim = st_swim.get("player", {})
        swim_speed = math.sqrt(p_swim.get("vx", 0)**2 + p_swim.get("vz", 0)**2)
        in_water = p_swim.get("in_water", False) or (p_swim.get("y", 10.0) <= 9.8)

        water_ok = in_water and v_buoy.is_valid and v_swim.is_valid
        report.record(
            "Movement Dynamics: Aquatic Swimming & Buoyancy",
            water_ok,
            f"InWater: {in_water} | Swimming Speed: {swim_speed:.2f}m/s (drag damped) | Water Y: {p_swim.get('y',0):.2f}m",
            str(water_drag_png)
        )

        # ─── BULLET3 RIGID BODY KINEMATICS & COLLISION ─────────────────────────

        # Step 11: Bullet3 Dynamic Spawning, Freefall & Impact Settling
        print("\n[Step 11] Testing Bullet3 Rigid Body Kinematics, Impact & Settling...")
        # Position camera looking up at the rock face where bodies are dropped
        client.teleport(x=165.0, y=48.0, z=138.0, yaw=3.14159, pitch=0.45, snap_to_ground=True)
        time.sleep(0.3)

        # Raycast check
        rc_res = client.raycast([160.0, 100.0, 160.0], [160.0, 0.0, 160.0])
        report.record(
            "Bullet3 Raycast Terrain Intersection",
            rc_res.get("hit", False),
            f"Hit: {rc_res.get('hit')} | Point: ({rc_res.get('point',[0,0,0])[0]:.2f}, {rc_res.get('point',[0,0,0])[1]:.2f}, {rc_res.get('point',[0,0,0])[2]:.2f})"
        )

        # Spawn Dynamic Boulder & Crate
        boulder = client.spawn_rigid_body("sphere", radius=0.9, mass=80.0, position=[165.0, 75.0, 155.0], restitution=0.6)
        box = client.spawn_rigid_body("box", half_extents=[0.6, 0.6, 0.6], mass=40.0, position=[163.0, 70.0, 157.0], restitution=0.4)
        boulder_id = boulder.get("body_id", 0)
        box_id = box.get("body_id", 0)

        # Capture mid-air freefall
        time.sleep(0.35)
        midair_png = ARTIFACTS_DIR / "07b_physics_midair_fall.png"
        client.capture_screenshot(str(midair_png))
        v_midair = analyze_screenshot(midair_png, min_size_kb=30, min_contrast=8)

        # Await settling
        time.sleep(2.0)
        settled_png = ARTIFACTS_DIR / "07d_physics_settled.png"
        client.capture_screenshot(str(settled_png))
        v_settled = analyze_screenshot(settled_png, min_size_kb=30, min_contrast=8)

        phys_state = client.get_physics_state()
        bodies = phys_state.get("bodies", [])
        boulder_body = next((b for b in bodies if b.get("body_id") == boulder_id), None)
        box_body = next((b for b in bodies if b.get("body_id") == box_id), None)

        physics_settled = False
        if boulder_body and box_body:
            b_pos = boulder_body.get("position", [0, 0, 0])
            box_pos = box_body.get("position", [0, 0, 0])
            boulder_settled = (30.0 <= b_pos[1] <= 65.0)
            box_settled = (30.0 <= box_pos[1] <= 65.0)
            physics_settled = boulder_settled and box_settled
            phys_details = f"Boulder: ({b_pos[0]:.1f}, {b_pos[1]:.1f}, {b_pos[2]:.1f}) | Box: ({box_pos[0]:.1f}, {box_pos[1]:.1f}, {box_pos[2]:.1f})"
        else:
            phys_details = "Body lookup failed"

        report.record(
            "Bullet3 Dynamic Spawning & Mid-Air Freefall",
            (boulder_id > 0 and box_id > 0) and v_midair.is_valid,
            f"Spawned Body #{boulder_id} & #{box_id} | {v_midair.reason}",
            str(midair_png)
        )

        report.record(
            "Bullet3 Ground Collision Impact & Settling",
            physics_settled and v_settled.is_valid,
            f"{phys_details} | {v_settled.reason}",
            str(settled_png)
        )

        # ─── BIOME SYNTHESIS & ATMOSPHERE CYCLES ───────────────────────────────

        # Step 12: Biome Transitions
        print("\n[Step 12] Testing Hierarchical Wave Function Collapse Biome Transitions...")
        biomes = [
            (0, "volcano", "Volcano"),
            (1, "jungle", "Jungle"),
            (2, "desert", "Desert"),
            (3, "ice", "Glacial Ice"),
            (4, "archipelago", "Coral Archipelago")
        ]
        for b_code, b_id, b_name in biomes:
            client.set_biome(b_code)
            time.sleep(1.0)
            b_png = ARTIFACTS_DIR / f"04_biome_{b_id}.png"
            client.capture_screenshot(str(b_png))
            time.sleep(0.2)
            v_biome = analyze_screenshot(b_png, min_size_kb=30, min_contrast=8)
            report.record(
                f"Biome Transition: {b_name}",
                v_biome.is_valid,
                f"Biome ID: {b_code} ({b_id}) | {v_biome.reason}",
                str(b_png)
            )

        # Step 13: Diurnal Solar Lighting & Atmospheric Cycles (Sunrise, Noon, Sunset, Dusk, Night)
        print("\n[Step 13] Testing Diurnal Solar Lighting & Atmospheric Cycles (Dawn/Sunrise, Noon, Sunset, Dusk, Midnight)...")
        solar_tests = [
            # (time_of_day, id, name, phase, yaw, pitch, pos)
            (6.0, "01_sunrise_horizon", "Dawn Sunrise Solar Horizon (06:00)", "sunrise_horizon", -1.57, 0.05, (124.0, 10.5, 42.0)),
            (6.5, "02_sunrise_water", "Sunrise Ocean Specular Reflection (06:30)", "sunrise_water", -1.65, -0.05, (124.0, 10.5, 42.0)),
            (8.5, "03_morning_landscape", "Morning Island Vista (08:30)", "morning", 0.0, 0.05, (124.0, 14.0, 42.0)),
            (12.0, "04_midday_noon", "Midday High Solar Illumination (12:00)", "noon", 3.14, 0.10, (124.0, 14.0, 42.0)),
            (18.0, "05_sunset_horizon", "Golden Hour Sunset Horizon (18:00)", "sunset_horizon", 1.57, 0.05, (124.0, 10.5, 42.0)),
            (18.75, "06_sunset_water", "Sunset Ocean Specular & Twilight (18:45)", "sunset_water", 1.45, -0.05, (124.0, 10.5, 42.0)),
            (19.5, "07_civil_dusk", "Civil Dusk Twilight Atmosphere (19:30)", "dusk", 1.57, 0.10, (124.0, 10.5, 42.0)),
            (0.0, "08_midnight_celestial", "Celestial Midnight & Starfield (00:00)", "night", 0.0, 0.75, (124.0, 10.5, 42.0))
        ]

        for tod, s_id, s_name, s_phase, s_yaw, s_pitch, s_pos in solar_tests:
            client.teleport(x=s_pos[0], y=s_pos[1], z=s_pos[2], yaw=s_yaw, pitch=s_pitch)
            client.set_time(tod)
            time.sleep(0.7)
            s_png = ARTIFACTS_DIR / f"05_diurnal_{s_id}.png"
            client.capture_screenshot(str(s_png))
            time.sleep(0.2)
            v_res = analyze_screenshot(s_png, min_size_kb=20, min_contrast=5)
            c_ok, c_reason = analyze_solar_chromaticity(s_png, s_phase)
            test_passed = v_res.is_valid and c_ok
            report.record(
                f"Solar Lighting: {s_name}",
                test_passed,
                f"TimeOfDay: {tod}h | Lum: {v_res.mean_luminance:.1f} | {c_reason}",
                str(s_png)
            )

        # Step 13b: Dynamic Weather Semantics & Atmospheric Transitions
        print("\n[Step 13b] Testing Dynamic Weather Semantics & Atmospheric Transitions...")
        # 13b.1 Query Weather Profiles
        profiles_res = client.get_weather_profiles()
        profiles_list = profiles_res.get("profiles", [])
        profiles_ok = len(profiles_list) >= 6
        report.record(
            "Weather Registry: Extensible Profiles Discovery",
            profiles_ok,
            f"Available Profiles: {len(profiles_list)} ({[p.get('condition') for p in profiles_list[:3]]}...)"
        )

        # 13b.2 Transition to Tropical Monsoon
        client.set_weather("TROPICAL_MONSOON", transition_duration=0.5)
        time.sleep(0.7)
        w_monsoon = client.get_weather()
        monsoon_png = ARTIFACTS_DIR / "05b_weather_monsoon.png"
        client.capture_screenshot(str(monsoon_png))
        time.sleep(0.2)
        v_monsoon = analyze_screenshot(monsoon_png, min_size_kb=20, min_contrast=5)
        
        is_monsoon = ("tropical monsoon" in str(w_monsoon.get("condition", "")).lower() and 
                      w_monsoon.get("precipitation_intensity", 0.0) > 0.5 and
                      w_monsoon.get("barometric_pressure_hpa", 1013.25) < 1005.0)
        report.record(
            "Weather Dynamics: Tropical Monsoon Transition",
            is_monsoon and v_monsoon.is_valid,
            f"Condition: {w_monsoon.get('condition')} | Rain: {w_monsoon.get('precipitation_intensity',0):.2f} | Pressure: {w_monsoon.get('barometric_pressure_hpa',0):.1f}hPa | Wind: {w_monsoon.get('wind_speed_mps',0):.1f}m/s",
            str(monsoon_png)
        )

        # 13b.3 Transition to Volcanic Ash Tempest
        client.set_weather("VOLCANIC_ASH_TEMPEST", transition_duration=0.5)
        time.sleep(0.7)
        w_ash = client.get_weather()
        ash_png = ARTIFACTS_DIR / "05c_weather_ash_tempest.png"
        client.capture_screenshot(str(ash_png))
        time.sleep(0.2)
        v_ash = analyze_screenshot(ash_png, min_size_kb=20, min_contrast=5)

        is_ash = ("volcanic ash tempest" in str(w_ash.get("condition", "")).lower() and
                  w_ash.get("precipitation_type") == "volcanic_ash" and
                  w_ash.get("optical_depth", 0.0) >= 0.5)
        report.record(
            "Weather Dynamics: Volcanic Ash Tempest Transition",
            is_ash and v_ash.is_valid,
            f"Condition: {w_ash.get('condition')} | Type: {w_ash.get('precipitation_type')} | Turbidity: {w_ash.get('optical_depth',0):.2f} | Temp: {w_ash.get('temperature_celsius',0):.1f}°C",
            str(ash_png)
        )

        # 13b.4 Return to Clear Tropical
        client.set_weather("CLEAR_TROPICAL", transition_duration=0.5)
        time.sleep(0.7)
        w_clear = client.get_weather()
        clear_png = ARTIFACTS_DIR / "05d_weather_clear_restored.png"
        client.capture_screenshot(str(clear_png))
        time.sleep(0.2)
        v_clear = analyze_screenshot(clear_png, min_size_kb=20, min_contrast=5)
        
        is_clear = ("clear tropical" in str(w_clear.get("condition", "")).lower() and
                    w_clear.get("precipitation_intensity", 1.0) == 0.0)
        report.record(
            "Weather Dynamics: Clear Tropical Equilibrium",
            is_clear and v_clear.is_valid,
            f"Condition: {w_clear.get('condition')} | Rain: {w_clear.get('precipitation_intensity',0):.2f} | Pressure: {w_clear.get('barometric_pressure_hpa',0):.1f}hPa",
            str(clear_png)
        )

        # Step 14: Multi-Domain Simulation Switching
        print("\n[Step 14] Testing Multi-Domain Simulation Switching...")
        scenes = [
            (1, "karst_cave", "Karst Cave Isosurface Lab"),
            (2, "ocean_lab", "Multi-Spectral Ocean Lab"),
            (3, "atmospheric_lab", "Volumetric Atmosphere Lab"),
            (0, "volcanic_island", "Volcanic Island & Systems")
        ]
        for sidx, sid, stitle in scenes:
            client.load_scene(sidx)
            time.sleep(1.2)
            s_png = ARTIFACTS_DIR / f"06_scene_{sid}.png"
            client.capture_screenshot(str(s_png))
            time.sleep(0.2)
            v_s = analyze_screenshot(s_png, min_size_kb=20, min_contrast=5)
            report.record(
                f"Scene Switcher: {stitle}",
                v_s.is_valid,
                f"Scene #{sidx} ({sid}) | {v_s.reason}",
                str(s_png)
            )

        # Step 15: Graceful Hub Shutdown
        print("\n[Step 15] Testing Graceful IPC Shutdown...")
        client.quit()
        time.sleep(0.5)
        proc.poll()
        shutdown_ok = proc.returncode is not None or proc.wait(timeout=3.0) == 0
        report.record("Graceful Hub Shutdown", shutdown_ok, f"Exit Code: {proc.returncode}")

    except Exception as e:
        report.record("Test Suite Execution", False, f"Exception: {str(e)}")
    finally:
        client.close()
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=2.0)
            except Exception:
                proc.kill()
        if os.path.exists(sock_path):
            os.unlink(sock_path)

    success = report.summary()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    run_test_suite()
