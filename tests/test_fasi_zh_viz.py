"""Tests für fasi_zh_viz"""

import pytest
from fasi_zh_viz import (
    load_tokens,
    contrast_ratio,
    relative_luminance,
    validate_palette_against_background,
    validate_text_contrast,
    validate_min_font_px,
    warn_if_too_many_categories,
)


class TestTokens:
    """Tests für Token-Loading"""

    def test_load_tokens(self):
        tokens = load_tokens()
        assert tokens is not None
        assert "meta" in tokens
        assert "colors" in tokens
        assert "typography" in tokens

    def test_tokens_version(self):
        tokens = load_tokens()
        assert tokens["meta"]["version"] == "2.0.0"

    def test_infographics_palette_exists(self):
        tokens = load_tokens()
        palette = tokens["colors"]["infographics_palette"]
        assert len(palette) >= 10  # Mindestens 10 Farben


class TestContrast:
    """Tests für Kontrast-Berechnung"""

    def test_contrast_black_white(self):
        # Schwarz auf Weiss = 21:1 (Maximum)
        ratio = contrast_ratio("#000000", "#FFFFFF")
        assert ratio == pytest.approx(21.0, rel=0.01)

    def test_contrast_same_color(self):
        # Gleiche Farbe = 1:1
        ratio = contrast_ratio("#0070B4", "#0070B4")
        assert ratio == pytest.approx(1.0, rel=0.01)

    def test_contrast_zh_blau(self):
        # ZH Blau auf Weiss
        ratio = contrast_ratio("#0070B4", "#FFFFFF")
        assert ratio >= 4.5  # WCAG AA für Text

    def test_luminance_black(self):
        lum = relative_luminance("#000000")
        assert lum == pytest.approx(0.0, abs=0.001)

    def test_luminance_white(self):
        lum = relative_luminance("#FFFFFF")
        assert lum == pytest.approx(1.0, abs=0.001)


class TestValidators:
    """Tests für Validatoren"""

    def test_palette_validation_ok(self):
        # Dunkle Farben auf Weiss sollten OK sein
        result = validate_palette_against_background(
            ["#00407C", "#00797B"], "#FFFFFF", min_ratio=3.0
        )
        assert result["ok"] is True

    def test_palette_validation_fail(self):
        # Sehr helle Farbe auf Weiss sollte fehlschlagen
        result = validate_palette_against_background(
            ["#F0F0F0"], "#FFFFFF", min_ratio=3.0
        )
        assert result["ok"] is False

    def test_text_contrast_normal(self):
        # Schwarz auf Weiss
        result = validate_text_contrast("#000000", "#FFFFFF", is_large_text=False)
        assert result["ok"] is True
        assert result["ratio"] >= 4.5

    def test_text_contrast_large(self):
        # Grau auf Weiss (nur für grossen Text OK)
        result = validate_text_contrast("#666666", "#FFFFFF", is_large_text=True)
        assert result["ok"] is True  # 3:1 reicht für grossen Text

    def test_font_size_ok(self):
        result = validate_min_font_px(12, min_px=12)
        assert result["ok"] is True

    def test_font_size_too_small(self):
        result = validate_min_font_px(10, min_px=12)
        assert result["ok"] is False

    def test_categories_ok(self):
        result = warn_if_too_many_categories(5, recommended_max=7)
        assert result["ok"] is True

    def test_categories_too_many(self):
        result = warn_if_too_many_categories(10, recommended_max=7)
        assert result["ok"] is False


class TestInfographicsRules:
    """Tests basierend auf ZH-Designsystem Vorgaben"""

    def test_all_infographics_colors_contrast_on_white(self):
        """Alle Infografik-Farben müssen 3:1 auf Weiss haben"""
        tokens = load_tokens()
        palette = list(tokens["colors"]["infographics_palette"].values())
        
        result = validate_palette_against_background(palette, "#FFFFFF", min_ratio=3.0)
        
        # Alle sollten auf Weiss OK sein
        assert result["ok"] is True, f"Farben mit zu wenig Kontrast: {result['issues']}"

    def test_text_colors_allowed(self):
        """Nur Schwarz, Grau 60, Weiss als Textfarben"""
        tokens = load_tokens()
        allowed = tokens["infographics_rules"]["text_colors_allowed"]
        
        assert "#000000" in allowed  # Schwarz
        assert "#666666" in allowed  # Grau 60
        assert "#FFFFFF" in allowed  # Weiss

    def test_min_font_size(self):
        """Minimale Schriftgrösse muss 12px sein"""
        tokens = load_tokens()
        min_font = tokens["typography"]["note"]["min_font_px_in_infographics"]
        
        assert min_font == 12

    def test_palette_by_background_exists(self):
        """palette_by_background muss definiert sein"""
        tokens = load_tokens()
        assert "palette_by_background" in tokens["infographics_rules"]
        assert "#FFFFFF" in tokens["infographics_rules"]["palette_by_background"]


