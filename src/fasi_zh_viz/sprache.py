"""Geschlechtergerechte Sprache gemäss Bundeskanzlei-Leitfaden.

Quelle: Bundeskanzlei, Leitfaden zur geschlechtergerechten Sprache, 3. Auflage.
https://www.bk.admin.ch/dam/bk/de/dokumente/sprachdienste/leitfaden-geschlechtergerechte-sprache.pdf

Regeln:
- Empfohlen: Paarform («Mitarbeiterinnen und Mitarbeiter»)
- Erlaubt für Formulare: Sparschreibung («Mitarbeiter/-innen»)
- VERBOTEN: Genderstern (*innen), Doppelpunkt (:innen), Unterstrich (_innen)
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Optional


@dataclass(frozen=True)
class SprachIssue:
    level: str  # "error" | "warn"
    message: str
    found: Optional[str] = None


# Verbotene Formen gemäss Bundeskanzlei
_VERBOTENE_FORMEN: List[str] = [
    "*innen",
    ":innen",
    "_innen",
    "Innen",  # Binnenmajuskel: MitarbeiterInnen
]

# Häufige Paarformen (erweiterbar)
_PAARFORMEN: Dict[str, str] = {
    "Mitarbeiter": "Mitarbeiterinnen und Mitarbeiter",
    "Mitarbeitende": "Mitarbeitende",
    "Leiter": "Leiterinnen und Leiter",
    "Direktor": "Direktorinnen und Direktoren",
    "Sachbearbeiter": "Sachbearbeiterinnen und Sachbearbeiter",
    "Benutzer": "Benutzerinnen und Benutzer",
    "Nutzer": "Nutzerinnen und Nutzer",
    "Bürger": "Bürgerinnen und Bürger",
    "Einwohner": "Einwohnerinnen und Einwohner",
    "Antragsteller": "Antragstellerinnen und Antragsteller",
    "Auftragnehmer": "Auftragnehmerinnen und Auftragnehmer",
    "Auftraggeber": "Auftraggeberinnen und Auftraggeber",
    "Verkehrsteilnehmer": "Verkehrsteilnehmerinnen und Verkehrsteilnehmer",
    "Fussgänger": "Fussgängerinnen und Fussgänger",
    "Velofahrer": "Velofahrerinnen und Velofahrer",
    "Autofahrer": "Autofahrerinnen und Autofahrer",
}


def paarform(wort: str) -> str:
    """Gibt die empfohlene Paarform zurück.

    Beispiel: paarform("Mitarbeiter") → "Mitarbeiterinnen und Mitarbeiter"
    Falls kein Eintrag vorhanden, wird eine generische Form gebildet.
    """
    return _PAARFORMEN.get(wort, f"{wort}innen und {wort}")


def sparschreibung(wort: str) -> str:
    """Gibt die Sparschreibung zurück (NUR für Formulare zulässig).

    Beispiel: sparschreibung("Mitarbeiter") → "Mitarbeiter/-innen"
    """
    return f"{wort}/-innen"


def neutrale_form(wort: str) -> Optional[str]:
    """Gibt eine neutrale Form zurück, falls bekannt.

    Neutrale Formen sind immer zulässig.
    Beispiel: "Mitarbeitende", "Lehrpersonen"
    """
    neutrale: Dict[str, str] = {
        "Mitarbeiter": "Mitarbeitende",
        "Lehrer": "Lehrpersonen",
        "Schüler": "Lernende",
        "Student": "Studierende",
        "Bewerber": "Bewerbende",
    }
    return neutrale.get(wort)


def lint_geschlechtergerecht(text: str) -> Dict:
    """Prüft Text auf verbotene Formen der Geschlechterdarstellung.

    Verboten gemäss Bundeskanzlei:
    - Genderstern: *innen
    - Doppelpunkt: :innen
    - Unterstrich: _innen
    - Binnenmajuskel: MitarbeiterInnen (Grosses I mitten im Wort)
    """
    issues: List[SprachIssue] = []

    for verboten in _VERBOTENE_FORMEN:
        if verboten in text:
            issues.append(SprachIssue(
                level="error",
                message=(
                    f"Verbotene Form «{verboten}» gefunden. "
                    "Bundeskanzlei erlaubt: Paarform oder neutrale Formulierungen. "
                    "Genderstern, Doppelpunkt und Unterstrich sind nicht zulässig."
                ),
                found=verboten,
            ))

    # Prüfe auf Binnenmajuskel (z.B. MitarbeiterInnen)
    import re
    binnenmajuskel = re.findall(r'[a-züäö][A-ZÜÄÖ][a-züäö]', text)
    if binnenmajuskel:
        issues.append(SprachIssue(
            level="warn",
            message=(
                "Mögliche Binnenmajuskel gefunden (z.B. MitarbeiterInnen). "
                "Diese Form ist nicht zulässig gemäss Bundeskanzlei."
            ),
            found=str(binnenmajuskel),
        ))

    return {
        "ok": not any(i.level == "error" for i in issues),
        "issues": [{"level": i.level, "message": i.message, "found": i.found} for i in issues],
    }
