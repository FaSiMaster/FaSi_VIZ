# Glossar — FaSi ZH Viz

Begriffsklärungen für die Library und das zugrundeliegende Designsystem.

---

## Designsystem & Corporate Design

### CD Manual
Corporate Design Manual des Kantons Zürich, Version 2025. Definiert Print-Farben,
Typografie, Logos und Kommunikationsstandards für alle kantonalen Stellen.
Quelle: Staatskanzlei Kanton Zürich.

### statistikZH/leu
Offizielles GitHub-Repository der Fachstelle OpenData des Kantons Zürich mit
Figma-Design-Tokens (Farben, Typografie, Breakpoints, Shadows, Grid).
Einzige autoritative Quelle für **Web-Tokens**.
URL: https://github.com/statistikZH/leu

### Infografik-Palette
17 Farben, die in Visualisierungen für den Kanton Zürich verwendet werden dürfen.
Erfüllen WCAG-Kontrastverhältnis ≥ 3:1 gegen Weiss. In der Library unter
`tokens["colors"]["infographics_palette"]`.

### Akzentfarben
8 Hauptfarben des KZH-CD (Blau, Grün, Orange usw.). In `tokens["colors"]["accent"]`.

### Sequential Palette (`ktz_palette`)
54-stufige Sequenzpalette für Choropleth-Karten und Farb-Verläufe. Seit v2.6.0 in
`tokens["colors"]["sequential_palette"]`.

### Soft / Darkmode / Inverted
Alternative Farb-Sets für helle Akzenthintergründe (`soft`) und invertierte
Hintergründe (`darkmode` / `inverted`).

---

## Barrierefreiheit (Accessibility)

### WCAG 2.1
Web Content Accessibility Guidelines 2.1 (W3C). Technischer Standard für Web-
Barrierefreiheit. Relevante Kontrast-Schwellen:

| Regel | Schwelle |
|-------|----------|
| Text normal (AA) | ≥ 4.5:1 |
| Text gross (≥ 18 pt / 14 pt bold, AA) | ≥ 3.0:1 |
| Grafische Elemente / Icons | ≥ 3.0:1 |

### Kontrastverhältnis
Verhältnis der relativen Luminanzen zweier Farben (L1+0.05)/(L2+0.05). Wird in
`contrast.py` nach WCAG 2.1 berechnet.

### ARIA
Accessible Rich Internet Applications. Semantische HTML-Attribute
(`role`, `aria-label`, `aria-describedby`) für Screenreader.

### Alt-Text
Textalternative für Bilder/Grafiken. Im Library-Standard ≤ 150 Zeichen.

---

## Verkehrssicherheit (FaSi)

### FaSi
Fachstelle Verkehrssicherheit, Tiefbauamt, Baudirektion Kanton Zürich.
Verantwortlich für strategisches Verkehrssicherheits-Monitoring im Kanton.

### Unfallschwere
Klassifikation nach Schwere des Personenschadens gemäss ASTRA-Standard:
Sachschaden → Leichtverletzt → Schwerverletzt → Getötet → Unbekannt.
In `UNFALLSCHWERE_PALETTE`. Hinweis: SN 641 724 regelt das Hotspot-Management
(nicht die Schwere-Klassifikation) — siehe Abschnitt Normen.

### Unfalltyp
Kollisionsart gemäss ASTRA-Unfallaufnahmeprotokoll (UAP), Anhang 1 «Unfalltypen»
(Doku-Code `VU EB`). Haupt-Unfalltypengruppen 0–9:

| Nr | Gruppe | Sub-Codes |
|----|--------|-----------|
| 0 | Schleuder- oder Selbstunfall | 1–9 |
| 1 | Überholunfall, Fahrstreifenwechsel | 10–19 |
| 2 | Auffahrunfall | 20–29 |
| 3 | Abbiegeunfall | 30–39 |
| 4 | Einbiegeunfall | 40–49 |
| 5 | Überqueren der Fahrbahn | 50–59 |
| 6 | Frontalkollision | 60–69 |
| 7 | Parkierunfall | 70–79 |
| 8 | Fussgängerunfall | 80–89 |
| 9 | Tierunfall (Haustier / Wildtier / Reiter) | 90–99 |
| 00 | Andere | 0 |

In `UNFALLTYP_PALETTE`.

### ASTRA UAP
Bundesamt für Strassen — Unfallaufnahmeprotokoll. Seit 1.1.2018 als UAP2018
in Kraft (Vorgänger: UAP2011). Anhang 1 dokumentiert die Unfalltypen.
Fachapplikation in MISTRA (Managementinformationssystem Strasse und
Strassenverkehr).

### Ampel-Palette (Quartil-Ampel)
Quartil-basiertes Monitoring-Schema: Grün (unter Q25), Gelb (Q25–Q75),
Rot (über Q75), Grau (keine Daten). Nicht Teil des CD-Manuals, sondern
FaSi-Eigenstandard (SafetyCockpit).

### SafetyCockpit
R-Shiny-Anwendung der FaSi zur Auswertung netzweiter Verkehrssicherheits-
Kennzahlen. Seit v2.6.1 aus dem Repo ausgelagert nach `_archiv/`.

---

## Sprache & Kommunikation

