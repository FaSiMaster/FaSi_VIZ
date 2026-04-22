"""Impressum- und Signatur-Templates für die kantonale Kommunikation.

Basiert auf dem Corporate Design Manual Kanton Zürich, Version 2025.
E-Mail-Signatur: S. 23 des CD Manual.
Schrift E-Mail: Arial Regular/Black, 10 pt.

Kontaktdaten werden aus data/kontakte.json geladen.
Zum Anpassen: kontakte.json editieren (kein Package-Rebuild nötig).

Hierarchie im Kanton Zürich (relevant für Stempel/Signatur):

    Kanton Zürich  →  Direktion  →  Amt  →  Abteilung  →  Team

Beispiel:
    Kanton Zürich  →  Baudirektion  →  Tiefbauamt  →  FaSi  →  —

Stempelversion (3 Zeilen, CD Manual S.14-15):
    Kanton Zürich / Direktion / Stempel-Einheit

    Die Stempel-Einheit muss nicht zwingend das formale Amt sein. Bei der FaSi
    wird z.B. "Fachstelle Verkehrssicherheit FaSi" im Stempel geführt, weil das
    die sprechende Einheit in der externen Kommunikation ist. Das formale Amt
    (Tiefbauamt) erscheint dennoch in Bürostempel und E-Mail-Signatur.

Bürostempel (bis 5 Zeilen, CD Manual S.14-15):
    Kanton Zürich / Direktion / Amt / Abteilung / Team
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
    """Kontaktangaben einer Person gemäss CD Manual E-Mail-Signatur-Vorlage.

    Die Felder entsprechen der offiziellen Kanton-Zürich-Hierarchie:
    direktion → amt → abteilung → team.
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
    abteilung: Optional[str] = None
    team: Optional[str] = None

    @property
    def vollname(self) -> str:
        return f"{self.vorname} {self.nachname}"


@dataclass(frozen=True)
class OrgEinheit:
    """Organisationseinheit für den Absendertext (Stempelversion / Bürostempel).

    - Stempelversion: genau 3 Zeilen (Kanton Zürich + Direktion + Stempel-Einheit).
      Stempel-Einheit = `stempel_name` falls gesetzt, sonst `amt`.
    - Bürostempel: bis 5 Zeilen (Kanton + Direktion + Amt + Abteilung + Team).

    Quelle: CD Manual Kanton Zürich, S. 14-15.
    """

    direktion: str
    amt: str
    abteilung: Optional[str] = None
    team: Optional[str] = None
    stempel_name: Optional[str] = None

    def as_stempelversion(self) -> list[str]:
        """Gibt die 3-zeilige Stempelversion zurück.

        Nutzt `stempel_name` wenn gesetzt (z.B. "Fachstelle FaSi"), sonst `amt`.
        Siehe CD Manual S.14-15.
        """
        einheit = self.stempel_name or self.amt
        return ["Kanton Zürich", self.direktion, einheit]

    def as_burostempel(self) -> list[str]:
        """Gibt die bis zu 5-zeilige Bürostempel-Version zurück (hierarchisch korrekt)."""
        zeilen = ["Kanton Zürich", self.direktion, self.amt]
        if self.abteilung:
            zeilen.append(self.abteilung)
        if self.team:
            zeilen.append(self.team)
        return zeilen


def build_email_signatur(
    person: KontaktPerson,
    grussformel: str = "Freundliche Grüsse",
    plain_text: bool = True,
) -> str:
    """Erzeugt eine E-Mail-Signatur gemäss CD Manual Kanton Zürich, S. 23.

    Schrift: Arial Regular 10 pt.
    Fett (Arial Black): Direktion und Name des Absenders.

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
    """Plain-Text-Signatur, hierarchisch: Kanton → Direktion → Amt → Abteilung → Team."""
    zeilen = [
        grussformel,
        person.vollname,
        "",
        "Kanton Zürich",
        person.direktion,
        person.amt,
    ]
    if person.abteilung:
        zeilen.append(person.abteilung)
    if person.team:
        zeilen.append(person.team)
    zeilen += [
        "",
        person.vollname,
        person.funktion,
        person.strasse,
        person.plz_ort,
        f"Telefon {person.telefon}",
        person.email,
        person.website,
    ]
    return "\n".join(zeilen)


def _build_html(person: KontaktPerson, grussformel: str) -> str:
    """HTML-Signatur mit <strong> für fett darzustellende Elemente (Arial Black)."""
    org_zeilen_html = (
        f"Kanton Zürich<br>"
        f"<strong>{person.direktion}</strong><br>"
        f"{person.amt}"
    )
    if person.abteilung:
        org_zeilen_html += f"<br>{person.abteilung}"
    if person.team:
        org_zeilen_html += f"<br>{person.team}"

    return (
        f"{grussformel}<br>"
        f"{person.vollname}<br>"
        f"<br>"
        f"{org_zeilen_html}<br>"
        f"<br>"
        f"<strong>{person.vollname}</strong><br>"
        f"{person.funktion}<br>"
        f"{person.strasse}<br>"
        f"{person.plz_ort}<br>"
        f"Telefon {person.telefon}<br>"
        f'<a href="mailto:{person.email}">{person.email}</a><br>'
        f'<a href="https://{person.website}">{person.website}</a>'
    )


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

    Stempel-Einheit = `stempel_einheit` aus kontakte.json (z.B. "FaSi"),
    Amt = formales Amt (z.B. "Tiefbauamt") für Bürostempel und E-Mail-Signatur.
    """
    k = _load_kontakte()
    org = k["fasi_org"]
    return OrgEinheit(
        direktion=org["direktion"],
        amt=org["amt"],
        abteilung=org.get("abteilung"),
        team=None,
        stempel_name=org.get("stempel_einheit"),
    )


FASI: KontaktPerson = _build_fasi()
FASI_ORG: OrgEinheit = _build_fasi_org()
