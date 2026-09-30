#!/usr/bin/env python3
"""check_shoreline_foam.py — "foam only at the shoreline" automated gate.

Milestone 0005 exit criterion (spec §7): given an overhead (aerial) capture of
the island, every BRIGHT pixel that shows open water must lie within a band of
±FOAM_BAND_M (default 6 u) of the `y_terrain = sea_level` contour of the
committed seed-1 height field, and the count outside that band must be
≤ 2% of the in-band count.

What this asserts (0005 §1.1 (a)): the shore band the ocean.gdshader draws
comes from the sim-computed SHORE_FOAM texture and hugs the coastline — not a
white ring drifting offshore, and not a solid foam wedge over the whole ocean
(the 0002 §6.4 regression this gate exists to catch).

Method (all display-verification constants, AP-7 scope — no gameplay values):
  1. Pure-stdlib PNG decode (reuses check_luminance.decode_png).
  2. Height field: TERRAIN vertices of tests/fixtures/snapshot_seed1_tick1.bin
     (world-space 65x65 corner grid, 4 u spacing) -> bilinear y_terrain(x,z);
     sea_level from the fixture's OCEAN section.
  3. Contour: grid-edge crossings of y_terrain = sea_level, subdivided to ~1 u
     sample points (distance-to-contour measure).
  4. Camera model matches godot_aerial_diagnostic.gd defaults: position
     (0, alt, 0), rotation (-90,0,0) deg, Camera3D default fov 75, perspective
     projection; the y=0 plane intersection gives world xz per pixel.
 5. Candidate pixels: Rec.601 luma >= --luma (default 0.60) AND the pixel is
    over water (bilinear y_terrain < sea_level) AND outside the HUD
    overlays (top --hud-rows rows carry the tick label; bottom
    --bottom-hud-rows rows carry the 0007 hotbar/target panels — both are
    bright presentation, not scene pixels).
  6. Each candidate's distance to the contour point cloud (spatial hash) decides
     in-band vs out-of-band.

Usage:
    python3 applications/godot/tests/godot/check_shoreline_foam.py \
        applications/godot/build/aerial.png

Exit codes: 0 pass · 1 assertion failed · 2 usage/decode/fixture error.
"""
from __future__ import annotations

import math
import os
import struct
import sys

# Reuse the stdlib-only PNG decoder from the sibling gate.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from check_luminance import decode_png  # noqa: E402

FIXTURE_REL = "applications/godot/tests/fixtures/snapshot_seed1_tick1.bin"
REPO_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
                 "..", "..", "..", "..")
)

# Grid geometry (mirrors src/mojo constants: GRID_N 64, CELL_SIZE 4).
GRID_N = 64
CELL = 4.0
CORNER_MIN = -128.0  # corner grid spans [-128, 128], 65x65 points

# Aerial camera (godot_aerial_diagnostic.gd defaults).
CAM_ALT = 160.0
CAM_FOV_DEG = 75.0  # Camera3D default; the diagnostic never overrides it

# Gate defaults (display-verification constants).
FOAM_BAND_M = 6.0
LUMA_MIN = 0.60
HUD_ROWS = 72  # top tick/HUD label strip (bright white text)
# Bottom overlay strip (0007): the scr_hotbar slot panels + target readout
# anchor to the bottom of the viewport (island.tscn) and are bright — they
# are presentation, not scene pixels. Same display-condition class as the
# top HUD_ROWS mask and the --fog=0 aerial condition: the foam assertion
# itself (bright scene water within the contour band) is unchanged.
BOTTOM_HUD_ROWS = 96
MIN_IN_BAND = 200  # refuse a vacuous pass when no foam is visible at all
MAX_OUT_RATIO = 0.02