### Schweizer Hochdeutsch
Standardsprache der deutschsprachigen Schweiz. Abweichungen vom Bundesdeutsch:
- `ss` statt `ß` (auch nach langen Vokalen: Strasse, gross, Fussgänger)
- Apostroph `'` als Tausendertrennzeichen (1'234)
- Guillemets «…» primär, ‹…› sekundär
- Schreibweisen gemäss Bundeskanzlei-Leitfaden

### Paarform
Empfohlene Form der geschlechtergerechten Sprache: *Mitarbeiterinnen und
Mitarbeiter*. Quelle: Bundeskanzlei, Leitfaden zur geschlechtergerechten
Sprache, 3. Auflage.

### Sparschreibung
Kurzform *Mitarbeiter/-innen*. **Nur in Formularen zulässig**, nicht in
Fliesstext.

### Neutrale Form
Geschlechtsneutrale Form, immer zulässig: *Mitarbeitende*, *Lernende*,
*Studierende*.

### Binnenmajuskel
Gross-I mitten im Wort: *MitarbeiterInnen*. Laut Bundeskanzlei **unzulässig**.

### Genderstern / Doppelpunkt / Unterstrich
`*innen`, `:innen`, `_innen`. Laut Bundeskanzlei **unzulässig** in offiziellen
Texten des Kantons Zürich.

### Stempelversion
3-zeilige Absender-Signatur: *Kanton Zürich / Direktion / Amt*. Quelle: CD
Manual S. 14-15.

### Bürostempel
Bis zu 5-zeilige Absender-Signatur: *Kanton Zürich / Direktion / Amt /
Abteilung / Team*. Quelle: CD Manual S. 14-15.

### E-Mail-Signatur
Offizielle Signatur gemäss CD Manual S. 23. Schrift Arial Regular/Black 10 pt.
Direktion und Name fett (Arial Black). In `impressum.py`.

---

## Typografie

### Inter / Helvetica Now
Primäre Web-Schriftfamilien des KZH-Designsystems. Fallback-Kaskade:
`InterRegular → HelveticaNowRegular → Helvetica → Arial → sans-serif`.

### Typo-Skala
18-stufige Grössenskala von `tiny` (12 px) bis `giant` (72 px). In
`tokens["typography"]["scale"]`. Jede Stufe hat `size_px`, `line_height`,
`letter_spacing_px` und `weight` (regular/black).

### Responsive Curves
Mapping einer Typo-Stufe auf verschiedene Breakpoints. Mobile-first
(min-width). In `tokens["typography"]["responsive_curves"]`.

### Breakpoints
Min-Width-Grenzen gemäss statistikZH/leu:
400 / 600 / 840 / 1024 / 1280 px.

---

## Normen & Quellen

### ASTRA
Bundesamt für Strassen. Herausgeber der Unfalltypenklassierung und der VSS-
Normen (via VSS, Verband Schweizer Strasseninfrastruktur-Fachleute).

### VSS
Schweizerischer Verband der Strassen- und Verkehrsfachleute. Herausgeber der
Schweizer Normen für das Strassen- und Verkehrswesen (≈ 1'300 Normen).

### SN 641 / SN 640
Schweizer Normen aus dem Bereich Verkehr und Strassen.

### SN 641 712
VSS-Norm «Strassenverkehrssicherheit — Sicherheitsaudit für Projekte von
Strassenverkehrsanlagen». Methodik für proaktive Verkehrssicherheitsprüfung
in der Planungsphase.

### SN 641 724
VSS-Norm «Strassenverkehrssicherheit — Unfallschwerpunkt-Management».
Grundlage für die systematische Analyse und Sanierung von Unfallschwerpunkten
auf Schweizer Strassen. Seit 2013 durch Artikel 6a SVG (Strassenverkehrsgesetz)
für alle Strasseneigentümer verbindlich.

### BK-Leitfaden
Bundeskanzlei: Leitfaden zur geschlechtergerechten Sprache, 3. Auflage.
Offizielle Vorgaben der Schweizerischen Bundeskanzlei.

### CH1903+ / LV95 / EPSG:2056
Schweizer Landeskoordinatensystem. Standard für alle Geodaten im Kanton
Zürich. Nicht direkt im Library-Scope, aber Kontext für nachgelagerte
Visualisierungen.

---

## Library-Technik

### Single Source of Truth
`src/fasi_zh_viz/data/tokens.json` — einzige autoritative Quelle für alle
Design-Tokens. Alle Python-Module laden Tokens über `load_tokens()`,
niemals hardcodierte Werte.

### Design-Token
Einzelner Wert (Farbe, Schriftgrösse, Breakpoint) mit stabilem Namen.
Ermöglicht konsistente Anwendung und zentrale Änderbarkeit.

### Validator
Funktion in `validators.py`, die eine Eingabe gegen eine Regel prüft und
`{ok: bool, issues: [...], ...}` zurückgibt. Beispiele:
`validate_palette_against_background`, `validate_text_contrast`.

### Linter
Funktion, die Text auf Schreib-/Form-Regelverletzungen prüft.
In `text_format.py` (`lint_swiss_de_text`) und `sprache.py`
(`lint_geschlechtergerecht`).

### Theme-Adapter
Modul, das `tokens.json` in ein Framework-spezifisches Theme umsetzt:
- `matplotlib_style.py` → matplotlib rcParams
- `plotly_theme.py` → Plotly Template
- `altair_theme.py` → Altair Theme
