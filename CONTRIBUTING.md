# Beitragen zu FaSi ZH Viz

Vielen Dank für dein Interesse, zu diesem Projekt beizutragen!

## Entwicklungsumgebung einrichten

```bash
# Repository klonen
git clone https://github.com/FaSiMaster/FaSi_VIZ.git
cd FaSi_VIZ

# Virtual Environment erstellen
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# oder: .venv\Scripts\activate  # Windows

# Entwicklungsabhängigkeiten installieren
pip install -e ".[dev]"
```

## Code-Qualität

Vor jedem Commit:

```bash
# Linting
ruff check src/

# Type Checking
mypy src/fasi_zh_viz/

# Tests
pytest tests/ -v
```

## Pull Request erstellen

1. Fork das Repository
2. Erstelle einen Feature-Branch: `git checkout -b feature/mein-feature`
3. Committe deine Änderungen: `git commit -m "Beschreibung"`
4. Push zum Branch: `git push origin feature/mein-feature`
5. Öffne einen Pull Request

## Commit-Messages

Bitte verwende aussagekräftige Commit-Messages auf Deutsch oder Englisch:

```
feat: Neue Funktion für X hinzugefügt
fix: Kontrast-Berechnung korrigiert
docs: README aktualisiert
test: Tests für Validatoren ergänzt
```

## Designsystem-Änderungen

Wenn sich das [ZH-Designsystem](https://www.zh.ch/de/webangebote-entwickeln-und-gestalten.html) ändert:

1. `tokens.json` aktualisieren
2. Quellen-URLs in `meta.sources` prüfen
3. Version in `pyproject.toml` und `__init__.py` erhöhen
4. Tests anpassen falls nötig

## Fragen?

Bei Fragen wende dich an: fasi@bd.zh.ch
