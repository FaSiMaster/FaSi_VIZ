"""Hilfsfunktionen für Quellen-/Kontextzeilen und Alt-Text.

Die ZH-Designsystem-Seite zu Infografiken betont die Kontextualisierung beim grafischen Element.
Barrierefreiheit verlangt zudem aussagekräftige Alternativtexte.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Optional


@dataclass(frozen=True)
class AnnotationIssue:
    level: str  # "warn" | "error"
    message: str
    data: Optional[Dict[str, Any]] = None


def build_source_line(
    source: str,
    updated: Optional[str] = None,
    prefix: str = "Quelle:",
) -> str:
    """Erzeugt eine standardisierte Quellenzeile.

    Parameters
    ----------
    source:
        Quellenangabe (z.B. Dataset/URL/Publikation).
    updated:
        Optionales Aktualisierungsdatum als Text (z.B. "21.01.2026").
    """
    s = f"{prefix} {source}".strip()
    if updated:
        s = f"{s} (Stand {updated})"
    return s


def build_caption(
    title: Optional[str] = None,
    source_line: Optional[str] = None,
    note: Optional[str] = None,
) -> str:
    """Baut eine Caption/Unterzeile, die direkt unter eine Grafik gesetzt werden kann."""
    parts = [p for p in [title, source_line, note] if p]
    return " – ".join(parts)


def validate_alt_text(alt_text: str, max_chars: int = 150) -> Dict[str, Any]:
    """Validiert Alt-Text-Länge (praktische Qualitäts-Gate).

    Der konkrete Grenzwert ist als Default auf 150 Zeichen gesetzt.
    """
    issues: list[AnnotationIssue] = []

    if not alt_text or not alt_text.strip():
        issues.append(AnnotationIssue(level="error", message="Alt-Text fehlt oder ist leer."))
        return {"ok": False, "issues": [i.__dict__ for i in issues]}

    length = len(alt_text)
    if length > max_chars:
        issues.append(AnnotationIssue(
            level="warn",
            message=f"Alt-Text ist länger als {max_chars} Zeichen ({length}). Kürzen empfohlen.",
            data={"length": length, "max_chars": max_chars},
        ))

    return {
        "ok": not any(i.level == "error" for i in issues),
        "issues": [i.__dict__ for i in issues],
        "length": length,
    }
