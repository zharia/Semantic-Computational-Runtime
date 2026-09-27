# Filesystem + repo-root utilities — AP-4 (zero absolute paths) enforced by
# construction: every path here is derived from the working directory, an
# environment override, or a caller-supplied base. No path literal contains
# a drive/root prefix; the only absolute path ever formed is
# SCR_REPO_ROOT (opt-in, set by the environment) + relative suffix.

from std.pathlib import cwd
from std.os.path import exists
from std.ffi import c_char, external_call


def getenv_string(name: String) -> Optional[String]:
    """Read a process environment variable (None when unset)."""
    var p = external_call["getenv", Pointer[mut=False, c_char, ImmUntrackedOrigin]](
        name.unsafe_ptr()
    )
    if Int(p) == 0:
        return None
    var out = String()
    var i = 0
    while i < 4096:
        var b = p[unsafe_offset=i]
        var ib = Int(b)
        if ib == 0:
            break
        if ib < 0:
            ib += 256
        out = out + chr(ib)
        i += 1
    return out^


def _parent_dir(path: String) -> String:
    """Strip the last `/component`; returns '' when nothing remains."""
    var bytes = List[UInt8]()
    for b in path.bytes():
        bytes.append(b)
    var n = len(bytes)
    if n == 0:
        return ""
    # Trim trailing slash (but keep root "/").
    if n > 1 and bytes[n - 1] == 0x2F:
        n -= 1
    var i = n - 1
    while i >= 0:
        if bytes[i] == 0x2F:
            if i == 0:
                return "/"
            var out = String()
            for j in range(0, i):
                out = out + chr(Int(bytes[j]))
            return out^
        i -= 1
    return ""


def _strip_trailing_slash(path: String) -> String:
    """Remove one trailing '/' (byte-wise; repo paths are ASCII)."""
    var bytes = List[UInt8]()
    for b in path.bytes():
        bytes.append(b)
    var n = len(bytes)
    if n > 1 and bytes[n - 1] == 0x2F:
        n -= 1
    var out = String()
    for i in range(n):
        out = out + chr(Int(bytes[i]))
    return out^


def join_path(base: String, suffix: String) -> String:
    if base.byte_length() == 0:
        return suffix.copy()
    if base == "/":
        return "/" + suffix
    return base + "/" + suffix


def find_repo_root() raises -> String:
    """Locate the repository root by walking up from the working directory,
    looking for the relative marker `lib/A01_Render/Material/materials_catalog.json`.
    SCR_REPO_ROOT overrides the walk when set (still must contain the marker).
    Returns the root directory string (no trailing slash, '/' for filesystem root)."""
    var marker = "lib/A01_Render/Material/materials_catalog.json"
    var override = getenv_string("SCR_REPO_ROOT")
    if override:
        var root = _strip_trailing_slash(override.value())
        if exists(join_path(root, marker)):
            return root^
        raise Error("SCR_REPO_ROOT does not contain " + marker)
    var dir = String(cwd())
    while True:
        if exists(join_path(dir, marker)):
            return dir^
        var parent = _parent_dir(dir)
        if parent.byte_length() == 0 or parent == dir:
            raise Error("repo root not found: " + marker)
        dir = parent^


def read_file_bytes(path: String) raises -> List[UInt8]:
    """Read a whole file as bytes; raises when the file is unreadable."""
    var fh = open(path, "r")
    var buf = List[UInt8]()
    try:
        while True:
            var chunk = fh.read_bytes(131072)
            if len(chunk) == 0:
                break
            for b in chunk:
                buf.append(b)
    finally:
        fh.close()
    return buf^


def read_file_text(path: String) raises -> String:
    var buf = read_file_bytes(path)
    var out = String()
    var i = 0
    while i < len(buf):
        var b = buf[i]
        if b < 0x80:
            out = out + chr(Int(b))
            i += 1
        elif b < 0xE0:
            out = out + chr((Int(b & 0x1F) << 6) | Int(buf[i + 1] & 0x3F))
            i += 2
        elif b < 0xF0:
            out = out + chr(
                (Int(b & 0x0F) << 12) | (Int(buf[i + 1] & 0x3F) << 6) | Int(buf[i + 2] & 0x3F)
            )
            i += 3
        else:
            out = out + chr(
                (Int(b & 0x07) << 18)
                | (Int(buf[i + 1] & 0x3F) << 12)
                | (Int(buf[i + 2] & 0x3F) << 6)
                | Int(buf[i + 3] & 0x3F)
            )
            i += 4
    return out^


def write_file_bytes(path: String, data: List[UInt8]) raises:
    """Write bytes to path, truncating any existing file."""
    var fh = open(path, "w")
    try:
        fh.write_bytes(data)
    finally:
        fh.close()