class TestTextFormat:
    """Tests für Schweizer Text-Formatierung (NEU in v2.1)"""

    def test_format_int_ch(self):
        from fasi_zh_viz import format_int_ch
        assert format_int_ch(1234567) == "1'234'567"
        assert format_int_ch(123) == "123"
        assert format_int_ch(0) == "0"

    def test_format_float_ch(self):
        from fasi_zh_viz import format_float_ch
        assert format_float_ch(1234.5, 2) == "1'234,50"
        assert format_float_ch(0.5, 1) == "0,5"

    def test_format_percent_ch(self):
        from fasi_zh_viz import format_percent_ch
        assert format_percent_ch(12.5, 1) == "12,5 %"
        assert format_percent_ch(0.125, 1, value_is_fraction=True) == "12,5 %"

    def test_format_date_ch(self):
        from fasi_zh_viz import format_date_ch
        from datetime import date
        d = date(2026, 1, 21)
        assert format_date_ch(d) == "21.01.2026"

    def test_format_time_ch(self):
        from fasi_zh_viz import format_time_ch
        from datetime import time
        t = time(14, 30)
        assert format_time_ch(t) == "14.30"
        assert format_time_ch(t, with_uhr=True) == "14.30 Uhr"

    def test_quote_primary(self):
        from fasi_zh_viz import quote_primary
        assert quote_primary("Test") == "«Test»"

    def test_quote_secondary(self):
        from fasi_zh_viz import quote_secondary
        assert quote_secondary("Test") == "‹Test›"

    def test_lint_swiss_de_eszett(self):
        from fasi_zh_viz import lint_swiss_de_text
        result = lint_swiss_de_text("Strasse")
        assert result["ok"] is True
        
        result = lint_swiss_de_text("Straße")
        assert len(result["issues"]) > 0  # Warnung wegen ß

    def test_lint_swiss_de_quotes(self):
        from fasi_zh_viz import lint_swiss_de_text
        result = lint_swiss_de_text("Er sagte „Hallo"")
        assert len(result["issues"]) > 0  # Warnung wegen deutscher Anführungszeichen


class TestAnnotations:
    """Tests für Annotationen (NEU in v2.1)"""

    def test_build_source_line(self):
        from fasi_zh_viz import build_source_line
        line = build_source_line("Statistisches Amt")
        assert "Quelle:" in line
        assert "Statistisches Amt" in line

    def test_build_source_line_with_date(self):
        from fasi_zh_viz import build_source_line
        line = build_source_line("Statistisches Amt", "21.01.2026")
        assert "Stand 21.01.2026" in line

    def test_build_caption(self):
        from fasi_zh_viz import build_caption
        caption = build_caption(
            title="Bevölkerungsentwicklung",
            source_line="Quelle: Statistisches Amt"
        )
        assert "Bevölkerungsentwicklung" in caption
        assert "Quelle" in caption

    def test_validate_alt_text_ok(self):
        from fasi_zh_viz import validate_alt_text
        result = validate_alt_text("Balkendiagramm zur Bevölkerungsentwicklung im Kanton Zürich")
        assert result["ok"] is True

    def test_validate_alt_text_empty(self):
        from fasi_zh_viz import validate_alt_text
        result = validate_alt_text("")
        assert result["ok"] is False

    def test_validate_alt_text_too_long(self):
        from fasi_zh_viz import validate_alt_text
        long_text = "x" * 200
        result = validate_alt_text(long_text, max_chars=150)
        assert len(result["issues"]) > 0  # Warnung wegen Länge
