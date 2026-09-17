#!/usr/bin/env python3
"""
sim_client.py — Python IPC Client for SCR Simulation Remote Control
Communicates via UNIX domain socket using JSON-RPC line-delimited protocol.
"""

import json
import socket
import time
from typing import Any, Dict, Optional


class SimClient:
    def __init__(self, socket_path: str = "/tmp/scr_sim_hub.sock", timeout: float = 10.0):
        self.socket_path = socket_path
        self.timeout = timeout
        self.sock: Optional[socket.socket] = None
        self._req_id = 0
        self._buffer = ""

    def connect(self, retry_seconds: float = 15.0) -> bool:
        start_time = time.time()
        while time.time() - start_time < retry_seconds:
            try:
                self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                self.sock.settimeout(self.timeout)
                self.sock.connect(self.socket_path)
                return True
            except (socket.error, FileNotFoundError):
                time.sleep(0.3)
        return False

    def close(self):
        if self.sock:
            try:
                self.sock.close()
            except Exception:
                pass
            self.sock = None

    def send_command(self, method: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        if not self.sock:
            raise RuntimeError("SimClient is not connected to socket")
        if params is None:
            params = {}

        self._req_id += 1
        req = {
            "id": self._req_id,
            "method": method,
            "params": params
        }
        data = json.dumps(req) + "\n"
        self.sock.sendall(data.encode("utf-8"))

        # Read until newline
        while "\n" not in self._buffer:
            chunk = self.sock.recv(4096)
            if not chunk:
                raise ConnectionResetError("Socket connection closed by simulation hub")
            self._buffer += chunk.decode("utf-8")

        line, self._buffer = self._buffer.split("\n", 1)
        resp = json.loads(line.strip())
        if resp.get("status") == "error":
            raise RuntimeError(f"Simulation Hub error in '{method}': {resp.get('error')}")
        return resp.get("result", {})

    def get_state(self) -> Dict[str, Any]:
        return self.send_command("get_state")

    def teleport(self, x: float, y: float, z: float, yaw: Optional[float] = None, pitch: Optional[float] = None, snap_to_ground: bool = False, **kwargs) -> Dict[str, Any]:
        params = {"x": float(x), "y": float(y), "z": float(z), "snap_to_ground": bool(snap_to_ground)}
        if yaw is not None:
            params["yaw"] = float(yaw)
        if pitch is not None:
            params["pitch"] = float(pitch)
        params.update(kwargs)
        return self.send_command("teleport", params)

    def set_camera(self, x: float, y: float, z: float, yaw: Optional[float] = None, pitch: Optional[float] = None) -> Dict[str, Any]:
        return self.teleport(x, y, z, yaw, pitch)

    def set_biome(self, biome: Any) -> Dict[str, Any]:
        return self.send_command("set_biome", {"biome": biome})

    def set_partition(self, partition: Any) -> Dict[str, Any]:
        return self.send_command("set_partition", {"partition": partition})

    def set_time(self, time_of_day: float) -> Dict[str, Any]:
        return self.send_command("set_time", {"time_of_day": float(time_of_day)})

    def inject_input(self, **kwargs) -> Dict[str, Any]:
        return self.send_command("inject_input", kwargs)

    def capture_screenshot(self, filename: str) -> Dict[str, Any]:
        return self.send_command("capture_screenshot", {"filename": filename})

    def load_scene(self, scene_id_or_index: Any) -> Dict[str, Any]:
        if isinstance(scene_id_or_index, int):
            return self.send_command("load_scene", {"index": scene_id_or_index})
        return self.send_command("load_scene", {"id": str(scene_id_or_index)})

    def spawn_rigid_body(self, body_type: str = "sphere", radius: float = 0.8,
                         half_extents: Optional[list] = None, mass: float = 50.0,
                         position: Optional[list] = None, initial_velocity: Optional[list] = None,
                         restitution: float = 0.6, friction: float = 0.5) -> Dict[str, Any]:
        params = {
            "type": body_type,
            "radius": float(radius),
            "mass": float(mass),
            "restitution": float(restitution),
            "friction": float(friction),
            "position": position if position is not None else [160.0, 120.0, 160.0],
            "initial_velocity": initial_velocity if initial_velocity is not None else [0.0, 0.0, 0.0]
        }
        if half_extents is not None:
            params["half_extents"] = half_extents
        return self.send_command("spawn_rigid_body", params)

    def raycast(self, from_pos: list, to_pos: list) -> Dict[str, Any]:
        return self.send_command("raycast", {"from": from_pos, "to": to_pos})

    def get_physics_state(self) -> Dict[str, Any]:
        return self.send_command("get_physics_state")

    def get_weather(self) -> Dict[str, Any]:
        return self.send_command("get_weather")

    def set_weather(self, weather: Any, transition_duration: float = 2.0) -> Dict[str, Any]:
        params = {"transition_duration": float(transition_duration)}
        if isinstance(weather, int):
            params["profile_id"] = weather
        else:
            params["condition"] = str(weather)
        return self.send_command("set_weather", params)

    def get_weather_profiles(self) -> Dict[str, Any]:
        return self.send_command("get_weather_profiles")

    def quit(self) -> Dict[str, Any]:
        return self.send_command("quit")
