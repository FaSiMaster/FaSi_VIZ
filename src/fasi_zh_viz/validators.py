from dataclasses import dataclass
from typing import List, Optional, Dict, Any
from .contrast import contrast_ratio

@dataclass
class ValidationIssue:
    level: str
    message: str
    data: Optional[dict] = None

def validate_palette_against_background(palette: List[str], background: str, min_ratio: float = 3.0) -> Dict[str, Any]:
    issues: List[ValidationIssue] = []
    for c in palette:
        ratio = contrast_ratio(c, background)
        if ratio < min_ratio:
            issues.append(ValidationIssue(
                level="error",
                message=f"Farbe {c} hat zu wenig Kontrast zum Hintergrund {background}: {ratio:.2f} < {min_ratio:.1f}",
                data={"color": c, "background": background, "ratio": ratio, "min_ratio": min_ratio},
            ))
    return {"ok": len([i for i in issues if i.level == "error"]) == 0, "issues": [i.__dict__ for i in issues]}


def validate_background_allowed(
    background: str,
    allowed: List[str],
    allowed_inverted: Optional[List[str]] = None,
    inverted: bool = False,
) -> Dict[str, Any]:
    """Prüft, ob der Hintergrund gemäss Tokens zulässig ist.

    - normal: Weiss / Hellgrau
    - invertiert: Schwarz 100/80
    """
    allowed_set = set((allowed_inverted or []) if inverted else allowed)
    ok = background in allowed_set
    return {
        "ok": ok,
        "background": background,
        "inverted": inverted,
        "allowed": sorted(list(allowed_set)),
        "message": None if ok else "Hintergrund ist nicht in den erlaubten Werten enthalten.",
    }


def validate_palette_names_for_background(
    palette_names: List[str],
    background: str,
    palette_by_background: Dict[str, List[str]],
) -> Dict[str, Any]:
    """Prüft eine Palette (über Farbnamen) gegen die in tokens.json definierte Background-Matrix.

    Ziel: offizielles CD nicht 'umfärben', aber regelbasiert verhindern, dass Farben verwendet werden,
    die auf dem gewählten Hintergrund den Mindestkontrast unterschreiten.
    """
    allowed = set(palette_by_background.get(background, []))
    disallowed = [n for n in palette_names if n not in allowed]
    ok = len(disallowed) == 0
    return {
        "ok": ok,
        "background": background,
        "disallowed": disallowed,
        "message": None if ok else "Einige Farben sind für diesen Hintergrund nicht freigegeben (Kontrast).",
    }


def warn_if_palette_not_diverse_groups(
    palette_names: List[str],
    palette_groups: Dict[str, List[str]],
    min_distinct_groups: int = 2,
) -> Dict[str, Any]:
    """Warnung, wenn (v.a. bei Farbenpaar/-trio) nur eine Farbgruppe genutzt wird.

    Hintergrund: Farbenblindheit – bevorzugt Kombinationen aus unterschiedlichen Farbgruppen.
    """
    group_for = {}
    for g, names in palette_groups.items():
        for n in names:
            group_for[n] = g
    used_groups = {group_for.get(n) for n in palette_names if group_for.get(n)}
    ok = len(used_groups) >= min_distinct_groups if len(palette_names) in {2, 3} else True
    return {
        "ok": ok,
        "used_groups": sorted(list(used_groups)),
        "n_colors": len(palette_names),
        "message": None if ok else "Farbenpaar/-trio nutzt nur eine Farbgruppe. Für Farbenblindheit besser Gruppen mischen.",
    }


def warn_if_legend_not_outside(legend_is_outside: bool, prefer_outside: bool = True) -> Dict[str, Any]:
    if not prefer_outside:
        return {"ok": True, "message": None}
    return {
        "ok": legend_is_outside,
        "message": None if legend_is_outside else "Legende/Beschriftung wenn möglich ausserhalb der Visualisierung platzieren.",
    }

def validate_text_contrast(text_color: str, background: str, is_large_text: bool = False,
                          min_normal: float = 4.5, min_large: float = 3.0) -> Dict[str, Any]:
    ratio = contrast_ratio(text_color, background)
    threshold = min_large if is_large_text else min_normal
    ok = ratio >= threshold
    return {"ok": ok, "ratio": ratio, "threshold": threshold, "is_large_text": is_large_text,
            "hint": None if ok else "Wenn der Farbkontrast nicht gewährleistet ist, Text mit hellem Rechteck/Kreis hinterlegen oder Farbe anpassen."}

def warn_if_too_many_categories(n_categories: int, recommended_max: int = 7) -> Dict[str, Any]:
    return {"ok": n_categories <= recommended_max, "n_categories": n_categories, "recommended_max": recommended_max,
            "message": None if n_categories <= recommended_max else f"Mehr als {recommended_max} Kategorien: prüfen, ob alle Kategorien nötig sind oder zusammengefasst werden können."}

def validate_min_font_px(font_px: float, min_px: float = 12.0) -> Dict[str, Any]:
    return {"ok": font_px >= min_px, "font_px": font_px, "min_px": min_px,
            "message": None if font_px >= min_px else f"Schriftgrösse {font_px}px ist kleiner als {min_px}px."}
