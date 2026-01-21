from typing import Dict, Any

def matplotlib_rcparams(tokens: Dict[str, Any], base_font_px: float = 12.0) -> Dict[str, Any]:
    font_family = tokens["typography"]["web_default_font_family"]
    bg = tokens["infographics_rules"]["background_default"]
    black = tokens["colors"]["grays"]["black100"]
    gray60 = tokens["colors"]["grays"]["black60"]

    base = max(base_font_px, float(tokens.get("typography", {}).get("note", {}).get("min_font_px_in_infographics", 12)))

    return {
        "font.family": font_family,
        "font.size": base,
        "axes.titlesize": base + 2.0,
        "axes.labelsize": base,
        "xtick.labelsize": base,
        "ytick.labelsize": base,
        "legend.fontsize": base,
        "legend.title_fontsize": base,
        "axes.titlepad": 10,
        "figure.facecolor": bg,
        "axes.facecolor": bg,
        "text.color": black,
        "axes.labelcolor": black,
        "axes.edgecolor": gray60,
        "xtick.color": black,
        "ytick.color": black,
        "grid.color": tokens["colors"]["grays"]["black20"],
        "grid.linestyle": "-",
        "grid.linewidth": 0.6,
    }

def apply_matplotlib_style(tokens: Dict[str, Any], base_font_px: float = 12.0) -> None:
    import matplotlib as mpl
    mpl.rcParams.update(matplotlib_rcparams(tokens, base_font_px=base_font_px))
