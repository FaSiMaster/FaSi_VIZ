# FaSi ZH Viz

[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/kanton-zuerich/fasi-zh-viz/actions/workflows/ci.yml/badge.svg)](https://github.com/kanton-zuerich/fasi-zh-viz/actions)

**Visualisierungs-Library gemäss Kanton Zürich Designsystem**

Diese Library stellt Farben, Typografie, Validatoren und Formatierungs-Utilities für Infografiken bereit, die den Vorgaben des [Kanton Zürich Designsystems](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten.html) und den [Schreibweisungen der Bundeskanzlei](https://www.bk.admin.ch/dam/bk/de/dokumente/sprachdienste/sprachdienst_de/schreibweisungen.pdf) entsprechen.

## Installation

```bash
pip install fasi-zh-viz
```

Oder direkt von GitHub:

```bash
pip install git+https://github.com/kanton-zuerich/fasi-zh-viz.git
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
)

# Tokens laden
tokens = load_tokens()

# Matplotlib konfigurieren
apply_matplotlib_style(tokens)

# Schweizer Formatierung
print(format_int_ch(1234567))  # "1'234'567"
print(format_date_ch(datetime.now()))  # "21.01.2026"

# Quellenangabe (PFLICHT unter jeder Grafik!)
print(build_source_line("Statistisches Amt", "21.01.2026"))
# "Quelle: Statistisches Amt (Stand 21.01.2026)"

# Palette validieren (Kontrast >= 3:1)
palette = list(tokens["colors"]["infographics_palette"].values())
result = validate_palette_against_background(palette, "#FFFFFF")
```

## Features

### Farben
- 8 Akzentfarben
- 17 Infografik-Farben (mit Kontrast-geprüfter Zuordnung pro Hintergrund)
- 7 Grautöne
- Soft-Varianten für Hintergründe
- Darkmode-Farben
- Farbgruppen (kalt/warm/neutral) für Farbenblindheit

### Validatoren
| Funktion | Prüft |
|----------|-------|
| `validate_palette_against_background()` | Kontrast >= 3:1 zum Hintergrund |
| `validate_text_contrast()` | WCAG AA (4.5:1 normal, 3.0:1 gross) |
| `validate_min_font_px()` | Minimum 12px für Infografiken |
| `warn_if_too_many_categories()` | Maximum 7 Kategorien empfohlen |
| `validate_alt_text()` | Alt-Text vorhanden und < 150 Zeichen |
| `lint_swiss_de_text()` | Prüft auf ß und falsche Anführungszeichen |

### Text-Formatierung (Schweizer Hochdeutsch)
| Funktion | Beispiel |
|----------|----------|
| `format_int_ch(1234567)` | `"1'234'567"` |
| `format_float_ch(1234.5, 2)` | `"1'234,50"` |
| `format_percent_ch(12.5)` | `"12,5 %"` |
| `format_date_ch(date)` | `"21.01.2026"` |
| `format_time_ch(time)` | `"14.30"` |
| `quote_primary("Text")` | `"«Text»"` |

### Annotationen
| Funktion | Beschreibung |
|----------|--------------|
| `build_source_line()` | Quellenzeile für Grafiken |
| `build_caption()` | Komplette Bildunterschrift |
| `validate_alt_text()` | Alt-Text-Validierung |

### Themes
- **Matplotlib**: `apply_matplotlib_style(tokens)`
- **Plotly**: `apply_plotly_defaults(tokens)`
- **Altair**: `enable_altair_theme(tokens)`

### UI-Templates
- Footer (3 Varianten: website, service_no_login, webapp_login)
- Verantwortliche Stellen
- CSS inkludiert: `load_css("ui.css")`

## Infografik-Regeln (ZH-Designsystem)

| Regel | Wert |
|-------|------|
| Minimale Schriftgrösse | 12px |
| Kontrast Grafik zu Hintergrund | >= 3:1 |
| Kontrast Text (normal) | >= 4.5:1 |
| Kontrast Text (gross) | >= 3:1 |
| Maximale Kategorien | 7 (empfohlen) |
| Erlaubte Hintergründe | Weiss, Schwarz 5, Schwarz 10 |
| Erlaubte Textfarben | Schwarz, Grau 60, Weiss |

## Quellen

Die Vorgaben stammen aus dem offiziellen Designsystem:

- [Farben](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten/inhalt/designsystem/design-grundlagen/farben.html)
- [Typografie](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten/inhalt/designsystem/design-grundlagen/typografie.html)
- [Infografiken](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten/inhalt/designsystem/design-grundlagen/infografiken-und-visualisierungen.html)
- [Barrierefreiheit](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten/inhalt/barrierefreiheit/vorgaben-zur-barrierefreiheit/barrierefreiheit-von-infografiken-und-visualisierungen.html)

## Entwicklung

```bash
# Repository klonen
git clone https://github.com/kanton-zuerich/fasi-zh-viz.git
cd fasi-zh-viz

# Entwicklungsumgebung
pip install -e ".[dev]"

# Tests ausführen
pytest
```

## Lizenz

MIT License - siehe [LICENSE](LICENSE)

## Kontakt

Fachstelle Verkehrssicherheit FaSi  
Tiefbauamt Kanton Zürich  
fasi@bd.zh.ch
