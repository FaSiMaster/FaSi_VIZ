# GitHub Repository erstellen - Schritt für Schritt

## Voraussetzungen

- GitHub Account (kostenlos: https://github.com/signup)
- Git installiert (https://git-scm.com/downloads)
- Dieses ZIP entpackt

---

## SCHRITT 1: GitHub Account erstellen (falls noch nicht vorhanden)

1. Gehe zu https://github.com/signup
2. E-Mail, Passwort, Benutzername eingeben
3. E-Mail verifizieren

---

## SCHRITT 2: Neues Repository auf GitHub erstellen

1. Einloggen auf https://github.com
2. Klicke oben rechts auf **"+"** → **"New repository"**
3. Ausfüllen:
   - **Repository name:** `fasi-zh-viz`
   - **Description:** `Visualisierungs-Library gemäss Kanton Zürich Designsystem`
   - **Public** auswählen (für öffentlich)
   - **NICHT** "Add a README file" ankreuzen
   - **NICHT** "Add .gitignore" ankreuzen
   - **NICHT** "Choose a license" auswählen
4. Klicke **"Create repository"**

---

## SCHRITT 3: Lokales Repository einrichten

Öffne ein Terminal/Kommandozeile und führe aus:

```bash
# 1. In den entpackten Ordner wechseln
cd fasi-zh-viz

# 2. Git initialisieren
git init

# 3. Alle Dateien hinzufügen
git add .

# 4. Ersten Commit erstellen
git commit -m "Initial commit: FaSi ZH Viz Library v2.0.0"

# 5. Main Branch benennen
git branch -M main

# 6. GitHub als Remote hinzufügen (DEIN USERNAME hier einfügen!)
git remote add origin https://github.com/DEIN-USERNAME/fasi-zh-viz.git

# 7. Hochladen
git push -u origin main
```

---

## SCHRITT 4: Verifizieren

1. Gehe zu `https://github.com/DEIN-USERNAME/fasi-zh-viz`
2. Du solltest alle Dateien sehen
3. README wird automatisch angezeigt

---

## SCHRITT 5: Release erstellen (optional)

1. Auf GitHub: Klicke auf **"Releases"** (rechte Seite)
2. Klicke **"Create a new release"**
3. **Tag:** `v2.0.0`
4. **Title:** `v2.0.0 - Initial Release`
5. **Description:** Changelog einfügen
6. Klicke **"Publish release"**

---

## SCHRITT 6: PyPI veröffentlichen (optional, später)

Wenn du auf PyPI veröffentlichen willst (damit `pip install fasi-zh-viz` funktioniert):

1. Account auf https://pypi.org erstellen
2. API Token erstellen (Account Settings → API tokens)
3. In GitHub: Settings → Secrets → Actions → New secret
   - Name: `PYPI_API_TOKEN`
   - Value: Dein PyPI Token
4. Tag erstellen: `git tag v2.0.0 && git push --tags`
5. GitHub Action läuft automatisch und publiziert auf PyPI

---

## Fertig!

Deine Library ist jetzt verfügbar unter:

```
https://github.com/DEIN-USERNAME/fasi-zh-viz
```

Andere können sie installieren mit:

```bash
pip install git+https://github.com/DEIN-USERNAME/fasi-zh-viz.git
```

---

## Häufige Probleme

### "Permission denied"
```bash
# SSH-Key einrichten oder HTTPS mit Token verwenden
git remote set-url origin https://TOKEN@github.com/DEIN-USERNAME/fasi-zh-viz.git
```

### "Repository not found"
- Prüfe ob Repository-Name korrekt ist
- Prüfe ob du eingeloggt bist

### Tests schlagen fehl
```bash
# Lokal testen vor Push
pip install -e ".[dev]"
pytest tests/ -v
```

---

## Nächste Schritte

1. [ ] Repository erstellen
2. [ ] Code hochladen
3. [ ] README prüfen (wird auf GitHub angezeigt)
4. [ ] Erste Release erstellen
5. [ ] Team-Mitglieder einladen (Settings → Collaborators)
6. [ ] Optional: PyPI veröffentlichen

Bei Fragen: GitHub Dokumentation https://docs.github.com
