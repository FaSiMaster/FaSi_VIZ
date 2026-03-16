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
        assert tokens["meta"]["version"] == "2.5.0"

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
        result = lint_swiss_de_text("Er sagte \u201eHallo\u201c")
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


class TestImpressum:
    """Tests für Impressum-Modul (NEU in v2.2)"""

    def test_fasi_kontakt_vorhanden(self):
        from fasi_zh_viz.impressum import FASI
        assert FASI.vorname == "Stevan"
        assert FASI.nachname == "Skeledžić"
        assert FASI.email == "stevan.skeledzic@bd.zh.ch"

    def test_email_signatur_plain(self):
        from fasi_zh_viz.impressum import build_email_signatur, FASI
        sig = build_email_signatur(FASI)
        assert "Freundliche Grüsse" in sig
        assert "Stevan Skeledžić" in sig
        assert "Kanton Zürich" in sig
        assert "Baudirektion" in sig
        assert "stevan.skeledzic@bd.zh.ch" in sig
        assert "+41 43 259 31 20" in sig

    def test_email_signatur_html(self):
        from fasi_zh_viz.impressum import build_email_signatur, FASI
        sig = build_email_signatur(FASI, plain_text=False)
        assert "<strong>" in sig
        assert "Baudirektion" in sig

    def test_org_einheit_stempelversion(self):
        from fasi_zh_viz.impressum import FASI_ORG
        zeilen = FASI_ORG.as_stempelversion()
        assert len(zeilen) == 3
        assert zeilen[0] == "Kanton Zürich"
        assert zeilen[1] == "Baudirektion"

    def test_org_einheit_burostempel(self):
        from fasi_zh_viz.impressum import FASI_ORG
        zeilen = FASI_ORG.as_burostempel()
        assert len(zeilen) >= 3
        assert "Kanton Zürich" in zeilen


class TestSprache:
    """Tests für geschlechtergerechte Sprache (NEU in v2.2)"""

    def test_paarform_bekannt(self):
        from fasi_zh_viz.sprache import paarform
        result = paarform("Mitarbeiter")
        assert "Mitarbeiterinnen" in result
        assert "Mitarbeiter" in result

    def test_sparschreibung(self):
        from fasi_zh_viz.sprache import sparschreibung
        result = sparschreibung("Mitarbeiter")
        assert result == "Mitarbeiter/-innen"

    def test_lint_genderstern_verboten(self):
        from fasi_zh_viz.sprache import lint_geschlechtergerecht
        result = lint_geschlechtergerecht("Die Mitarbeiter*innen sind eingeladen.")
        assert result["ok"] is False
        assert len(result["issues"]) > 0

    def test_lint_doppelpunkt_verboten(self):
        from fasi_zh_viz.sprache import lint_geschlechtergerecht
        result = lint_geschlechtergerecht("Die Mitarbeiter:innen sind eingeladen.")
        assert result["ok"] is False

    def test_lint_paarform_ok(self):
        from fasi_zh_viz.sprache import lint_geschlechtergerecht
        result = lint_geschlechtergerecht("Die Mitarbeiterinnen und Mitarbeiter sind eingeladen.")
        assert result["ok"] is True

    def test_neutrale_form(self):
        from fasi_zh_viz.sprache import neutrale_form
        result = neutrale_form("Mitarbeiter")
        assert result == "Mitarbeitende"


class TestCDManualColors:
    """Tests für CD Manual Farben (NEU in v2.2)"""

    def test_cd_manual_colors_vorhanden(self):
        tokens = load_tokens()
        assert "cd_manual_colors" in tokens
        assert "cyan_zh" in tokens["cd_manual_colors"]
        assert "gelb_zh" in tokens["cd_manual_colors"]  # war bisher fehlend

    def test_cd_manual_10_farben(self):
        tokens = load_tokens()
        cd_colors = {k: v for k, v in tokens["cd_manual_colors"].items() if not k.startswith("_")}
        assert len(cd_colors) == 10

    def test_typography_office_vorhanden(self):
        tokens = load_tokens()
        assert "typography_office" in tokens
        assert "brief_dokument" in tokens["typography_office"]
        assert "email_signatur" in tokens["typography_office"]
        assert "powerpoint" in tokens["typography_office"]

    def test_typography_print_vorhanden(self):
        tokens = load_tokens()
        assert "typography_print" in tokens
        assert "publikationen" in tokens["typography_print"]


