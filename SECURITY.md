# Security Policy

## Unterstützte Versionen

Sicherheits-Updates werden nur für die jeweils aktuellste Version bereitgestellt.

| Version | Unterstützt |
|---------|-------------|
| 2.4.x   | ✅ ja       |
| < 2.4   | ❌ nein     |

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
| 2.4.0   | XSS in `responsible.py`: `javascript:`-URLs nicht blockiert, Labels nicht escaped | — |

## Hinweise zur sicheren Nutzung

- `verantwortliche_stellen_html()` akzeptiert seit v2.4.0 nur noch `https://`,
  `http://`, relative Pfade und `#`. Andere Schemas lösen `ValueError` aus.
- HTML-generierenden Funktionen vertrauen keinen Benutzereingaben — validiere
  immer vor der Übergabe.
- Das Package macht keine Netzwerkanfragen und speichert keine Daten.
