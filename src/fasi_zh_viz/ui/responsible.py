import html
from typing import List, Tuple


def _safe_url(url: str) -> str:
    """Erlaubt nur https://, http:// und relative URLs. Blockiert javascript: etc."""
    stripped = url.strip()
    allowed = ("https://", "http://", "/", "#")
    if any(stripped.startswith(p) for p in allowed):
        return html.escape(stripped, quote=True)
    raise ValueError(f"Ungültiges URL-Schema (nur https/http/relativ erlaubt): {stripped!r}")


def verantwortliche_stellen_html(entries: List[Tuple[str, str]]) -> str:
    title = "Für dieses Thema zuständig:"
    chips = "\n".join([
        f"<a class='fasi-chip' role='listitem' href='{_safe_url(url)}' aria-label='{html.escape(label)}'>{html.escape(label)}</a>"
        for label, url in entries
    ])
    return f"""<section class="fasi-responsible-stellen" aria-label="{title}">
  <h2>{title}</h2>
  <div class="fasi-chip-group" role="list">
    {chips}
  </div>
</section>"""
