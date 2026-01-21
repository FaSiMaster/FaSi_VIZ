"""
FaSi ZH Viz - Visualisierungs-Library gemäss Kanton Zürich Designsystem

Version: 2.1.0

Verwendung:
    from fasi_zh_viz import load_tokens, apply_matplotlib_style
    from fasi_zh_viz import format_int_ch, format_date_ch, build_source_line
    
    tokens = load_tokens()
    apply_matplotlib_style(tokens)
    
    # Schweizer Formatierung
    print(format_int_ch(1234567))  # "1'234'567"
    
    # Quellenangabe
    print(build_source_line("Statistisches Amt", "21.01.2026"))
"""

__version__ = "2.1.0"

# Tokens & CSS
from .tokens import load_tokens, load_css

# Kontrast-Berechnung
from .contrast import contrast_ratio, relative_luminance

# Validatoren
from .validators import (
    validate_palette_against_background,
    validate_text_contrast,
    validate_min_font_px,
    warn_if_too_many_categories,
    ValidationIssue,
)

# Library-Themes
from .matplotlib_style import apply_matplotlib_style, matplotlib_rcparams
from .plotly_theme import apply_plotly_defaults, plotly_template
from .altair_theme import enable_altair_theme, altair_theme

# Text-Formatierung (Schweizer Hochdeutsch)
from .text_format import (
    format_int_ch,
    format_float_ch,
    format_percent_ch,
    format_date_ch,
    format_time_ch,
    quote_primary,
    quote_secondary,
    lint_swiss_de_text,
    TextLintIssue,
)

# Annotationen (Quellen, Alt-Text)
from .annotations import (
    build_source_line,
    build_caption,
    validate_alt_text,
    AnnotationIssue,
)

__all__ = [
    # Version
    "__version__",
    # Tokens & CSS
    "load_tokens",
    "load_css",
    # Kontrast
    "contrast_ratio",
    "relative_luminance",
    # Validatoren
    "validate_palette_against_background",
    "validate_text_contrast",
    "validate_min_font_px",
    "warn_if_too_many_categories",
    "ValidationIssue",
    # Matplotlib
    "apply_matplotlib_style",
    "matplotlib_rcparams",
    # Plotly
    "apply_plotly_defaults",
    "plotly_template",
    # Altair
    "enable_altair_theme",
    "altair_theme",
    # Text-Formatierung
    "format_int_ch",
    "format_float_ch",
    "format_percent_ch",
    "format_date_ch",
    "format_time_ch",
    "quote_primary",
    "quote_secondary",
    "lint_swiss_de_text",
    "TextLintIssue",
    # Annotationen
    "build_source_line",
    "build_caption",
    "validate_alt_text",
    "AnnotationIssue",
]
