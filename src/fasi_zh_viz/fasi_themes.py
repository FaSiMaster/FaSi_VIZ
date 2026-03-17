"""FaSi-eigene Farbempfehlungen für Verkehrssicherheitsthemen.

Diese Schicht liegt ÜBER dem offiziellen Kanton Zürich CD (tokens.json).
Die Basisfarben sind unveränderlich — hier wird nur die thematische
Zuweisung für die Fachstelle Verkehrssicherheit (FaSi, Baudirektion ZH) definiert.

Quelle Unfalltypen: ASTRA, Unfalltypenblatt (UTF),
https://www.astra.admin.ch/astra/de/home/dokumentation/unfalldaten.html
Klassierung nach ASTRA-Unfallaufnahmeformular Formular 13.004.

Verwendung:
    from fasi_zh_viz.fasi_themes import get_theme_palette, UNFALLSCHWERE_PALETTE
    colors = get_theme_palette("unfallschwere")
    ampel = get_theme_palette("ampel")
"""

from __future__ import annotations

from typing import Dict, List, Optional


# ---------------------------------------------------------------------------
# Unfallschwere-Palette (nach SN 641 724 / ASTRA-Standard)
# Sachschaden → Leichtverletzt → Schwerverletzt → Getötet → Unbekannt
# Farben aus dem offiziellen KZH-Infografik-Palette und Grautoene
# ---------------------------------------------------------------------------
UNFALLSCHWERE_PALETTE: Dict[str, str] = {
    "sachschaden":       "#0076BD",  # Blau ZH   — Sachschaden / nicht verletzt
    "leichtverletzte":   "#FFCC00",  # Gelb ZH   — auffällig, aber nicht alarmierend
    "schwerverletzte":   "#E87600",  # Orange ZH — erhöhte Schwere
    "getötete":          "#B31523",  # Dunkelrot  — höchste Schwere
    "unbekannt":         "#949494",  # Grau 40 ZH — fehlender / unbekannter Wert
}

# ---------------------------------------------------------------------------
# Unfalltypen-Palette (nach ASTRA Unfalltyp-Klassifikation)
# Quelle: ASTRA Unfalltypenblatt (UTF), Formular 13.004
# https://www.astra.admin.ch/astra/de/home/dokumentation/unfalldaten.html
# ---------------------------------------------------------------------------
UNFALLTYP_PALETTE: Dict[str, str] = {
    "auffahrunfall":     "#0076BD",  # Blau ZH  – ASTRA UTF Typ 1: Auffahren
    "abbiegeunfall":     "#009A8E",  # Grün/Türkis ZH – ASTRA UTF Typ 2: Abbiegen/Einmünden
    "überholunfall":     "#6E1C81",  # Lila ZH  – ASTRA UTF Typ 3: Überholen/Spurwechsel
    "fussgängerunfall":  "#E87600",  # Orange ZH – ASTRA UTF Typ 5: Fussgängerunfall
    "wildunfall":        "#006400",  # Dunkelgrün – ASTRA UTF Typ 6: Tierunfall (ausserorts)
    "selbstunfall":      "#666666",  # Grau 60  – ASTRA UTF Typ 7: Selbstunfall
}

# ---------------------------------------------------------------------------
# Ampel-Palette (Quartil-basiertes Monitoring — SafetyCockpit-Standard)
# Grün  = unter Q25  (besser als üblich)
# Gelb  = Q25–Q75   (im Normalbereich)
# Rot   = über Q75  (schlechter als üblich)
# Grau  = keine Daten / unbekannt
# ---------------------------------------------------------------------------
AMPEL_PALETTE: Dict[str, str] = {
    "gruen": "#1A7F1F",  # Infografiken Grün — Wert unter Q25 (positiv)
    "gelb":  "#FFCC00",  # CD Manual Gelb    — Wert Q25–Q75 (normal)
    "rot":   "#D93C1A",  # Funktion Rot      — Wert über Q75 (negativ)
    "grau":  "#949494",  # Grau 40 ZH        — keine Daten / unbekannt
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
    "ampel":                AMPEL_PALETTE,
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
        schwere: "sachschaden", "leichtverletzte", "schwerverletzte",
                 "getötete" oder "unbekannt"

    Returns:
        Hex-Farbe oder None wenn unbekannt
    """
    return UNFALLSCHWERE_PALETTE.get(schwere.lower())


def get_ampel_color(status: str) -> Optional[str]:
    """Schnellzugriff auf Ampel-Statusfarbe (Quartil-basiert).

    Args:
        status: "gruen", "gelb", "rot" oder "grau"

    Returns:
        Hex-Farbe oder None wenn unbekannt
    """
    return AMPEL_PALETTE.get(status.lower())
