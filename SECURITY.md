# Security Policy

## Unterstützte Versionen

Sicherheits-Updates werden nur für die jeweils aktuellste Version bereitgestellt.

| Version | Unterstützt |
|---------|-------------|
| 2.6.x   | ja          |
| < 2.6   | nein        |

## Sicherheitslücke melden

Bitte melde Sicherheitslücken **nicht** als öffentliches GitHub Issue.

Sende stattdessen eine E-Mail an: **stevan.skeledzic@bd.zh.ch**

Bitte inkludiere:
- Beschreibung der Schwachstelle
- Schritte zur Reproduktion
- Mögliche Auswirkungen
- Falls vorhanden: Vorschlag für eine Behebung

Wir bestätigen den Eingang innerhalb von 5 Arbeitstagen und informieren über den
weiteren Verlauf.

## Bekannte behobene Schwachstellen

| Version | Beschreibung | CVE |
|---------|-------------|-----|
| 2.6.2   | Double-Escape / Rohwert-Vertrauen: `footer_html(kind="webapp_login", version=...)` escapete den Version-String inkonsistent. Jetzt einheitlich über `html.escape()` im submenu-Loop. | — |
| 2.4.0   | XSS in `responsible.py`: `javascript:`-URLs nicht blockiert, Labels nicht escaped | — |

## Hinweise zur sicheren Nutzung

### HTML-Komponenten
- `verantwortliche_stellen_html()` akzeptiert seit v2.4.0 nur noch `https://`,
  `http://`, relative Pfade und `#`. Andere Schemas lösen `ValueError` aus.
- `footer_html()` escapet alle dynamischen Werte (inkl. `version`) via `html.escape`.
- HTML-generierenden Funktionen vertrauen keinen Benutzereingaben — validiere
  immer vor der Übergabe.

### Netzwerk
- Das Package macht **keine Netzwerkanfragen** und speichert keine Daten.

### Datenschutz — `kontakte.json`

Die Datei `src/fasi_zh_viz/data/kontakte.json` enthält **dienstliche** Kontaktdaten
der Fachstelle Verkehrssicherheit (Name, dienstliche E-Mail, dienstliche
Telefonnummer, Anschrift). Diese Angaben sind — als Teil der allgemeinen
Informationspflicht öffentlicher Organe nach **§ 14 IDG** des Kantons Zürich
(Informations- und Datenschutzgesetz) — **öffentlich zugänglich** und dürfen
im Repository geführt werden. § 14 Abs. 1 IDG verpflichtet öffentliche Organe
zur Bereitstellung von Informationen über Struktur, Zuständigkeiten und
Ansprechmöglichkeiten.

Für Fork/Anpassung durch Dritte:
- `kontakte.example.json` als Template verwenden
- `kontakte.json` lokal mit eigenen **dienstlichen** Daten füllen
- **Keine privaten Kontaktdaten** (private Mobilnummer, Privatadresse) im Repo ablegen
- Falls gewünscht: `kontakte.json` in einer Fork-.gitignore führen und nur
  `kontakte.example.json` tracken

### CI / Publishing

- Der `publish`-Job in `.github/workflows/ci.yml` ist nur aktiv, wenn
  `PYPI_API_TOKEN` als Repository-Secret gesetzt ist. Ohne Token wird der Job
  ohne Fehler übersprungen (keine versehentliche Publikation).

### Bandit-Scan

Bandit läuft im CI-Pipeline-Job `security` bei jedem Push/PR. Aktueller Stand:
0 Issues auf ~930 LOC.

Lokal:

```bash
bandit -r src/fasi_zh_viz/ -ll
```
