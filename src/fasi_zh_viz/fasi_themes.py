"""FaSi-eigene Farbempfehlungen für Verkehrssicherheitsthemen.

Diese Schicht liegt ÜBER dem offiziellen Kanton Zürich CD (tokens.json).
Die Basisfarben sind unveränderlich — hier wird nur die thematische
Zuweisung für die Fachstelle Verkehrssicherheit (FaSi, Baudirektion ZH) definiert.

Verwendung:
    from fasi_zh_viz.fasi_themes import get_theme_palette, UNFALLSCHWERE_PALETTE
    colors = get_theme_palette("unfallschwere")
"""

from __future__ import annotations

from typing import Dict, List, Optional


# ---------------------------------------------------------------------------
# Unfallschwere-Palette (nach SN 641 724 / ASTRA-Standard)
# Leichtverletzt → Schwerverletzt → Getötet
# Farben aus dem offiziellen KZH-Infografik-Palette
# ---------------------------------------------------------------------------
UNFALLSCHWERE_PALETTE: Dict[str, str] = {
    "leichtverletzte":   "#FFCC00",  # Gelb ZH  — auffällig, aber nicht alarmierend
    "schwerverletzte":   "#E87600",  # Orange ZH — erhöhte Schwere
    "getötete":          "#B31523",  # Dunkelrot  — höchste Schwere
}

# ---------------------------------------------------------------------------
# Unfalltypen-Palette (nach ASTRA Unfalltyp-Klassifikation)
# ---------------------------------------------------------------------------
UNFALLTYP_PALETTE: Dict[str, str] = {
    "auffahrunfall":     "#0076BD",  # Blau ZH
    "abbiegeunfall":     "#009A8E",  # Grün/Türkis ZH
    "überholunfall":     "#6E1C81",  # Lila ZH
    "fussgängerunfall":  "#E87600",  # Orange ZH
    "wildunfall":        "#006400",  # Dunkelgrün (ausserorts)
    "selbstunfall":      "#666666",  # Grau 60
}

# ---------------------------------------------------------------------------
# Trend-Palette (positive/negative Entwicklung)
# ---------------------------------------------------------------------------
TREND_PALETTE: Dict[str, str] = {
    "abnahme_gut":   "#009A8E",  # Grün/Türkis — Unfälle nehmen ab = positiv
    "zunahme_schlecht": "#B31523",  # Rot — Unfälle nehmen zu = negativ
    "stabil":        "#666666",  # Grau 60 — keine signifikante Änderung
    "ziel":          "#0076BD",  # Blau — Zielwert/Benchmark
}

# ---------------------------------------------------------------------------
# Verkehrsteilnehmer-Palette
# ---------------------------------------------------------------------------
VERKEHRSTEILNEHMER_PALETTE: Dict[str, str] = {
    "fussgänger":    "#E87600",  # Orange ZH
    "velo":          "#009A8E",  # Grün/Türkis ZH
    "motorrad":      "#6E1C81",  # Lila ZH
    "pkw":           "#0076BD",  # Blau ZH
    "lkw_bus":       "#666666",  # Grau 60
    "e_scooter":     "#FFCC00",  # Gelb ZH
}

# ---------------------------------------------------------------------------
# Strassentyp-Palette
# ---------------------------------------------------------------------------
STRASSENTYP_PALETTE: Dict[str, str] = {
    "autobahn":      "#0076BD",  # Blau ZH
    "kantonsstrasse": "#009A8E",  # Grün/Türkis ZH
    "gemeindestrasse": "#666666",  # Grau 60
    "innerorts":     "#E87600",  # Orange ZH
    "ausserorts":    "#6E1C81",  # Lila ZH
}

# ---------------------------------------------------------------------------
# Alle Themes zusammengefasst
# ---------------------------------------------------------------------------
_THEMES: Dict[str, Dict[str, str]] = {
    "unfallschwere":        UNFALLSCHWERE_PALETTE,
    "unfalltyp":            UNFALLTYP_PALETTE,
    "trend":                TREND_PALETTE,
    "verkehrsteilnehmer":   VERKEHRSTEILNEHMER_PALETTE,
    "strassentyp":          STRASSENTYP_PALETTE,
}


def get_theme_palette(theme: str) -> Dict[str, str]:
    """Gibt die FaSi-Farbpalette für ein bestimmtes Thema zurück.

    Args:
        theme: "unfallschwere", "unfalltyp", "trend", "verkehrsteilnehmer", "strassentyp"

    Returns:
        Dict mit Label → Hex-Farbe

    Raises:
        ValueError: wenn das Theme nicht bekannt ist
    """
    if theme not in _THEMES:
        available = ", ".join(sorted(_THEMES.keys()))
        raise ValueError(f"Unbekanntes Theme '{theme}'. Verfügbar: {available}")
    return dict(_THEMES[theme])


def get_theme_colors(theme: str) -> List[str]:
    """Gibt nur die Farbwerte (ohne Labels) zurück — für direkte Übergabe an Matplotlib/Plotly."""
    return list(get_theme_palette(theme).values())


def get_theme_labels(theme: str) -> List[str]:
    """Gibt nur die Labels zurück — für Legende."""
    return list(get_theme_palette(theme).keys())


def list_themes() -> List[str]:
    """Gibt alle verfügbaren Theme-Namen zurück."""
    return sorted(_THEMES.keys())


def get_unfallschwere_color(schwere: str) -> Optional[str]:
    """Schnellzugriff auf Unfallschwere-Farbe.

    Args:
        schwere: "leichtverletzte", "schwerverletzte" oder "getötete"

    Returns:
        Hex-Farbe oder None wenn unbekannt
    """
    return UNFALLSCHWERE_PALETTE.get(schwere.lower())
