from typing import Any, Dict


def plotly_template(tokens: Dict[str, Any], base_font_px: float = 12.0) -> Dict[str, Any]:
    """Erzeugt ein Plotly-Template-Dict aus den Tokens."""
    font_family = ", ".join(tokens["typography"]["web_default_font_family"])
    bg = tokens["infographics_rules"]["background_default"]
    black = tokens["colors"]["grays"]["black100"]
    palette = list(tokens["colors"]["infographics_palette"].values())

    min_px = float(
        tokens.get("typography", {}).get("note", {}).get("min_font_px_in_infographics", 12)
    )
    base = max(base_font_px, min_px)

    return {
        "layout": {
            "font": {"family": font_family, "size": base, "color": black},
            "paper_bgcolor": bg,
            "plot_bgcolor": bg,
            "colorway": palette,
            "title": {"font": {"size": base + 2}},
            "xaxis": {
                "title": {"font": {"size": base}},
                "tickfont": {"size": base},
                "gridcolor": tokens["colors"]["grays"]["black20"],
                "zerolinecolor": tokens["colors"]["grays"]["black20"],
            },
            "yaxis": {
                "title": {"font": {"size": base}},
                "tickfont": {"size": base},
                "gridcolor": tokens["colors"]["grays"]["black20"],
                "zerolinecolor": tokens["colors"]["grays"]["black20"],
            },
            "legend": {
                "title": {"font": {"size": base}},
                "font": {"size": base},
                "orientation": "h",
                "x": 0,
                "y": 1.02,
                "xanchor": "left",
                "yanchor": "bottom",
            },
            "margin": {"t": 70, "r": 30, "b": 50, "l": 60},
        }
    }


def apply_plotly_defaults(
    tokens: Dict[str, Any],
    base_font_px: float = 12.0,
    template_name: str = "fasi_zh",
) -> None:
    """Registriert und aktiviert das Plotly-Template unter `template_name`."""
    import plotly.io as pio

    pio.templates[template_name] = plotly_template(tokens, base_font_px=base_font_px)
    pio.templates.default = template_name