def parse_heights_and_sea(path: str):
    """Return (heights[65][65], sea_level) from the golden fixture."""
    with open(path, "rb") as fh:
        buf = fh.read()
    if buf[:4] != b"SCRS":
        raise ValueError("fixture: bad magic")
    schema = struct.unpack_from("<I", buf, 4)[0]
    # Schema 5 (milestone_0006) only ADDS sections 10 FLORA / 11 FAUNA; the
    # TERRAIN (schema-4 blend tuples) and OCEAN layouts read here are
    # byte-identical, so schema 4/5/6 fixtures decode the same way (schema
    # 6 adds sections 12–14; sections 1–11 are byte-identical to schema 5).
    if schema not in (4, 5, 6):
        raise ValueError(f"fixture: schema {schema} not in (4, 5, 6)")
    section_count = struct.unpack_from("<I", buf, 8)[0]
    payload = struct.unpack_from("<I", buf, 40)[0]
    if payload != len(buf) - 48:
        raise ValueError("fixture: payload_bytes mismatch")
    heights = [[float("nan")] * (GRID_N + 1) for _ in range(GRID_N + 1)]
    sea = None
    off = 48
    end = 48 + payload
    seen = set()
    while off < end:
        sid, sbytes = struct.unpack_from("<II", buf, off)
        data = off + 8
        if data + sbytes > end:
            raise ValueError("fixture: truncated section")
        seen.add(sid)
        if sid == 4:  # OCEAN
            sea = struct.unpack_from("<f", buf, data)[0]
        elif sid == 3:  # TERRAIN
            toff = data
            chunk_count = struct.unpack_from("<I", buf, toff)[0]
            toff += 4
            for _c in range(chunk_count):
                # chunk header: origin xyz (3xf32) + vcount + icount (2xu32)
                _ox, _oy, _oz, vcount, icount = struct.unpack_from(
                    "<fffII", buf, toff
                )
                toff += 20
                for v in range(vcount):
                    vx, vy, vz = struct.unpack_from("<fff", buf, toff + 12 * v)
                    # world-space corner -> grid index (4 u lattice)
                    gx = int(round((vx - CORNER_MIN) / CELL))
                    gz = int(round((vz - CORNER_MIN) / CELL))
                    if 0 <= gx <= GRID_N and 0 <= gz <= GRID_N:
                        heights[gz][gx] = vy
                toff += 28 * vcount + 4 * icount
        off = data + sbytes
    if 3 not in seen or 4 not in seen:
        raise ValueError("fixture: missing TERRAIN/OCEAN section")
    if sea is None:
        raise ValueError("fixture: no OCEAN section")
    for z in range(GRID_N + 1):
        for x in range(GRID_N + 1):
            if math.isnan(heights[z][x]):
                raise ValueError(f"fixture: missing grid point ({x},{z})")
    return heights, sea


def height_at(heights, x: float, z: float) -> float:
    """Bilinear y_terrain at world (x,z); clamped to the corner grid."""
    fx = min(max((x - CORNER_MIN) / CELL, 0.0), float(GRID_N))
    fz = min(max((z - CORNER_MIN) / CELL, 0.0), float(GRID_N))
    x0 = min(int(fx), GRID_N - 1)
    z0 = min(int(fz), GRID_N - 1)
    tx = fx - x0
    tz = fz - z0
    h00 = heights[z0][x0]
    h10 = heights[z0][x0 + 1]
    h01 = heights[z0 + 1][x0]
    h11 = heights[z0 + 1][x0 + 1]
    return (h00 * (1 - tx) + h10 * tx) * (1 - tz) + (h01 * (1 - tx) + h11 * tx) * tz


def contour_points(heights, sea: float, step: float = 1.0):
    """Sample points where y_terrain crosses sea_level (grid-edge crossings)."""
    pts = []

    def interp(p0, p1, h0, h1):
        t = (sea - h0) / (h1 - h0) if h1 != h0 else 0.5
        t = min(max(t, 0.0), 1.0)
        return (p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t)

    for z in range(GRID_N + 1):
        for x in range(GRID_N):
            h0 = heights[z][x]
            h1 = heights[z][x + 1]
            if (h0 - sea) * (h1 - sea) < 0:
                p = interp((CORNER_MIN + x * CELL, CORNER_MIN + z * CELL),
                           (CORNER_MIN + (x + 1) * CELL, CORNER_MIN + z * CELL),
                           h0, h1)
                pts.append(p)
    for x in range(GRID_N + 1):
        for z in range(GRID_N):
            h0 = heights[z][x]
            h1 = heights[z + 1][x]
            if (h0 - sea) * (h1 - sea) < 0:
                p = interp((CORNER_MIN + x * CELL, CORNER_MIN + z * CELL),
                           (CORNER_MIN + x * CELL, CORNER_MIN + (z + 1) * CELL),
                           h0, h1)
                pts.append(p)
    # Subdivide crossings to ~1 u spacing so pixel distances are accurate.
    dense = []
    for i, p in enumerate(pts):
        q = pts[(i + 1) % len(pts)]
        seg = math.hypot(q[0] - p[0], q[1] - p[1])
        n = max(1, int(seg / step))
        for k in range(n):
            t = k / n
            dense.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
    return dense


