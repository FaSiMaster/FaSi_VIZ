# Projektstruktur — roadsafety-viz

Aktueller Stand: v2.6.1

```
roadsafety-viz/
├── .github/
│   └── workflows/
│       └── ci.yml                    ← CI: test + lint + mypy + bandit + publish
├── .claude/
│   └── settings.json                 ← Claude Code Config (lokal)
├── .editorconfig                     ← UTF-8, LF, 4-Spaces Python
├── .gitignore                        ← Caches, Artefakte, _archiv/, Secrets
├── CHANGELOG.md                      ← Versionshistorie (Keep a Changelog)
├── CLAUDE.md                         ← Projekt-Kontext für Claude Code
├── CONTRIBUTING.md                   ← Branch-Konvention + Commit-Regeln
├── LICENSE                           ← MIT
├── README.md                         ← Schnellstart + Feature-Übersicht
├── SECURITY.md                       ← Security-Policy + CVE-Historie
├── pyproject.toml                    ← Build, Dependencies, Tools (ruff/mypy/pytest)
│
├── src/
│   └── fasi_zh_viz/                  ← Package
│       ├── __init__.py               ← 59 öffentliche Exports
│       ├── data/
│       │   ├── tokens.json           ← Single Source of Truth (Design-Tokens)
│       │   ├── kontakte.json         ← Projekt-Kontaktangaben (im Repo)
│       │   ├── kontakte.example.json ← Template für externe Nutzung
│       │   ├── inter.css             ← Inter Webfont-Declaration
│       │   └── ui.css                ← KZH-UI-Basis-CSS
│       ├── ui/
│       │   ├── footer.py             ← HTML-Footer (3 Varianten)
│       │   └── responsible.py        ← HTML-Chips für verantwortliche Stellen
│       ├── tokens.py                 ← Token-Loader (importlib.resources)
│       ├── contrast.py               ← WCAG-Kontrastberechnung
│       ├── validators.py             ← Palette/Text/Font/Kategorien
│       ├── text_format.py            ← Schweizer Textformatierung
│       ├── annotations.py            ← Quellenzeile, Caption, Alt-Text
│       ├── impressum.py              ← E-Mail-Signatur, Stempelversion
│       ├── sprache.py                ← Geschlechtergerechte Sprache (BK-Leitfaden)
│       ├── fasi_themes.py            ← Themen-Farbpaletten (Verkehrssicherheit)
│       ├── matplotlib_style.py       ← Matplotlib rcParams
│       ├── plotly_theme.py           ← Plotly Template
│       └── altair_theme.py           ← Altair Theme
│
├── tests/
│   ├── __init__.py
│   └── test_fasi_zh_viz.py           ← 90 Tests, 85 % Coverage
│
├── examples/
│   ├── einfuehrung.ipynb             ← Jupyter-Tutorial (4 Zellen)
│   ├── python_plotly_example.py      ← Plotly-Beispiel
│   └── fasi_design_showcase.html     ← HTML-Showcase aller Komponenten
│
├── docs/
│   ├── README.md                     ← Doku-Landing-Page
│   ├── GLOSSAR.md                    ← Begriffe und Fachausdrücke
│   └── STRUKTUR.md                   ← Diese Datei
│
└── _archiv/                          ← Gitignored, nicht im Remote
    └── SafetyCockpit/                ← R-Shiny-App (eigenständig, v2.6.1 ausgelagert)
```

---

## Verantwortlichkeiten pro Modul

