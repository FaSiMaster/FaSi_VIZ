# FaSi ZH Viz

[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/FaSiMaster/FaSi_VIZ/actions/workflows/ci.yml/badge.svg)](https://github.com/FaSiMaster/FaSi_VIZ/actions)
[![Tests](https://img.shields.io/badge/tests-90%20passed-brightgreen)](https://github.com/FaSiMaster/FaSi_VIZ/actions)

**Visualisierungs-Library gemäss Kanton Zürich Designsystem**

Entwickelt von der [Fachstelle Verkehrssicherheit FaSi](https://www.zh.ch/de/direktion-der-justiz-und-des-innern/strassenverkehrsamt.html), Tiefbauamt, Baudirektion Kanton Zürich.

## Installation

```bash
pip install git+https://github.com/FaSiMaster/FaSi_VIZ.git
```

Oder lokal (editierbar):

```bash
git clone https://github.com/FaSiMaster/FaSi_VIZ.git
cd FaSi_VIZ
pip install -e ".[dev]"
```

## Schnellstart

```python
from fasi_zh_viz import (
    load_tokens,
    apply_matplotlib_style,
    format_int_ch,
    format_date_ch,
    build_source_line,
    validate_palette_against_background,
    get_theme_palette,
)
from datetime import date

# Design Tokens laden
tokens = load_tokens()

# Matplotlib mit KZH-CD konfigurieren
apply_matplotlib_style(tokens)

# Schweizer Zahlenformatierung
print(format_int_ch(1234567))              # "1'234'567"
print(format_date_ch(date(2026, 1, 21)))   # "21.01.2026"

# Pflichtangabe unter jeder Grafik
print(build_source_line("Statistisches Amt", "21.01.2026"))
# → "Quelle: Statistisches Amt (Stand 21.01.2026)"

# FaSi-Themenpalette für Unfallschwere
palette = get_theme_palette("unfallschwere")
# → {"leichtverletzte": "#FFCC00", "schwerverletzte": "#E87600", "getötete": "#B31523"}

# Kontrast prüfen
result = validate_palette_against_background(
    list(tokens["colors"]["infographics_palette"].values()), "#FFFFFF"
)
print(result["ok"])  # True
```

## Features

### Farben & Design Tokens
- Offizielle KZH-Webfarben aus `statistikZH/leu` Figma-Tokens (Single Source of Truth)
- 8 Akzentfarben, 17 Infografik-Farben, 7 Grautöne, Soft- und Darkmode-Varianten
- Druckfarben aus CD Manual 2025 (CMYK→RGB) in `cd_manual_colors`
- Farbgruppen (kalt/warm/neutral) für Farbenblindheits-sichere Kombinationen
- Typoskala (18 Stufen: 12px–72px), Breakpoints, Shadows, Grid

### FaSi-Farbthemen (Verkehrssicherheit)

| Theme | Inhalt |
|-------|--------|
| `unfallschwere` | Leichtverletzte / Schwerverletzte / Getötete |
| `unfalltyp` | Auffahrunfall, Abbiegeunfall, Fussgängerunfall u.a. |
| `trend` | Abnahme (gut) / Zunahme (schlecht) / Stabil / Ziel |
| `verkehrsteilnehmer` | Fussgänger, Velo, Motorrad, PKW, LKW/Bus, E-Scooter |
| `strassentyp` | Autobahn, Kantonsstrasse, Gemeindestrasse u.a. |

```python
from fasi_zh_viz import get_theme_colors, get_unfallschwere_color
colors = get_theme_colors("verkehrsteilnehmer")  # Liste von Hex-Werten
rot = get_unfallschwere_color("getötete")         # "#B31523"
```

### Validatoren

| Funktion | Prüft |
|----------|-------|
| `validate_palette_against_background()` | Kontrast ≥ 3:1 zum Hintergrund |
| `validate_text_contrast()` | WCAG AA (4.5:1 normal, 3.0:1 gross) |
| `validate_min_font_px()` | Minimum 12px für Infografiken |
| `validate_alt_text()` | Alt-Text vorhanden und ≤ 150 Zeichen |
| `validate_background_allowed()` | Hintergrund gemäss erlaubter Liste |
| `validate_palette_names_for_background()` | Farben für gewählten Hintergrund freigegeben |
| `warn_if_too_many_categories()` | Maximum 7 Kategorien empfohlen |
| `warn_if_palette_not_diverse_groups()` | Farbenblindheits-sichere Gruppenmischung |
| `lint_swiss_de_text()` | Prüft auf ß und falsche Anführungszeichen |
| `lint_geschlechtergerecht()` | Prüft auf Genderstern, Doppelpunkt, Binnenmajuskel |

### Text-Formatierung (Schweizer Hochdeutsch)

| Funktion | Beispiel |
|----------|----------|
| `format_int_ch(1234567)` | `"1'234'567"` |
| `format_float_ch(1234.5, 2)` | `"1'234,50"` |
| `format_percent_ch(12.5)` | `"12,5 %"` |
| `format_date_ch(date)` | `"21.01.2026"` |
| `format_time_ch(time)` | `"14.30"` / `"14.30 Uhr"` |
| `quote_primary("Text")` | `"«Text»"` |
| `quote_secondary("Text")` | `"‹Text›"` |

### Annotationen

```python
from fasi_zh_viz import build_source_line, build_caption, validate_alt_text

line = build_source_line("Statistisches Amt", "21.01.2026")
caption = build_caption(title="Bevölkerungsentwicklung", source_line=line)
result = validate_alt_text("Balkendiagramm zur Unfallentwicklung im Kanton Zürich")
```

### Sprache & Impressum

```python
from fasi_zh_viz import paarform, lint_geschlechtergerecht
print(paarform("Mitarbeiter"))  # "Mitarbeiterinnen und Mitarbeiter"

result = lint_geschlechtergerecht("Die Mitarbeiter*innen sind eingeladen.")
# → {"ok": False, "issues": [{"level": "error", ...}]}

from fasi_zh_viz import FASI, build_email_signatur
sig = build_email_signatur(FASI)  # Offizielle E-Mail-Signatur gemäss CD Manual S.23
```

### Themes & UI

```python
# Matplotlib
from fasi_zh_viz import apply_matplotlib_style
apply_matplotlib_style(tokens)

# Plotly
from fasi_zh_viz import apply_plotly_defaults
apply_plotly_defaults(tokens)

# Altair
from fasi_zh_viz import enable_altair_theme
enable_altair_theme(tokens)

# HTML-Footer (website / service_no_login / webapp_login)
from fasi_zh_viz.ui.footer import footer_html
html = footer_html("website", include_impressum=True)

# Verantwortliche Stellen
from fasi_zh_viz.ui.responsible import verantwortliche_stellen_html
html = verantwortliche_stellen_html([
    ("Statistisches Amt", "https://www.zh.ch/statistik"),
])
```

## Infografik-Vorgaben (ZH-Designsystem)

| Regel | Wert |
|-------|------|
| Minimale Schriftgrösse | 12 px |
| Kontrast Grafik zu Hintergrund | ≥ 3:1 |
| Kontrast Text (normal) | ≥ 4.5:1 (WCAG AA) |
| Kontrast Text (gross) | ≥ 3.0:1 |
| Maximale Kategorien | 7 (empfohlen) |
| Erlaubte Hintergründe | Weiss, Schwarz 5, Schwarz 10 |
| Erlaubte Textfarben | Schwarz, Grau 60, Weiss |
| Tausendertrennzeichen | Apostroph `'` (Fliesstext) / Schmales Leerzeichen (Tabellen) |

## Quellen

| Quelle | Inhalt |
|--------|--------|
| [statistikZH/leu](https://github.com/statistikZH/leu) | Offizielle Figma Design-Tokens (Farben, Typografie, Breakpoints) |
| [KZH Designsystem – Farben](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten/inhalt/designsystem/design-grundlagen/farben.html) | Webfarben, Infografik-Palette |
| [KZH Designsystem – Typografie](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten/inhalt/designsystem/design-grundlagen/typografie.html) | Web-Schriften |
| [KZH Designsystem – Infografiken](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten/inhalt/designsystem/design-grundlagen/infografiken-und-visualisierungen.html) | Infografik-Regeln |
| [KZH Barrierefreiheit](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten/inhalt/barrierefreiheit/vorgaben-zur-barrierefreiheit/barrierefreiheit-von-infografiken-und-visualisierungen.html) | WCAG-Vorgaben |
| Kanton Zürich CD Manual 2025 | Print-CD, E-Mail-Signatur S.23, Office-Typografie S.40–47 |
| [BK-Leitfaden Geschlechtergerechte Sprache](https://www.bk.admin.ch/dam/bk/de/dokumente/sprachdienste/leitfaden-geschlechtergerechte-sprache.pdf) | Sprachregeln, 3. Auflage |
| [WCAG 2.1 (W3C)](https://www.w3.org/TR/WCAG21/) | Kontrastschwellen |
| ASTRA Unfalltypenklassierung | Grundlage für `fasi_themes.py` |

## Entwicklung

```bash
# Repo klonen und Umgebung einrichten
git clone https://github.com/FaSiMaster/FaSi_VIZ.git
cd FaSi_VIZ
pip install -e ".[dev]"

# Tests
pytest tests/ -v

# Linting + Typecheck
ruff check src/
mypy src/fasi_zh_viz/ --ignore-missing-imports
```

Siehe [CONTRIBUTING.md](CONTRIBUTING.md), [CHANGELOG.md](CHANGELOG.md) und [docs/](docs/) für Glossar und Projektstruktur.

## Sicherheit

Sicherheitslücken bitte **nicht** als öffentliches Issue melden — siehe [SECURITY.md](SECURITY.md).

## Lizenz

MIT License — siehe [LICENSE](LICENSE)

## Kontakt

Fachstelle Verkehrssicherheit FaSi
Tiefbauamt, Baudirektion Kanton Zürich
stevan.skeledzic@bd.zh.ch
