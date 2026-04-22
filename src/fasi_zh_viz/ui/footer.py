"""HTML-Footer-Templates für KZH-Webangebote.

Drei Varianten gemäss KZH-Designsystem:
- `website`: vollständiger Footer mit Menü, Social Media und Submenü
- `service_no_login`: Service-Seite ohne Login, nur Submenü
- `webapp_login`: WebApp mit Login, minimaler Footer
"""

from __future__ import annotations

import html
from typing import Optional

_VALID_KINDS = {"website", "service_no_login", "webapp_login"}


def footer_html(
    kind: str,
    include_impressum: bool = False,
    include_version: bool = False,
    version: Optional[str] = None,
) -> str:
    """Erzeugt HTML-Footer in einer der drei KZH-Varianten.

    Alle dynamischen Werte (v.a. `version`) werden per `html.escape` gegen XSS gesichert.
    """
    if kind not in _VALID_KINDS:
        raise ValueError(
            f"kind muss eine von {sorted(_VALID_KINDS)} sein, erhalten: {kind!r}"
        )

    sender = "Kanton Zürich"

    if kind == "webapp_login":
        submenu = ["Copyright"]
        if include_impressum:
            submenu.append("Impressum")
        submenu.append("Nutzungshinweis")
        if include_version:
            # submenu_html escapet unten jedes Item – hier nur Rohwert einsetzen,
            # sonst entsteht Double-Escape (&amp;lt; statt &lt;).
            version_suffix = f": {version}" if version else ""
            submenu.append(f"Versionsnummer{version_suffix}")
        menu_links = False
        social = False
    elif kind == "service_no_login":
        submenu = ["Copyright", "Designsystem", "Erklärung zur Barrierefreiheit"]
        if include_impressum:
            submenu.append("Impressum")
        submenu.append("Nutzungshinweise")
        menu_links = False
        social = False
    else:  # website
        submenu = ["Copyright", "Designsystem", "Erklärung zur Barrierefreiheit"]
        if include_impressum:
            submenu.append("Impressum")
        submenu.append("Nutzungshinweise")
        menu_links = True
        social = True

    submenu_html = "\n".join([
        f'    <li><a href="#" aria-label="Externer Link: {html.escape(item)}">'
        f'{html.escape(item)}</a></li>'
        for item in submenu
    ])

    links_menu_html = ""
    if menu_links:
        links_menu_html = (
            "<nav class='fasi-footer-menu' aria-label='Footer-Navigation'>"
            "<ul>"
            "<li><a href='#'>Kontakt</a></li>"
            "<li><a href='#'>News</a></li>"
            "<li><a href='#'>Medien</a></li>"
            "</ul>"
            "</nav>"
        )

    social_html = ""
    if social:
        social_html = (
            "<div class='fasi-footer-social' aria-label='Social Media'>"
            "<a href='#' rel='noopener' aria-label='Externer Link: LinkedIn'>LinkedIn</a>"
            "<a href='#' rel='noopener' aria-label='Externer Link: YouTube'>YouTube</a>"
            "</div>"
        )

    return f"""<footer class="fasi-footer" role="contentinfo">
  <h2>{sender}</h2>
  {links_menu_html}
  <nav class="fasi-footer-submenu" aria-label="Footer-Submenü">
    <ul>
{submenu_html}
    </ul>
  </nav>
  {social_html}
</footer>"""
