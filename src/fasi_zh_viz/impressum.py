"""Impressum- und Signatur-Templates für strukturierte Absenderangaben.

Generischer Generator für E-Mail-Signaturen und Organisations-Stempel nach
einem mehrstufigen Hierarchie-Aufbau, wie ihn Schweizer Organisationen
verwenden.

Kontaktdaten werden aus data/kontakte.json geladen.
Zum Anpassen: kontakte.json editieren (kein Package-Rebuild nötig).

Hierarchie (relevant für Stempel/Signatur):

    Träger  →  Direktion  →  Amt  →  Abteilung  →  Team

Stempelversion (3 Zeilen):
    Träger / Direktion / Stempel-Einheit

    Die Stempel-Einheit muss nicht zwingend das formale Amt sein. Leere Felder
    (z.B. ein leerer `kanton`-Wert) werden in der Ausgabe weggelassen, sodass
    das Modul auch für private Absender ohne amtliche Hierarchie nutzbar ist.

Bürostempel (bis 5 Zeilen):
    Träger / Direktion / Amt / Abteilung / Team
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Optional, cast


def _load_kontakte() -> Dict[str, Any]:
    """Lädt Kontaktdaten aus data/kontakte.json."""
    data_dir = Path(__file__).parent / "data"
    kontakte_path = data_dir / "kontakte.json"
    with open(kontakte_path, encoding="utf-8") as f:
        return cast(Dict[str, Any], json.load(f))


@dataclass(frozen=True)
class KontaktPerson:
    """Kontaktangaben einer Person für die E-Mail-Signatur-Vorlage.

    Die Felder folgen einer mehrstufigen Organisations-Hierarchie:
    träger (kanton) → direktion → amt → abteilung → team. Leere Felder werden
    in der Ausgabe weggelassen (auch für private Absender nutzbar).
    """

    vorname: str
    nachname: str
    funktion: str
    direktion: str
    amt: str
    strasse: str
    plz_ort: str
    telefon: str
    email: str
    website: str
    kanton: str = ""
    abteilung: Optional[str] = None
    team: Optional[str] = None

    @property
    def vollname(self) -> str:
        return f"{self.vorname} {self.nachname}"


@dataclass(frozen=True)
class OrgEinheit:
    """Organisationseinheit für den Absendertext (Stempelversion / Bürostempel).

    - Stempelversion: bis zu 3 Zeilen (Träger + Direktion + Stempel-Einheit).
      Stempel-Einheit = `stempel_name` falls gesetzt, sonst `amt`.
    - Bürostempel: bis 5 Zeilen (Träger + Direktion + Amt + Abteilung + Team).

    Leere Felder werden in der Ausgabe weggelassen.
    """

    direktion: str
    amt: str
    kanton: str = "Kanton Zürich"
    abteilung: Optional[str] = None
    team: Optional[str] = None
    stempel_name: Optional[str] = None

    def as_stempelversion(self) -> list[str]:
        """Gibt die Stempelversion zurück (Träger / Direktion / Stempel-Einheit).

        Nutzt `stempel_name` wenn gesetzt, sonst `amt`. Leere Zeilen entfallen.
        """
        einheit = self.stempel_name or self.amt
        return [z for z in [self.kanton, self.direktion, einheit] if z]

    def as_burostempel(self) -> list[str]:
        """Gibt die bis zu 5-zeilige Bürostempel-Version zurück. Leere Zeilen entfallen."""
        zeilen = [self.kanton, self.direktion, self.amt]
        if self.abteilung:
            zeilen.append(self.abteilung)
        if self.team:
            zeilen.append(self.team)
        return [z for z in zeilen if z]


def build_email_signatur(
    person: KontaktPerson,
    grussformel: str = "Freundliche Grüsse",
    plain_text: bool = True,
) -> str:
    """Erzeugt eine strukturierte E-Mail-Signatur.

    Fett (HTML <strong>): Direktion und Name des Absenders. Leere
    Organisationsfelder werden weggelassen.

    Parameters
    ----------
    person:
        Kontaktangaben der Person.
    grussformel:
        Standard: 'Freundliche Grüsse'. Alternatives Beispiel: 'Mit freundlichen Grüssen'.
    plain_text:
        True: Gibt reinen Text zurück (für Plain-Text-E-Mail).
        False: Gibt HTML zurück mit <strong> für Fett-Elemente.
    """
    if plain_text:
        return _build_plain(person, grussformel)
    return _build_html(person, grussformel)


def _build_plain(person: KontaktPerson, grussformel: str) -> str:
    """Plain-Text-Signatur, hierarchisch: Träger → Direktion → Amt → Abteilung → Team.

    Leere Organisations- und Kontaktfelder werden weggelassen.
    """
    zeilen = [grussformel, person.vollname, ""]
    org_zeilen = [person.kanton, person.direktion, person.amt]
    if person.abteilung:
        org_zeilen.append(person.abteilung)
    if person.team:
        org_zeilen.append(person.team)
    zeilen += [z for z in org_zeilen if z]
    zeilen += ["", person.vollname]
    if person.funktion:
        zeilen.append(person.funktion)
    if person.strasse:
        zeilen.append(person.strasse)
    if person.plz_ort:
        zeilen.append(person.plz_ort)
    if person.telefon:
        zeilen.append(f"Telefon {person.telefon}")
    zeilen.append(person.email)
    if person.website:
        zeilen.append(person.website)
    return "\n".join(zeilen)


def _build_html(person: KontaktPerson, grussformel: str) -> str:
    """HTML-Signatur mit <strong> für fett darzustellende Elemente.

    Leere Organisations- und Kontaktfelder werden weggelassen.
    """
    org_parts = []
    if person.kanton:
        org_parts.append(person.kanton)
    if person.direktion:
        org_parts.append(f"<strong>{person.direktion}</strong>")
    if person.amt:
        org_parts.append(person.amt)
    if person.abteilung:
        org_parts.append(person.abteilung)
    if person.team:
        org_parts.append(person.team)
    org_zeilen_html = "<br>".join(org_parts)

    teil = [
        f"{grussformel}<br>",
        f"{person.vollname}<br>",
        "<br>",
    ]
    if org_zeilen_html:
        teil.append(f"{org_zeilen_html}<br>")
        teil.append("<br>")
    teil.append(f"<strong>{person.vollname}</strong><br>")
    if person.funktion:
        teil.append(f"{person.funktion}<br>")
    if person.strasse:
        teil.append(f"{person.strasse}<br>")
    if person.plz_ort:
        teil.append(f"{person.plz_ort}<br>")
    if person.telefon:
        teil.append(f"Telefon {person.telefon}<br>")
    teil.append(f'<a href="mailto:{person.email}">{person.email}</a>')
    if person.website:
        teil.append(f'<br><a href="https://{person.website}">{person.website}</a>')
    return "".join(teil)


# ---------------------------------------------------------------------------
# Vordefinierte Kontakte – aus kontakte.json geladen
# ---------------------------------------------------------------------------

def _build_fasi() -> KontaktPerson:
    """Baut FASI-Kontakt aus kontakte.json (korrektes hierarchisches Mapping)."""
    k = _load_kontakte()
    p = k["fasi"]
    org = k["fasi_org"]
    return KontaktPerson(
        vorname=p["vorname"],
        nachname=p["nachname"],
        funktion=p["titel"],
        kanton=org.get("kanton", ""),
        direktion=org["direktion"],
        amt=org["amt"],
        abteilung=org.get("abteilung"),
        team=None,
        strasse=org["adresse"],
        plz_ort=org["plz_ort"],
        telefon=p["telefon"],
        email=p["email"],
        website=p["website"],
    )


def _build_fasi_org() -> OrgEinheit:
    """Baut FASI_ORG aus kontakte.json.

    Stempel-Einheit = `stempel_einheit` aus kontakte.json,
    Amt = formales Amt für Bürostempel und E-Mail-Signatur. Leere Felder
    entfallen in der Ausgabe.
    """
    k = _load_kontakte()
    org = k["fasi_org"]
    return OrgEinheit(
        kanton=org.get("kanton", ""),
        direktion=org["direktion"],
        amt=org["amt"],
        abteilung=org.get("abteilung"),
        team=None,
        stempel_name=org.get("stempel_einheit"),
    )


FASI: KontaktPerson = _build_fasi()
FASI_ORG: OrgEinheit = _build_fasi_org()
