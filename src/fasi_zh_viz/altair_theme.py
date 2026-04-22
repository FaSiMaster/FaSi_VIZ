from typing import Any, Dict


def altair_theme(tokens: Dict[str, Any], base_font_px: float = 12.0) -> Dict[str, Any]:
    """Erzeugt ein Altair-Theme-Dict aus den Tokens."""
    font = tokens["typography"]["web_default_font_family"][0]
    bg = tokens["infographics_rules"]["background_default"]
    black = tokens["colors"]["grays"]["black100"]
    gray60 = tokens["colors"]["grays"]["black60"]
    palette = list(tokens["colors"]["infographics_palette"].values())
    size = max(base_font_px, 12.0)

    return {
        "config": {
            "background": bg,
            "title": {"font": font, "fontSize": size + 2, "color": black},
            "axis": {
                "labelFont": font,
                "titleFont": font,
                "labelFontSize": size,
                "titleFontSize": size,
                "labelColor": black,
                "titleColor": black,
                "gridColor": tokens["colors"]["grays"]["black20"],
                "domainColor": gray60,
                "tickColor": gray60,
            },
            "legend": {
                "titleFont": font,
                "labelFont": font,
                "titleFontSize": size,
                "labelFontSize": size,
                "titleColor": black,
                "labelColor": black,
                "orient": "right",
            },
            "range": {"category": palette},
        }
    }


def enable_altair_theme(
    tokens: Dict[str, Any],
    base_font_px: float = 12.0,
    theme_name: str = "fasi_zh",
) -> None:
    """Registriert und aktiviert das Altair-Theme unter `theme_name`."""
    import altair as alt

    def _theme() -> Dict[str, Any]:
        return altair_theme(tokens, base_font_px=base_font_px)

    alt.themes.register(theme_name, _theme)
    alt.themes.enable(theme_name)
