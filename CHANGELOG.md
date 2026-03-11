# Changelog

Alle wichtigen Änderungen werden in dieser Datei dokumentiert.
Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

---

## [2.4.0] – 2026-03-11

### Hinzugefügt
- `fasi_themes.py`: FaSi-eigene Farbempfehlungen für Verkehrssicherheitsthemen
  - `UNFALLSCHWERE_PALETTE`: Leichtverletzte / Schwerverletzte / Getötete
  - `UNFALLTYP_PALETTE`: Auffahrunfall, Abbiegeunfall, Fussgängerunfall u.a.
  - `TREND_PALETTE`: Abnahme (gut) / Zunahme (schlecht) / Stabil / Ziel
  - `VERKEHRSTEILNEHMER_PALETTE`: Fussgänger, Velo, Motorrad, PKW, LKW/Bus, E-Scooter
  - `STRASSENTYP_PALETTE`: Autobahn, Kantonsstrasse, Gemeindestrasse u.a.
  - Funktionen: `get_theme_palette()`, `get_theme_colors()`, `get_theme_labels()`,
    `list_themes()`, `get_unfallschwere_color()`
- `TestVersionSync`: Test prüft ob `__version__` und `pyproject.toml` übereinstimmen
- `TestUngueltigeEingaben`: Tests für ungültige Hex-Farben (raises ValueError)
- `TestValidatorenErweitert`: Tests für bisher nicht abgedeckte Validatoren
- `TestUIKomponenten`: Tests für HTML-Komponenten inkl. XSS-Prüfung
- `TestFaSiThemes`: 8 Tests für die neuen FaSi-Farbthemen
- CI: Neuer `security`-Job mit `bandit` (Python-Sicherheitsscanner)
- `/fasi-check` Claude Code Skill für Qualitätschecks

### Geändert
- `responsible.py`: XSS-Sicherheitslücke geschlossen
  - Labels werden mit `html.escape()` escaped
  - URLs werden auf erlaubte Schemas beschränkt (`https://`, `http://`, `/`, `#`)
  - `javascript:` und andere gefährliche Schemas lösen `ValueError` aus
- CI: Coverage-Upload nur auf Python 3.11 (nicht 4×), `publish`-Job wartet auf `security`

### Erhöht
- Tests: 60 → 84 (+24 neue Tests)

---

## [2.3.0] – 2026-03-11

### Hinzugefügt
- `tokens.json` v2.3.0: vollständige Figma/leu Token-Integration
  - `typography.scale`: 18-stufige Typoskala (tiny 12px → giant 72px)
  - `typography.font_family_regular` und `font_family_black` (Inter / HelveticaNow)
  - `typography.responsive_curves`: Breakpoint-zu-Skalenstufe-Mapping
  - `breakpoints`: 400 / 600 / 840 / 1024 / 1280 px (aus statistikZH/leu)
  - `shadows`: short / regular / long
  - `grid`: 12-Spalten, max-width 73rem
  - `text_rules.table_thousands_separator`: geschütztes Leerzeichen für Tabellen

### Geändert (Korrekturen)
- `colors.accent.blau`: `#0070B4` → `#0076BD` (korrekter Wert per CD Manual RGB 0/118/189
  und statistikZH/leu Figma-Tokens)
- `colors.infographics_palette.blau`: gleiche Korrektur
- `altair_theme.py`: hardcodierter `font = "Inter"` → aus `tokens["typography"]["web_default_font_family"][0]`
- `meta.version`: `"2.2.0"` → `"2.3.0"`

### Quellen ergänzt
- `meta.sources.leu_github`: statistikZH/leu GitHub Repository
- `meta.sources.cd_manual`: Kanton Zürich Corporate Design Manual 2025

---

## [2.2.0] – 2026-03-11

### Hinzugefügt
- `impressum.py`: E-Mail-Signatur und Stempelversion gemäss CD Manual S.23
  - `KontaktPerson` Dataclass mit allen Kontaktfeldern
  - `OrgEinheit` mit `as_stempelversion()` (3 Zeilen) und `as_burostempel()` (bis 5 Zeilen)
  - `build_email_signatur()`: Plain-Text oder HTML-Signatur
  - Vordefiniert: `FASI` (Stevan Skeledžić), `FASI_ORG` (Baudirektion / TBA / FaSi)
- `sprache.py`: Geschlechtergerechte Sprache gemäss Bundeskanzlei-Leitfaden 3. Auflage
  - `paarform()`: «Mitarbeiterinnen und Mitarbeiter»
  - `sparschreibung()`: «Mitarbeiter/-innen» (nur für Formulare)
  - `neutrale_form()`: «Mitarbeitende»
  - `lint_geschlechtergerecht()`: prüft auf Genderstern, Doppelpunkt, Unterstrich,
    Binnenmajuskel
- `tokens.json`: `cd_manual_colors` (10 Druckfarben aus CD Manual, inkl. Gelb ZH `#FFCC00`)
- `tokens.json`: `typography_office` (Arial-Grössen für Word/Excel/PowerPoint/E-Mail)
- `tokens.json`: `typography_print` (Helvetica Neue für InDesign)
- `TestImpressum`, `TestSprache`, `TestCDManualColors` (15 neue Tests)

### Geändert
- `pyproject.toml` und `README.md`: URLs auf `FaSiMaster/FaSi_VIZ` korrigiert
- `__init__.py`: Alle neuen Module exportiert

### Behoben
- `_note`-Key in `infographics_palette` entfernt (verursachte Kontrast-Test-Fehler)

---

## [2.1.0] – 2026-03-11

### Erste vollständige Version

- Design Tokens (`tokens.json`) als Single Source of Truth
- Kontrastberechnung nach WCAG 2.1 (relative Luminanz, Kontrastverhältnis)
- Validatoren: Palette, Text, Schriftgrösse, Kategorienanzahl, Alt-Text
- Schweizer Textformatierung: `format_int_ch`, `format_float_ch`, `format_percent_ch`,
  `format_date_ch`, `format_time_ch`, `quote_primary`, `quote_secondary`
- Annotationen: `build_source_line`, `build_caption`, `validate_alt_text`
- Themes: Matplotlib, Plotly, Altair
- UI-Templates: Footer (3 Varianten), Verantwortliche Stellen
- Lint-Funktionen: `lint_swiss_de_text`
- 60 Tests

---

[2.4.0]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/FaSiMaster/FaSi_VIZ/releases/tag/v2.1.0
