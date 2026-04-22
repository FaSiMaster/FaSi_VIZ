"""HTML-Komponente für «Verantwortliche Stellen» (KZH-Designsystem).

Escapet alle Benutzereingaben (Labels und URLs) gegen XSS.
URLs sind auf `https://`, `http://`, relative Pfade und `#` beschränkt —
`javascript:` und andere Schemas werfen `ValueError`.
"""

from __future__ import annotations

import html
from typing import List, Tuple

_ALLOWED_URL_PREFIXES = ("https://", "http://", "/", "#")


def _safe_url(url: str) -> str:
    """Erlaubt nur https://, http:// und relative URLs. Blockiert javascript: etc."""
    stripped = url.strip()
    if any(stripped.startswith(p) for p in _ALLOWED_URL_PREFIXES):
        return html.escape(stripped, quote=True)
    raise ValueError(
        f"Ungültiges URL-Schema (nur https/http/relativ erlaubt): {stripped!r}"
    )


def verantwortliche_stellen_html(entries: List[Tuple[str, str]]) -> str:
    """Erzeugt eine HTML-Sektion mit Chip-Links zu verantwortlichen Stellen."""
    title = "Für dieses Thema zuständig:"
    chips = "\n".join([
        f"<a class='fasi-chip' href='{_safe_url(url)}' "
        f"aria-label='{html.escape(label)}'>{html.escape(label)}</a>"
        for label, url in entries
    ])
    return f"""<section class="fasi-responsible-stellen" aria-label="{title}">
  <h2>{title}</h2>
  <div class="fasi-chip-group">
    {chips}
  </div>
</section>"""
