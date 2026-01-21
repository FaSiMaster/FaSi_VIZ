import re
from typing import Tuple

_HEX_RE = re.compile(r"^#?[0-9A-Fa-f]{6}$")

def _hex_to_rgb(hex_color: str) -> Tuple[float, float, float]:
    if not _HEX_RE.match(hex_color):
        raise ValueError(f"Ungültige Hex-Farbe: {hex_color}")
    h = hex_color.lstrip("#")
    return int(h[0:2],16)/255.0, int(h[2:4],16)/255.0, int(h[4:6],16)/255.0

def _srgb_to_linear(c: float) -> float:
    return c/12.92 if c <= 0.04045 else ((c + 0.055)/1.055) ** 2.4

def relative_luminance(hex_color: str) -> float:
    r,g,b = _hex_to_rgb(hex_color)
    rl,gl,bl = _srgb_to_linear(r), _srgb_to_linear(g), _srgb_to_linear(b)
    return 0.2126*rl + 0.7152*gl + 0.0722*bl

def contrast_ratio(fg: str, bg: str) -> float:
    L1, L2 = relative_luminance(fg), relative_luminance(bg)
    lighter, darker = (L1, L2) if L1 >= L2 else (L2, L1)
    return (lighter + 0.05) / (darker + 0.05)
