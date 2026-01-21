from typing import Optional

def footer_html(kind: str, include_impressum: bool = False, include_version: bool = False,
                version: Optional[str] = None) -> str:
    sender = "Kanton Zürich"
    if kind not in {"website", "service_no_login", "webapp_login"}:
        raise ValueError("kind muss 'website', 'service_no_login' oder 'webapp_login' sein")

    if kind == "webapp_login":
        submenu = ["Copyright"]
        if include_impressum:
            submenu.append("Impressum")
        submenu.append("Nutzungshinweis")
        if include_version:
            submenu.append("Versionsnummer" + (f": {version}" if version else ""))
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

    submenu_html = "\n".join([f'    <li><a href="#">{item}</a></li>' for item in submenu])

    links_menu_html = ""
    if menu_links:
        links_menu_html = "<nav class='fasi-footer-menu' aria-label='Footer-Menü'><ul><li><a href='#'>Kontakt</a></li><li><a href='#'>News</a></li><li><a href='#'>Medien</a></li></ul></nav>"

    social_html = ""
    if social:
        social_html = "<div class='fasi-footer-social' aria-label='Social Media'><a href='#' rel='noopener'>LinkedIn</a><a href='#' rel='noopener'>YouTube</a></div>"

    return f"""<footer class="fasi-footer">
  <h2>{sender}</h2>
  {links_menu_html}
  <nav class="fasi-footer-submenu" aria-label="Footer-Submenü">
    <ul>
{submenu_html}
    </ul>
  </nav>
  {social_html}
</footer>"""
