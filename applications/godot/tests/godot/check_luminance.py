#!/usr/bin/env python3
"""check_luminance.py — independent non-blank check for a PNG screenshot.

Pure-stdlib PNG decode (zlib + scanline unfilter); no PIL/numpy dependency.
Used by godot_screenshot.sh as a second opinion alongside the in-script
luminance check inside godot_screenshot.gd.

Usage:  check_luminance.py <png> [--min-mean F] [--min-stddev F]
Exit:   0 non-blank · 3 blank · 2 usage/decode error

Thresholds default to mean > 10.0 and stddev > 5.0 (8-bit Rec.601 luma
Y = 0.299R + 0.587G + 0.114B, subsampled every 8th pixel / every 4th row).
These are display-verification constants, not gameplay values (AP-7 scope).
"""
import struct
import sys
import zlib


def decode_png(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos = 8
    width = height = 0
    bit_depth = color_type = None
    idat = bytearray()
    while pos < len(data):
        (length,) = struct.unpack_from(">I", data, pos)
        ctype = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _comp, _filt, interlace = \
                struct.unpack(">IIBBBBB", chunk)
            if bit_depth != 8 or interlace != 0:
                raise ValueError("only 8-bit non-interlaced PNG supported")
            if color_type not in (0, 2, 6):
                raise ValueError(f"color type {color_type} unsupported")
        elif ctype == b"IDAT":
            idat.extend(chunk)
        elif ctype == b"IEND":
            break
        pos += 12 + length
    if width is None or height is None or color_type is None:
        raise ValueError("missing/invalid IHDR")
    channels = {0: 1, 2: 3, 6: 4}[color_type]
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    out = bytearray(height * stride)
    prev = bytearray(stride)
    p = 0
    for y in range(height):
        ftype = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        if ftype == 1:  # Sub
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 0xFF
        elif ftype == 2:  # Up
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ftype == 3:  # Average
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:  # Paeth
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                b = prev[i]
                c = prev[i - channels] if i >= channels else 0
                pp = a + b - c
                pa, pb, pc = abs(pp - a), abs(pp - b), abs(pp - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        elif ftype != 0:
            raise ValueError(f"unknown filter {ftype}")
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return width, height, channels, bytes(out)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    path = argv[1]
    min_mean, min_stddev = 10.0, 5.0
    i = 2
    while i < len(argv) - 1:
        if argv[i] == "--min-mean":
            min_mean = float(argv[i + 1]); i += 2
        elif argv[i] == "--min-stddev":
            min_stddev = float(argv[i + 1]); i += 2
        else:
            i += 1
    try:
        w, h, ch, pix = decode_png(path)
    except Exception as e:  # noqa: BLE001 — report and fail closed
        print(f"LUMINANCE: decode error: {e}")
        return 2
    n = 0
    s = 0.0
    s2 = 0.0
    for y in range(0, h, 4):
        row = y * w * ch
        for x in range(0, w, 8):
            i3 = row + x * ch
            if ch == 1:
                lum = float(pix[i3])
            else:
                lum = 0.299 * pix[i3] + 0.587 * pix[i3 + 1] + 0.114 * pix[i3 + 2]
            s += lum
            s2 += lum * lum
            n += 1
    mean = s / n
    stddev = max(0.0, s2 / n - mean * mean) ** 0.5
    print(f"LUMINANCE: {w}x{h} mean={mean:.2f} stddev={stddev:.2f} "
          f"(thresholds mean>{min_mean} stddev>{min_stddev})")
    if mean <= min_mean:
        print("LUMINANCE: FAIL (blank/dark)")
        return 3
    if stddev <= min_stddev:
        print("LUMINANCE: FAIL (uniform frame)")
        return 3
    print("LUMINANCE: PASS (non-blank)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
