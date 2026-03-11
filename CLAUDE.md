# CLAUDE.md – Kontext für Claude Code

Diese Datei gibt Claude Code wichtigen Projekt-Kontext für alle Sitzungen.

## Projekt

**FaSi ZH Viz** — Python-Library für Visualisierungen gemäss Kanton Zürich Designsystem.
Entwickelt von der Fachstelle Verkehrssicherheit (FaSi), Baudirektion Kanton Zürich.

- GitHub: https://github.com/FaSiMaster/FaSi_VIZ
- Aktuelle Version: siehe `pyproject.toml` und `src/fasi_zh_viz/__init__.py`
- Tests: `pytest tests/ -v` (Ziel: alle Tests grün)

## Eigentümer

**Stevan Skeledžić** — Leiter Verkehrssicherheit / SiBe ZH
Tiefbauamt, Baudirektion, Kanton Zürich
stevan.skeledzic@bd.zh.ch | +41 43 259 31 20

## Architektur

```
src/fasi_zh_viz/
├── data/tokens.json        ← Single Source of Truth für alle Design-Tokens
├── contrast.py             ← WCAG Kontrastberechnung
├── validators.py           ← Alle Validatoren
├── tokens.py               ← Token-Loader
├── text_format.py          ← Schweizer Textformatierung
├── annotations.py          ← Quellenzeilen, Alt-Texte, Bildunterschriften
├── impressum.py            ← E-Mail-Signatur, Org-Stempel (CD Manual S.23)
├── sprache.py              ← Geschlechtergerechte Sprache (BK-Leitfaden)
├── fasi_themes.py          ← FaSi-eigene Farbthemen (Verkehrssicherheit)
├── matplotlib_style.py     ← Matplotlib rcParams
├── plotly_theme.py         ← Plotly Template
├── altair_theme.py         ← Altair Theme
└── ui/
    ├── footer.py           ← HTML-Footer (3 Varianten)
    └── responsible.py      ← HTML-Chips für verantwortliche Stellen
```

## Wichtige Regeln

### Farben
- **Webfarben** (screen): aus `statistikZH/leu` Figma-Tokens und CD Manual RGB-Werte
- **Druckfarben** (CMYK): in `tokens["cd_manual_colors"]` — getrennt von Webfarben!
- `colors.accent.blau` = `#0076BD` (NICHT `#0070B4` — das ist der falsche alte Wert)
- Infografik-Farben brauchen ≥ 3:1 Kontrast auf Weiss
- Füllfarben in Charts (z.B. Gelb `#FFCC00`) müssen KEIN 3:1 erfüllen — Bedeutung via Label

### Sprache
- Schweizer Hochdeutsch: `ss` (nie `ß`), Apostrophe als Tausendertrennzeichen
- Anführungszeichen: `«»` primär, `‹›` sekundär
- Paarform (`Mitarbeiterinnen und Mitarbeiter`) bevorzugt
- Genderstern/Doppelpunkt VERBOTEN (Bundeskanzlei-Leitfaden)

### Versionierung
- Version IMMER synchron halten: `pyproject.toml` ↔ `src/fasi_zh_viz/__init__.py`
- Git Tags für jede Version erstellen: `git tag v2.x.0 && git push origin v2.x.0`
- CHANGELOG.md bei jeder neuen Version aktualisieren

### Tests
- `pytest tests/ -v` vor jedem Commit
- Test-Datei: `tests/test_fasi_zh_viz.py`
- Ziel: alle Tests grün, keine Warnings

### Sicherheit
- HTML-Komponenten: immer `html.escape()` für Benutzereingaben
- URLs in HTML: nur `https://`, `http://`, `/`, `#` erlaubt
- Keine Netzwerkanfragen im Package-Code

## Wichtige Quellen (autoritativ)

| Quelle | Inhalt |
|--------|--------|
| `statistikZH/leu` auf GitHub | Offizielle Figma-Tokens (Farben, Typografie, Breakpoints) |
| CD Manual 2025 (lokal: `C:\ClaudeAI\KTZH_Standard_Desgin\Corporate Design Manual.pdf`) | Print-CD, E-Mail-Signatur, Office-Typografie |
| BK-Leitfaden geschlechtergerechte Sprache, 3. Aufl. | Sprachregeln |
| WCAG 2.1 (W3C) | Kontrastschwellen 3:1 / 4.5:1 |
| ASTRA Unfalltypenklassierung | Grundlage für `fasi_themes.py` |

## Häufige Fehler vermeiden

- Nicht `#0070B4` für Blau verwenden (alt/falsch) — korrekt: `#0076BD`
- Keine `_note`-Keys innerhalb von `infographics_palette` (bricht Kontrast-Tests)
- Version in beiden Dateien erhöhen, nicht nur einer
- `git tag` nach dem Push nicht vergessen