class TestFarbenV23:
    """Tests fuer Farbkorrekturen und neue Token-Sektionen (v2.3)"""

    def test_blau_korrekter_wert(self):
        """accent.blau muss #0076BD sein (leu + CD Manual bestaetigt)."""
        tokens = load_tokens()
        assert tokens["colors"]["accent"]["blau"] == "#0076BD", \
            "blau war #0070B4 (falsch) - korrekter Wert: #0076BD"

    def test_infografik_blau_korrekter_wert(self):
        tokens = load_tokens()
        assert tokens["colors"]["infographics_palette"]["blau"] == "#0076BD"

    def test_blau_kontrast_auf_weiss(self):
        """#0076BD muss Mindestkontrast 3:1 auf Weiss haben."""
        ratio = contrast_ratio("#0076BD", "#FFFFFF")
        assert ratio >= 3.0, f"Kontrast #0076BD auf Weiss: {ratio:.2f} < 3.0"

    def test_breakpoints_vorhanden(self):
        tokens = load_tokens()
        bp = tokens["breakpoints"]
        assert bp["small"] == 400
        assert bp["regular"] == 600
        assert bp["medium"] == 840
        assert bp["large"] == 1024
        assert bp["xlarge"] == 1280

    def test_shadows_vorhanden(self):
        tokens = load_tokens()
        sh = tokens["shadows"]
        assert "short" in sh
        assert "regular" in sh
        assert "long" in sh

    def test_grid_vorhanden(self):
        tokens = load_tokens()
        grid = tokens["grid"]
        assert grid["columns"] == 12
        assert grid["max_width_rem"] == 73

    def test_typography_scale_vorhanden(self):
        tokens = load_tokens()
        scale = tokens["typography"]["scale"]
        assert "tiny" in scale
        assert "giant" in scale
        assert scale["tiny"]["size_px"] == 12
        assert scale["giant"]["size_px"] == 72

    def test_typography_scale_vollstaendig(self):
        """Alle 18 Skalenstufen muessen vorhanden sein."""
        tokens = load_tokens()
        scale = {k: v for k, v in tokens["typography"]["scale"].items()
                 if not k.startswith("_")}
        assert len(scale) == 18

    def test_font_family_regular_und_black_getrennt(self):
        tokens = load_tokens()
        assert "font_family_regular" in tokens["typography"]
        assert "font_family_black" in tokens["typography"]
        assert tokens["typography"]["font_family_regular"][0] == "InterRegular"
        assert tokens["typography"]["font_family_black"][0] == "InterBlack"

    def test_responsive_curves_vorhanden(self):
        tokens = load_tokens()
        curves = tokens["typography"]["responsive_curves"]
        assert "tiny_curve" in curves
        assert "huge_curve" in curves


class TestVersionSync:
    """Version muss in __init__.py und pyproject.toml übereinstimmen."""

    def test_version_konsistent(self):
        import fasi_zh_viz
        import importlib.metadata
        pkg_version = importlib.metadata.version("fasi-zh-viz")
        assert fasi_zh_viz.__version__ == pkg_version, (
            f"__init__.py hat {fasi_zh_viz.__version__}, "
            f"pyproject.toml hat {pkg_version}"
        )


class TestUngueltigeEingaben:
    """Robustheit bei ungültigen Eingaben."""

    def test_contrast_ungueltige_hex(self):
        import pytest
        from fasi_zh_viz import contrast_ratio
        with pytest.raises(ValueError):
            contrast_ratio("rot", "#FFFFFF")

    def test_contrast_zu_kurz(self):
        import pytest
        from fasi_zh_viz import contrast_ratio
        with pytest.raises(ValueError):
            contrast_ratio("#FFF", "#000000")

    def test_luminance_ungueltige_hex(self):
        import pytest
        from fasi_zh_viz import relative_luminance
        with pytest.raises(ValueError):
            relative_luminance("#GGGGGG")


