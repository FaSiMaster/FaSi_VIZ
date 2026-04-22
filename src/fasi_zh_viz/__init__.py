"""
FaSi ZH Viz - Visualisierungs-Library gemäss Kanton Zürich Designsystem

Version: 2.6.2

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

__version__ = "2.6.2"

# Tokens & CSS
from .altair_theme import altair_theme, enable_altair_theme

# Annotationen (Quellen, Alt-Text)
from .annotations import (
    AnnotationIssue,
    build_caption,
    build_source_line,
    validate_alt_text,
)

# Kontrast-Berechnung
from .contrast import contrast_ratio, relative_luminance

# FaSi-eigene Farbthemen (Verkehrssicherheit)
from .fasi_themes import (
    AMPEL_PALETTE,
    STRASSENTYP_PALETTE,
    TREND_PALETTE,
    UNFALLSCHWERE_PALETTE,
    UNFALLTYP_PALETTE,
    VERKEHRSTEILNEHMER_PALETTE,
    get_ampel_color,
    get_theme_colors,
    get_theme_labels,
    get_theme_palette,
    get_unfallschwere_color,
    list_themes,
)

# Impressum & Signatur
from .impressum import (
    FASI,
    FASI_ORG,
    KontaktPerson,
    OrgEinheit,
    build_email_signatur,
)

# Library-Themes
from .matplotlib_style import apply_matplotlib_style, matplotlib_rcparams
from .plotly_theme import apply_plotly_defaults, plotly_template

# Geschlechtergerechte Sprache
from .sprache import (
    SprachIssue,
    lint_geschlechtergerecht,
    neutrale_form,
    paarform,
    sparschreibung,
)

# Text-Formatierung (Schweizer Hochdeutsch)
from .text_format import (
    TextLintIssue,
    format_date_ch,
    format_float_ch,
    format_int_ch,
    format_percent_ch,
    format_time_ch,
    lint_swiss_de_text,
    quote_primary,
    quote_secondary,
)
from .tokens import load_css, load_tokens

# Validatoren
from .validators import (
    ValidationIssue,
    validate_background_allowed,
    validate_min_font_px,
    validate_palette_against_background,
    validate_palette_names_for_background,
    validate_text_contrast,
    warn_if_legend_not_outside,
    warn_if_palette_not_diverse_groups,
    warn_if_too_many_categories,
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
    "validate_background_allowed",
    "validate_palette_names_for_background",
    "warn_if_palette_not_diverse_groups",
    "warn_if_legend_not_outside",
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
    # Impressum & Signatur
    "KontaktPerson",
    "OrgEinheit",
    "build_email_signatur",
    "FASI",
    "FASI_ORG",
    # Geschlechtergerechte Sprache
    "paarform",
    "sparschreibung",
    "neutrale_form",
    "lint_geschlechtergerecht",
    "SprachIssue",
    # FaSi-Farbthemen
    "get_theme_palette",
    "get_theme_colors",
    "get_theme_labels",
    "list_themes",
    "get_unfallschwere_color",
    "get_ampel_color",
    "UNFALLSCHWERE_PALETTE",
    "UNFALLTYP_PALETTE",
    "AMPEL_PALETTE",
    "TREND_PALETTE",
    "VERKEHRSTEILNEHMER_PALETTE",
    "STRASSENTYP_PALETTE",
]
