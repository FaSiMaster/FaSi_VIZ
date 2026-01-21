"""Schreib-/Formatierungs-Utilities für Diagrammtexte (CH-Deutsch Standard).

Die Regeln sind so implementiert, dass sie direkt mit den Tokens (tokens.json -> text_rules)
konfigurierbar bleiben.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, time
from typing import Any, Dict, Optional, Union


Number = Union[int, float]


@dataclass(frozen=True)
class TextLintIssue:
    level: str  # "warn" | "error"
    message: str
    data: Optional[Dict[str, Any]] = None


def quote_primary(text: str, open_q: str = "«", close_q: str = "»") -> str:
    return f"{open_q}{text}{close_q}"


def quote_secondary(text: str, open_q: str = "‹", close_q: str = "›") -> str:
    return f"{open_q}{text}{close_q}"


def format_int_ch(value: int, thousands_sep: str = "'") -> str:
    """Formatiert ganze Zahlen mit Apostroph als Tausendertrennzeichen."""
    return format(value, ",").replace(",", thousands_sep)


def format_float_ch(
    value: float,
    decimals: int = 1,
    thousands_sep: str = "'",
    decimal_sep: str = ",",
) -> str:
    """Formatiert Dezimalzahlen (Standard: 1 Nachkommastelle)."""
    s = f"{value:,.{decimals}f}"  # 12,345.6 (US locale formatting)
    s = s.replace(",", "{TS}").replace(".", "{DS}")
    return s.format(TS=thousands_sep, DS=decimal_sep)


def format_percent_ch(
    value: float,
    decimals: int = 0,
    value_is_fraction: bool = False,
    thousands_sep: str = "'",
    decimal_sep: str = ",",
    with_space: bool = True,
) -> str:
    """Formatiert Prozentwerte.

    - value_is_fraction=False: 12.5 -> "12,5 %"
    - value_is_fraction=True: 0.125 -> "12,5 %"
    """
    v = value * 100.0 if value_is_fraction else value
    num = format_float_ch(v, decimals=decimals, thousands_sep=thousands_sep, decimal_sep=decimal_sep)
    return f"{num}{' ' if with_space else ''}%"


def format_date_ch(d: Union[date, datetime], sep: str = ".") -> str:
    """Formatiert Datum als TT.MM.JJJJ."""
    if isinstance(d, datetime):
        d = d.date()
    return f"{d.day:02d}{sep}{d.month:02d}{sep}{d.year:04d}"


def format_time_ch(t: Union[time, datetime], with_uhr: bool = False) -> str:
    """Formatiert Uhrzeit als H.MM (optional mit 'Uhr')."""
    if isinstance(t, datetime):
        t = t.time()
    s = f"{t.hour}.{t.minute:02d}"
    return f"{s} Uhr" if with_uhr else s


def lint_swiss_de_text(
    text: str,
    warn_on_eszett: bool = True,
    primary_quotes: tuple[str, str] = ("«", "»"),
    secondary_quotes: tuple[str, str] = ("‹", "›"),
) -> Dict[str, Any]:
    """Prüft einfache, für Diagrammtexte relevante Schreibregeln.

    Fokus: robust, ohne NLP/Heuristik-Overkill.
    """
    issues: list[TextLintIssue] = []

    if warn_on_eszett and "ß" in text:
        issues.append(TextLintIssue(
            level="warn",
            message="Text enthält ß. Für Schweizer Hochdeutsch in Diagrammtexten wird in der Regel ss verwendet.",
            data={"found": "ß"},
        ))

    # Deutsche Anführungszeichen (typografische Varianten)
    if any(q in text for q in ["„", "“", "‚", "‘", "”"]):
        issues.append(TextLintIssue(
            level="warn",
            message=(
                "Text enthält deutsche typografische Anführungszeichen. "
                f"Empfohlen sind Guillemets {primary_quotes[0]} {primary_quotes[1]} (bzw. {secondary_quotes[0]} {secondary_quotes[1]})."
            ),
            data={"recommended_primary": primary_quotes, "recommended_secondary": secondary_quotes},
        ))

    return {"ok": not any(i.level == "error" for i in issues), "issues": [i.__dict__ for i in issues]}