class TestValidatorenErweitert:
    """Tests für bisher nicht abgedeckte Validatoren."""

    def test_validate_background_allowed_ok(self):
        from fasi_zh_viz import validate_background_allowed
        result = validate_background_allowed(
            "#FFFFFF", allowed=["#FFFFFF", "#F5F5F5"]
        )
        assert result["ok"] is True

    def test_validate_background_allowed_fail(self):
        from fasi_zh_viz import validate_background_allowed
        result = validate_background_allowed(
            "#FF0000", allowed=["#FFFFFF", "#F5F5F5"]
        )
        assert result["ok"] is False

    def test_validate_background_inverted(self):
        from fasi_zh_viz import validate_background_allowed
        result = validate_background_allowed(
            "#000000",
            allowed=["#FFFFFF"],
            allowed_inverted=["#000000"],
            inverted=True,
        )
        assert result["ok"] is True

    def test_validate_palette_names_ok(self):
        from fasi_zh_viz import validate_palette_names_for_background
        result = validate_palette_names_for_background(
            palette_names=["blau", "gruen"],
            background="#FFFFFF",
            palette_by_background={"#FFFFFF": ["blau", "gruen", "rot"]},
        )
        assert result["ok"] is True

    def test_validate_palette_names_fail(self):
        from fasi_zh_viz import validate_palette_names_for_background
        result = validate_palette_names_for_background(
            palette_names=["blau", "hellgelb"],
            background="#FFFFFF",
            palette_by_background={"#FFFFFF": ["blau", "gruen"]},
        )
        assert result["ok"] is False
        assert "hellgelb" in result["disallowed"]

    def test_warn_palette_not_diverse(self):
        from fasi_zh_viz import warn_if_palette_not_diverse_groups
        result = warn_if_palette_not_diverse_groups(
            palette_names=["blau", "hellblau"],
            palette_groups={"blau_gruppe": ["blau", "hellblau"], "rot_gruppe": ["rot"]},
            min_distinct_groups=2,
        )
        assert result["ok"] is False

    def test_warn_legend_outside(self):
        from fasi_zh_viz import warn_if_legend_not_outside
        assert warn_if_legend_not_outside(True)["ok"] is True
        assert warn_if_legend_not_outside(False)["ok"] is False


class TestUIKomponenten:
    """Tests für HTML-UI-Komponenten (XSS-Schutz)."""

    def test_responsible_html_normaler_input(self):
        from fasi_zh_viz.ui.responsible import verantwortliche_stellen_html
        html = verantwortliche_stellen_html([
            ("Statistisches Amt", "https://www.zh.ch/statistik")
        ])
        assert "Statistisches Amt" in html
        assert "https://www.zh.ch/statistik" in html
        assert "fasi-chip" in html

    def test_responsible_html_xss_url(self):
        """javascript:-URLs müssen abgelehnt werden."""
        import pytest
        from fasi_zh_viz.ui.responsible import verantwortliche_stellen_html
        with pytest.raises(ValueError):
            verantwortliche_stellen_html([("Test", "javascript:alert(1)")])

    def test_responsible_html_xss_label(self):
        """HTML in Labels muss escaped werden."""
        from fasi_zh_viz.ui.responsible import verantwortliche_stellen_html
        html_out = verantwortliche_stellen_html([
            ("<script>alert(1)</script>", "https://example.com")
        ])
        assert "<script>" not in html_out
        assert "&lt;script&gt;" in html_out

    def test_footer_website(self):
        from fasi_zh_viz.ui.footer import footer_html
        html = footer_html("website")
        assert "fasi-footer" in html
        assert "Kanton Zürich" in html
        assert "Copyright" in html

    def test_footer_unbekannter_kind(self):
        import pytest
        from fasi_zh_viz.ui.footer import footer_html
        with pytest.raises(ValueError):
            footer_html("unbekannt")