| Modul | Zweck | Abhängigkeiten |
|-------|-------|---------------|
| `tokens.py` | Lädt `data/tokens.json` via `importlib.resources` | — |
| `contrast.py` | WCAG 2.1 relative Luminanz + Kontrastverhältnis | stdlib (re) |
| `validators.py` | Palette-/Text-/Font-/Kategorien-Validierung | `contrast` |
| `text_format.py` | `format_int_ch`, `format_float_ch`, `format_date_ch` usw. | stdlib (datetime) |
| `annotations.py` | Quellenzeile, Caption, Alt-Text-Validator | — |
| `impressum.py` | `KontaktPerson`, `OrgEinheit`, E-Mail-Signatur | `data/kontakte.json` |
| `sprache.py` | `paarform`, `neutrale_form`, `lint_geschlechtergerecht` | stdlib (re) |
| `fasi_themes.py` | `UNFALLSCHWERE_PALETTE`, `AMPEL_PALETTE` u.a. | — |
| `matplotlib_style.py` | `apply_matplotlib_style(tokens)` | matplotlib (optional) |
| `plotly_theme.py` | `apply_plotly_defaults(tokens)` | plotly (optional) |
| `altair_theme.py` | `enable_altair_theme(tokens)` | altair (optional) |
| `ui/footer.py` | HTML-Footer (`website` / `service_no_login` / `webapp_login`) | — |
| `ui/responsible.py` | HTML-Chips mit XSS-sicheren Labels/URLs | stdlib (html) |

---

## Datenflüsse

```
┌─────────────────────┐
│   tokens.json       │  ← statistikZH/leu + CD Manual
│  (Single Source)    │
└──────────┬──────────┘
           │ load_tokens()
           ▼
┌─────────────────────────────────────────────┐
│  Python-Module                              │
│                                             │
│  ┌──────────┐   ┌────────────┐   ┌────────┐ │
│  │ validators│───│  contrast  │   │ themes │ │
│  └──────────┘   └────────────┘   └───┬────┘ │
│                                      │      │
│  ┌──────────────────────────────────▼────┐ │
│  │   matplotlib / plotly / altair        │ │
│  │   Theme-Adapter                       │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
           │
           ▼
     User-Visualisierungen
  (Matplotlib-Figure, Plotly-Fig, Altair-Chart)
```

---

## Externe Quellen

| Quelle | Rolle | Update-Strategie |
|--------|-------|------------------|
| `statistikZH/leu` (GitHub) | Web-Tokens (Farben, Typo, Breakpoints) | Manuell synchronisiert in `tokens.json` |
| CD Manual 2025 (PDF) | Print-Tokens, Signatur-Regeln | Manuell, bei neuer Ausgabe |
| ASTRA UAP Anhang 1 (Doku-Code VU EB) | Unfalltypen-Klassifikation | Selten (Jahre, zuletzt UAP2018) |
| BK-Leitfaden 3. Auflage | Sprachregeln | Selten (Jahre) |
| WCAG 2.1 (W3C) | Kontrast-Schwellen | Stabil |

---

## Testabdeckung (Stand v2.6.1)

| Modul | Coverage | Anmerkung |
|-------|----------|-----------|
| `__init__.py` | 100 % | Alle Exports geladen |
| `annotations.py` | 100 % | — |
| `contrast.py` | 100 % | — |
| `fasi_themes.py` | 100 % | 8 dedizierte Tests |
| `impressum.py` | 96 % | Bürostempel mit team ungetestet |
| `sprache.py` | 96 % | Neutrale-Form-Fallback ungetestet |
| `text_format.py` | 95 % | Uhr-Suffix-Edge-Case |
| `validators.py` | 98 % | `prefer_outside=False` ungetestet |
| `tokens.py` | 75 % | `load_css` ungetestet |
| `ui/responsible.py` | 100 % | XSS-Tests vorhanden |
| `ui/footer.py` | 57 % | `webapp_login` + `service_no_login` partial |
| `matplotlib_style.py` | 27 % | Kein matplotlib in Test-Env |
| `plotly_theme.py` | 25 % | Kein plotly in Test-Env |
| `altair_theme.py` | 20 % | Kein altair in Test-Env |
| **Gesamt** | **85 %** | 90 Tests, <1 s |

---

## Wo landen neue Dateien?

| Art der Datei | Zielordner |
|---------------|-----------|
| Neues Python-Modul | `src/fasi_zh_viz/` |
| UI-Komponente | `src/fasi_zh_viz/ui/` |
| Statische Ressource (CSS, JSON, Font) | `src/fasi_zh_viz/data/` |
| Test | `tests/test_*.py` |
| Beispiel / Showcase | `examples/` |
| Dokumentation | `docs/` |
| Alte / auszulagernde Fremdprojekte | `_archiv/` (gitignored) |
| Claude-Code-Regeln | `CLAUDE.md` (Root) |