def build_hash(points, cell=8.0):
    h = {}
    for p in points:
        h.setdefault((int(math.floor(p[0] / cell)), int(math.floor(p[1] / cell))),
                     []).append(p)
    return h


def dist_to_contour(ph, x, z, cell=8.0):
    gx = int(math.floor(x / cell))
    gz = int(math.floor(z / cell))
    best = float("inf")
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            for p in ph.get((gx + dx, gz + dz), ()):
                d = math.hypot(p[0] - x, p[1] - z)
                if d < best:
                    best = d
    return best


def main(argv) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    png = argv[1]
    band, luma_min, hud_rows = FOAM_BAND_M, LUMA_MIN, HUD_ROWS
    bottom_hud_rows = BOTTOM_HUD_ROWS
    i = 2
    while i < len(argv) - 1:
        if argv[i] == "--band":
            band = float(argv[i + 1]); i += 2
        elif argv[i] == "--luma":
            luma_min = float(argv[i + 1]); i += 2
        elif argv[i] == "--hud-rows":
            hud_rows = int(argv[i + 1]); i += 2
        elif argv[i] == "--bottom-hud-rows":
            bottom_hud_rows = int(argv[i + 1]); i += 2
        else:
            i += 1

    try:
        fixture = os.path.join(REPO_ROOT, FIXTURE_REL)
        heights, sea = parse_heights_and_sea(fixture)
        w, h, ch, pix = decode_png(png)
    except Exception as e:  # noqa: BLE001 — report and fail closed
        print(f"SHORE FOAM: decode/fixture error: {e}")
        return 2

    pts = contour_points(heights, sea)
    if len(pts) < 32:
        print(f"SHORE FOAM: contour too short ({len(pts)} pts) — fixture bad")
        return 2
    ph = build_hash(pts)

    tan_half = math.tan(math.radians(CAM_FOV_DEG / 2.0))
    aspect = w / h
    in_band = 0
    out_band = 0
    out_samples = []
    for row in range(hud_rows, h - bottom_hud_rows):
        ndc_y = 1.0 - (row + 0.5) * 2.0 / h
        z_row = -ndc_y * tan_half * CAM_ALT  # camera forward = -Y, up = -Z
        base = row * w * ch
        for col in range(w):
            i3 = base + col * ch
            if ch == 1:
                r = g = b = pix[i3]
            else:
                r, g, b = pix[i3], pix[i3 + 1], pix[i3 + 2]
            luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            if luma < luma_min:
                continue
            ndc_x = (col + 0.5) * 2.0 / w - 1.0
            x_world = ndc_x * aspect * tan_half * CAM_ALT
            if height_at(heights, x_world, z_row) >= sea:
                continue  # land pixel (terrain/sulfur/sand — not foam)
            d = dist_to_contour(ph, x_world, z_row)
            if d <= band:
                in_band += 1
            else:
                out_band += 1
                if len(out_samples) < 5:
                    out_samples.append(
                        (col, row, round(x_world, 1), round(z_row, 1), round(d, 1))
                    )

    print(f"SHORE FOAM: contour pts={len(pts)} sea={sea:.3f} band={band} "
          f"luma>={luma_min}")
    print(f"SHORE FOAM: in-band={in_band} out-of-band={out_band} "
          f"ratio={(out_band / in_band if in_band else float('inf')):.4f}")
    for s in out_samples:
        print(f"SHORE FOAM: outside sample px=({s[0]},{s[1]}) world=({s[2]},{s[3]}) "
              f"dist={s[4]}u")
    if in_band < MIN_IN_BAND:
        print(f"SHORE FOAM: FAIL — in-band {in_band} < {MIN_IN_BAND} "
              "(no foam visible at the shoreline)")
        return 1
    if out_band > MAX_OUT_RATIO * in_band:
        print(f"SHORE FOAM: FAIL — {out_band} out-of-band > "
              f"{MAX_OUT_RATIO * 100:.0f}% of {in_band} in-band")
        return 1
    print("SHORE FOAM: PASS (foam only at the shoreline)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