class TestARIAKomponenten:
    """Tests für ARIA-Barrierefreiheitsattribute in HTML-Komponenten (NEU in v2.5)."""

    def test_footer_role_contentinfo(self):
        from fasi_zh_viz.ui.footer import footer_html
        html = footer_html("website")
        assert 'role="contentinfo"' in html

    def test_responsible_aria_label(self):
        from fasi_zh_viz.ui.responsible import verantwortliche_stellen_html
        html_out = verantwortliche_stellen_html([
            ("Statistisches Amt", "https://www.zh.ch/statistik")
        ])
        assert 'aria-label=' in html_out

    def test_responsible_chip_role_listitem(self):
        from fasi_zh_viz.ui.responsible import verantwortliche_stellen_html
        html_out = verantwortliche_stellen_html([
            ("Tiefbauamt", "https://www.zh.ch/tba")
        ])
        assert "role='listitem'" in html_out or 'role="listitem"' in html_out
        assert "role='list'" in html_out or 'role="list"' in html_out

    def test_footer_nav_aria_label(self):
        from fasi_zh_viz.ui.footer import footer_html
        html_out = footer_html("website")
        assert "aria-label='Footer-Navigation'" in html_out or 'aria-label="Footer-Navigation"' in html_out

    def test_footer_external_links_aria_label(self):
        from fasi_zh_viz.ui.footer import footer_html
        html_out = footer_html("website")
        assert 'aria-label="Externer Link:' in html_out


class TestFaSiThemes:
    """Tests für FaSi-eigene Farbthemen (Verkehrssicherheit)."""

    def test_alle_themes_vorhanden(self):
        from fasi_zh_viz import list_themes
        themes = list_themes()
        assert "unfallschwere" in themes
        assert "unfalltyp" in themes
        assert "trend" in themes
        assert "verkehrsteilnehmer" in themes
        assert "strassentyp" in themes

    def test_unfallschwere_drei_stufen(self):
        from fasi_zh_viz import get_theme_palette
        palette = get_theme_palette("unfallschwere")
        assert "leichtverletzte" in palette
        assert "schwerverletzte" in palette
        assert "getötete" in palette

    def test_theme_farben_gueltige_hex(self):
        """Alle Theme-Farben müssen gültige Hex-Werte sein."""
        from fasi_zh_viz import list_themes, get_theme_palette, contrast_ratio
        for theme in list_themes():
            for label, color in get_theme_palette(theme).items():
                # contrast_ratio wirft ValueError bei ungültigen Hex-Werten
                ratio = contrast_ratio(color, "#FFFFFF")
                assert ratio >= 1.0, f"{theme}/{label}: {color} ist keine gültige Farbe"

    def test_unfallschwere_farben_gueltig(self):
        """Alle Unfallschwere-Farben müssen gültige Hex-Werte sein.
        Hinweis: Füllfarben in Charts müssen kein 3:1 Textkontrast erfüllen —
        die Bedeutung wird durch Label + Form getragen, nicht nur durch Farbe.
        """
        from fasi_zh_viz import get_theme_palette, contrast_ratio
        for label, color in get_theme_palette("unfallschwere").items():
            ratio = contrast_ratio(color, "#FFFFFF")
            assert ratio >= 1.0, f"{label} ({color}): ungültige Farbe"

    def test_theme_colors_list(self):
        from fasi_zh_viz import get_theme_colors
        colors = get_theme_colors("trend")
        assert isinstance(colors, list)
        assert len(colors) == 4

    def test_theme_labels_list(self):
        from fasi_zh_viz import get_theme_labels
        labels = get_theme_labels("verkehrsteilnehmer")
        assert "fussgänger" in labels
        assert "velo" in labels

    def test_get_unfallschwere_color(self):
        from fasi_zh_viz import get_unfallschwere_color
        assert get_unfallschwere_color("getötete") == "#B31523"
        assert get_unfallschwere_color("unbekannt") is None

    def test_unbekanntes_theme_raises(self):
        import pytest
        from fasi_zh_viz import get_theme_palette
        with pytest.raises(ValueError):
            get_theme_palette("nichtvorhanden")
