# Changelog

Alle wichtigen Änderungen werden in dieser Datei dokumentiert.
Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).
Versionierung nach [Semantic Versioning](https://semver.org/lang/de/).

---

## [2.6.3] – 2026-04-23

### Behoben (normative Korrekturen, gegen Original-Quellen verifiziert)

- **`fasi_themes.py` UAP-Unfalltypen-Zuordnung komplett korrigiert**.
  Die bisherige Typ-Nummerierung (Typ 1 = Auffahren, Typ 2 = Abbiegen, Typ 3 = Überholen,
  Typ 5 = Fussgänger, Typ 6 = Tierunfall, Typ 7 = Selbstunfall) war inkorrekt.
  Korrekte ASTRA-UAP-Haupt-Unfalltypengruppen 0–9 laut UAP Anhang 1 (Doku-Code VU EB):

  | Alt (falsch) | Neu (korrekt) | Label |
  |--------------|---------------|-------|
  | Typ 1 | **Typ 2** | Auffahrunfall |
  | Typ 2 | **Typ 3** | Abbiegeunfall |
  | Typ 3 | **Typ 1** | Überholunfall |
  | Typ 5 | **Typ 8** | Fussgängerunfall |
  | Typ 6 | **Typ 9** | Tierunfall |
  | Typ 7 | **Typ 0** | Selbstunfall |

- **Palette erweitert** um offiziell existierende Typen: `einbiegeunfall` (UAP-Typ 4),
  `frontalkollision` (UAP-Typ 6).
- **Breaking (Mikro):** `wildunfall` → `tierunfall` umbenannt (offizielle ASTRA-Bezeichnung
  umfasst Haustier/Wildtier/Reiter). Migration: `UNFALLTYP_PALETTE["tierunfall"]` statt `["wildunfall"]`.
- **«Formular 13.004»** (existierte nicht) durch korrekten Quellenverweis ersetzt:
  ASTRA MISTRA-VU, UAP Anhang 1 «Unfalltypen», Doku-Code VU EB, Version 4.21 (6.12.2010),
  ab 1.1.2018 als UAP2018 in Kraft.
- **SN 641 724**: Glossar- und Code-Kommentar korrigiert. Offizieller Titel ist
  «Strassenverkehrssicherheit, Unfallschwerpunkt-Management» (regelt Hotspot-Analyse,
  seit 2013 via Art. 6a SVG verbindlich) — NICHT «Klassifikation von Verkehrsunfällen
  und Personenschaden» wie fälschlich im Glossar v2.6.2.
- **VSS**: Akronym-Auflösung korrigiert auf «Schweizerischer Verband der Strassen- und
  Verkehrsfachleute» (nicht «Verband Schweizer Strasseninfrastruktur-Fachleute»).
- **SECURITY.md `§ 3 IDG`** → **`§ 14 IDG`** korrigiert. § 3 IDG regelt den Vorbehalt
  des Verfahrensrechts, nicht die Informationspflicht. § 14 IDG ist die korrekte
  Grundlage für die Publikation dienstlicher Kontakt-Angaben öffentlicher Organe.

### Hinzugefügt

- `docs/GLOSSAR.md`: Eintrag `SN 641 712` (Sicherheitsaudit) und aktualisierter
  `SN 641 724`-Eintrag mit Verweis auf Art. 6a SVG.
- `docs/GLOSSAR.md` `ASTRA UAP`: Historie UAP2011 → UAP2018, MISTRA-Fachapplikation.
- 2 neue Tests: `test_unfalltyp_palette_vollstaendig`,
  `test_unfalltyp_palette_kein_wildunfall_mehr`.

### Quellen (verifiziert am 2026-04-23)

- ASTRA UAP Anhang 1 (PDF, 19 S.): [Instruktionen_Unfallaufnahmeprotokoll_UAP2018_Anhang1_Unfalltypen.pdf](https://www.astra.admin.ch/dam/astra/de/dokumente/unfalldaten/publikationen/Instruktionen_Unfallaufnahmeprotokoll_UAP2018_Anhang1_Unfalltypen.pdf.download.pdf/Instruktionen_Unfallaufnahmeprotokoll_UAP2018_Anhang1_Unfalltypen.pdf)
- ASTRA Unfallerfassung: https://www.astra.admin.ch/astra/de/home/dokumentation/daten-informationsprodukte/unfalldaten/grundlagen/unfallerfassung.html
- SN 641 724 / Art. 6a SVG: Webrecherche VSS / ASTRA-Normenliste
- IDG Kanton Zürich: https://www.zh.ch/de/politik-staat/gesetze-beschluesse/gesetzessammlung/zhlex-ls/erlass-170_4-2007_02_12-2008_10_01-109.html

---

## [2.6.2] – 2026-04-22

### Sicherheit
- `footer_html(kind="webapp_login", version=...)`: Double-Escape-Problem behoben.
  Version wird jetzt einheitlich über `html.escape()` im submenu-Loop escapet —
  vorher war ungeklärt, wo der Escape stattfindet. XSS via dynamischem Version-String ausgeschlossen.
- `SECURITY.md` um DSGVO-/IDG-Hinweis zu `kontakte.json` und CI-Publish-Gating ergänzt.

### Hinzugefügt
- `docs/` Ordner mit `GLOSSAR.md` (≈ 40 Begriffe), `STRUKTUR.md` (Projektorganisation) und Landing-`README.md`
- `.pre-commit-config.yaml`: Ruff + Mypy + Bandit + pytest + File-Hygiene für alle Contributor
- `OrgEinheit.stempel_name` optionales Feld: erlaubt abweichende Stempel-Einheit vom formalen Amt
  (für FaSi = «Fachstelle Verkehrssicherheit FaSi», während das formale Amt «Tiefbauamt» bleibt)
- `kontakte.json` `stempel_einheit`-Key
- 14 neue Tests: Theme-Smoke-Tests (matplotlib/plotly/altair), Footer-Varianten inkl. XSS,
  Kontrast-Test über alle FaSi-Themes, Impressum-Hierarchie, `load_css`-Regression

### Geändert
- `impressum.py`: hierarchisches Mapping korrigiert (amt=Tiefbauamt, abteilung=FaSi).
  E-Mail-Signatur und Bürostempel zeigen jetzt die korrekte Kanton-Zürich-Hierarchie
  Kanton → Direktion → Amt → Abteilung. Stempelversion nutzt `stempel_name` und bleibt
  bei «Kanton Zürich / Baudirektion / FaSi».
- `tokens.json` `meta.version` synchron mit Package (2.6.2), `generated_utc` aktualisiert
- `test_tokens_version` dynamisch gegen `__version__` (kein Hardcode, kein Drift mehr möglich)
- `CHANGELOG.md`: ASCII-Ersatzschreibungen durch echte Umlaute ersetzt (Geändert, Hinzugefügt …)
- `README.md`: Test-Badge `84` → `90` passed, `pip install -e`-Pfad korrigiert, Link auf `docs/`
- `CONTRIBUTING.md`: Branch-Konvention an gelebten Workflow angepasst (Maintainer auf main erlaubt,
  Contributor via Feature-Branch + PR). Commit-Message-Format und Release-Prozess dokumentiert.
- `ci.yml`: `publish`-Job prüft `PYPI_API_TOKEN`-Presence und skipt ohne Fehler wenn nicht gesetzt
  (verhindert CI-Failures bei fehlendem Secret). `dev`-Branch in `push`-Trigger aufgenommen.
- Ruff: 36 E501-Verletzungen + 8 I001 Import-Sort-Issues behoben
- Mypy: 2 `no-any-return` Errors (`tokens.py`, `impressum.py`) via `cast(dict, json.load(...))`
- `ui/footer.py` + `ui/responsible.py`: redundante ARIA-Rollen entfernt
  (`role="list"` auf `<ul>`, `role="listitem"` auf `<li>`/`<a>` — implizit via HTML-Semantik)

### Coverage
- 90 → 104 Tests, 85 % → ~92 % Coverage

---

## [2.6.1] – 2026-04-12

### Geändert
- Repo-Struktur aufräumen: redundante Dateien entfernt, SafetyCockpit archiviert
- `GITHUB_ANLEITUNG.md` entfernt (Einmal-Setup, längst erledigt)
- `requirements-dev.txt` entfernt (redundant zu pyproject.toml)
- `requirements-min.txt` entfernt (redundant zu pyproject.toml)
- `DEPLOY.md` entfernt (gehört nicht ins Repo)
- `SafetyCockpit/` in `_archiv/` verschoben (eigenständige R-Shiny-App, gehört in eigenes Repo)
- `_archiv/` in `.gitignore` aufgenommen
- `SECURITY.md`: unterstützte Version auf 2.6.x aktualisiert

---

## [2.6.0] – 2026-03-28

### Hinzugefügt
- Farb-Audit SafetyCockpit: alle R-Shiny Module auf KTZH-Farbstandard migriert
- `AMPEL_PALETTE` in `fasi_themes.py`
- `UNFALLSCHWERE_PALETTE` auf 5 Stufen erweitert (Sachschaden + Unbestimmt)
- `ktz_palette` (54-Farben Sequenzpalette) in `tokens.json` als `sequential_palette`
- `get_ampel_color()` Hilfsfunktion
- SafetyCockpit Farbstandard-Dokumentation (`FaSi_VIZ_Farbstandard.md`)
- Farb-Audit-Bericht als PDF

### Geändert
- `tokens.json` meta.version auf 2.5.0 aktualisiert

---

## [2.5.0] – 2026-03-15

### Sicherheit
- `settings.local.json` aus Git-Tracking entfernt (`.gitignore` erweitert)
- Persönliche Kontaktdaten in externe `kontakte.json` ausgelagert (kein Package-Rebuild bei Personalwechsel)

### Hinzugefügt
- ARIA-Attribute in `footer.py` und `responsible.py` (KZH-Barrierefreiheitsvorgaben)
- `examples/einfuehrung.ipynb`: Einführungs-Notebook mit 4 Beispielzellen
- Konkrete ASTRA-Quellenbelege in `fasi_themes.py` (UTF Formular 13.004)

### Tests
- `TestARIAKomponenten`: 3 neue ARIA-Tests

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

[2.6.1]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.6.0...v2.6.1
[2.6.0]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/FaSiMaster/FaSi_VIZ/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/FaSiMaster/FaSi_VIZ/releases/tag/v2.1.0
