# Mitwirken — FaSi ZH Viz

## Branch-Konvention

### Hauptbranches
- **`main`** — stabiler Code, releast. Jeder Tag `vX.Y.Z` zeigt auf einen Commit hier.
- **`dev`** — optional für grössere, noch nicht fertige Arbeiten. Wird vor Release in `main` gemerget.

### Feature- und Fix-Branches
- `feature/<kurz-beschreibung>` — neue Features
- `fix/<kurz-beschreibung>` — Bugfixes

### Workflow
- **Maintainer** (Stevan) kann direkt auf `main` committen bei kleinen Korrekturen,
  Dokumentations-Änderungen und Patch-Releases.
- **Grössere Umbauten** (breaking changes, mehrere verknüpfte Commits) gehen über
  `dev` oder einen Feature-Branch und werden per PR in `main` gemerget.
- **Externe Contributor** arbeiten ausschliesslich auf Feature-/Fix-Branches
  und öffnen PRs gegen `main`.

## Commit-Message-Konvention

Format: `<type>(<scope>): <kurze Beschreibung>`

Typen:
- `init` — initiale Projekteinrichtung
- `feat` — neues Feature
- `fix` — Bugfix
- `refactor` — Code-Umbau ohne Verhaltensänderung
- `test` — Tests hinzugefügt / geändert
- `docs` — nur Dokumentation
- `chore` — Build, Config, Cleanup
- `security` — Sicherheitsrelevanter Fix

Beispiele:
- `feat(themes): AMPEL_PALETTE für Quartil-Monitoring`
- `fix(impressum): hierarchisches Mapping korrigiert`
- `docs: GLOSSAR.md mit Begriffen ergänzt`
- `chore: v2.6.2 Release`

## Vor jedem Commit

```bash
# Tests
pytest tests/ -v

# Linting + Typecheck
ruff check src/
mypy src/fasi_zh_viz/ --ignore-missing-imports

# Sicherheit
bandit -r src/fasi_zh_viz/ -ll
```

Oder alles in einem Zug via pre-commit-Hook (siehe `.pre-commit-config.yaml`):

```bash
pip install pre-commit
pre-commit install
```

## Release-Prozess

1. `__version__` in `src/fasi_zh_viz/__init__.py` anheben
2. `pyproject.toml` `version` anheben (muss mit `__init__.py` übereinstimmen)
3. `src/fasi_zh_viz/data/tokens.json` `meta.version` anheben
4. `CHANGELOG.md` mit neuer Version + Datum aktualisieren
5. Commit: `chore: vX.Y.Z Release`
6. Tag: `git tag vX.Y.Z && git push origin vX.Y.Z`
7. Falls PyPI-Publishing aktiv ist, triggert der Tag-Push den `publish`-Job.

## Fragen / Probleme

Issues öffnen: https://github.com/FaSiMaster/FaSi_VIZ/issues
Sicherheitslücken: siehe [SECURITY.md](SECURITY.md).
