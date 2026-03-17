"""
Farb-Audit-Bericht SafetyCockpit → FaSi_VIZ
Generiert einen detaillierten PDF-Bericht.
Aufruf: python generate_farbbericht.py
"""

from fpdf import FPDF
from fpdf.enums import XPos, YPos
import datetime

# ── Hilfsfunktionen ────────────────────────────────────────────────────────

def hex_to_rgb(h):
    h = h.strip("#")
    if len(h) == 3:
        h = "".join(c*2 for c in h)
    return int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)

def luminance(h):
    r,g,b = hex_to_rgb(h)
    def f(v):
        v /= 255
        return v/12.92 if v <= 0.04045 else ((v+0.055)/1.055)**2.4
    return 0.2126*f(r) + 0.7152*f(g) + 0.0722*f(b)

def contrast(h1, h2="#FFFFFF"):
    L1, L2 = luminance(h1), luminance(h2)
    brighter, darker = max(L1,L2), min(L1,L2)
    return round((brighter + 0.05) / (darker + 0.05), 1)

def text_color_for_bg(hex_bg):
    """Weiss oder Schwarz je nach Hintergrund."""
    return "#FFFFFF" if luminance(hex_bg) < 0.35 else "#000000"


# ── PDF-Klasse ─────────────────────────────────────────────────────────────

class Bericht(FPDF):

    ZH_BLAU   = (0, 118, 189)
    ZH_DUNKEL = (0, 64, 124)
    GRAU_HELL = (247, 247, 247)
    GRAU_MED  = (224, 224, 224)
    GRAU_TEXT = (80, 80, 80)
    SCHWARZ   = (30, 30, 30)
    WEISS     = (255, 255, 255)
    ROT       = (183, 28, 35)
    GRUEN     = (26, 127, 31)
    ORANGE    = (232, 118, 0)
    GELB_SOFT = (255, 245, 204)
    ROT_SOFT  = (255, 213, 204)
    GRUEN_SOFT= (235, 246, 235)

    def header(self):
        self.set_fill_color(*self.ZH_BLAU)
        self.rect(0, 0, 210, 14, "F")
        self.set_font("Arial", "B", 9)
        self.set_text_color(*self.WEISS)
        self.set_xy(10, 4)
        self.cell(0, 6,
            "FaSi ZH Viz – Farb-Audit-Bericht SafetyCockpit · Fachstelle Verkehrssicherheit · Baudirektion Kanton Zürich",
            new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*self.SCHWARZ)
        self.ln(4)

    def footer(self):
        self.set_y(-12)
        self.set_font("Arial", "", 8)
        self.set_text_color(*self.GRAU_TEXT)
        self.set_draw_color(*self.GRAU_MED)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(1)
        self.cell(0, 5,
            f"Seite {self.page_no()} | Erstellt {datetime.date.today().strftime('%d.%m.%Y')} | "
            "FaSi ZH Viz v2.6.0 | Vertraulich – nicht zur Publikation",
            align="C")

    # ── Stilhilfsmittel ────────────────────────────────────────────────────

    def kapitel_titel(self, nr, titel):
        self.set_fill_color(*self.ZH_BLAU)
        self.set_text_color(*self.WEISS)
        self.set_font("Arial", "B", 13)
        self.set_x(10)
        self.cell(0, 9, f"  {nr}  {titel}", fill=True,
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*self.SCHWARZ)
        self.ln(3)

    def abschnitt_titel(self, titel, neu=False):
        self.set_font("Arial", "B", 10)
        self.set_text_color(*self.ZH_DUNKEL)
        self.set_x(10)
        prefix = "> " + titel
        if neu:
            prefix += "  * NEU / OFFEN"
        self.cell(0, 7, prefix, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_draw_color(*self.ZH_BLAU)
        self.line(10, self.get_y(), 200, self.get_y())
        self.set_text_color(*self.SCHWARZ)
        self.ln(2)

    def body(self, txt, indent=10):
        self.set_font("Arial", "", 9)
        self.set_text_color(*self.GRAU_TEXT)
        self.set_x(indent)
        self.multi_cell(0, 5, txt, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

    def hinweis(self, txt, farbe="blau"):
        farben = {
            "blau":  ((232, 242, 250), (0, 64, 124)),
            "rot":   ((253, 236, 234), (183, 28, 35)),
            "gruen": ((235, 246, 235), (26, 127, 31)),
            "gelb":  ((255, 248, 220), (120, 96, 0)),
        }
        bg, fg = farben.get(farbe, farben["blau"])
        self.set_fill_color(*bg)
        self.set_draw_color(*fg)
        self.set_font("Arial", "", 9)
        self.set_text_color(*fg)
        self.set_x(10)
        self.multi_cell(190, 5, "  " + txt, border=1, fill=True,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(*self.SCHWARZ)
        self.ln(2)

    # ── Tabellen ───────────────────────────────────────────────────────────

    def tabellen_kopf(self, spalten, breiten):
        self.set_fill_color(*self.ZH_DUNKEL)
        self.set_text_color(*self.WEISS)
        self.set_font("Arial", "B", 8)
        self.set_x(10)
        for s, b in zip(spalten, breiten):
            self.cell(b, 6, " " + s, fill=True, border=1)
        self.ln()
        self.set_text_color(*self.SCHWARZ)

    def tabellen_zeile(self, werte, breiten, fill=False, farbe=None,
                       status=None):
        STATUS_BG = {
            "KONFORM":     (220, 240, 220),
            "PRÜFEN":      (255, 248, 200),
            "ABWEICHUNG":  (255, 225, 220),
            "FaSi-intern": (235, 235, 255),
            "OFFEN":       (255, 238, 210),
            "ERLEDIGT":    (220, 240, 220),
            "NEU":         (220, 240, 255),
            "—":           (245, 245, 245),
        }
        if status and status in STATUS_BG:
            r, g, b = STATUS_BG[status]
            self.set_fill_color(r, g, b)
            fill = True
        elif fill:
            self.set_fill_color(*self.GRAU_HELL)

        self.set_font("Arial", "", 8)
        self.set_x(10)
        for i, (v, b) in enumerate(zip(werte, breiten)):
            self.cell(b, 5, " " + str(v), fill=fill, border=1)
        self.ln()

    def farb_swatch(self, hex_val, name, x, y, w=18, h=8):
        r, g, b = hex_to_rgb(hex_val)
        self.set_fill_color(r, g, b)
        self.set_draw_color(*self.GRAU_MED)
        self.rect(x, y, w, h, "FD")
        tc = text_color_for_bg(hex_val)
        tr, tg, tb = hex_to_rgb(tc)
        self.set_text_color(tr, tg, tb)
        self.set_font("Arial", "", 6)
        self.set_xy(x, y + h/2 - 2)
        self.cell(w, 4, hex_val, align="C")
        self.set_text_color(*self.SCHWARZ)
        self.set_font("Arial", "", 7)
        self.set_xy(x, y + h + 1)
        self.cell(w, 3, name[:12], align="C")


# ═══════════════════════════════════════════════════════════════════════════
# HAUPTPROGRAMM
# ═══════════════════════════════════════════════════════════════════════════

pdf = Bericht()
pdf.add_font("Arial",  "",  "C:/Windows/Fonts/arial.ttf")
pdf.add_font("Arial",  "B", "C:/Windows/Fonts/arialbd.ttf")
pdf.add_font("Arial",  "I", "C:/Windows/Fonts/ariali.ttf")
pdf.set_margins(10, 18, 10)
pdf.set_auto_page_break(True, margin=15)
pdf.set_font("Arial", "", 10)

# ══════════════════════════════════════════════════════
# DECKBLATT
# ══════════════════════════════════════════════════════
pdf.add_page()
pdf.set_fill_color(*Bericht.ZH_BLAU)
pdf.rect(0, 0, 210, 297, "F")

pdf.set_font("Arial", "B", 28)
pdf.set_text_color(*Bericht.WEISS)
pdf.set_xy(20, 60)
pdf.multi_cell(170, 12, "Farb-Audit-Bericht\nSafetyCockpit → FaSi_VIZ",
               align="L")

pdf.set_font("Arial", "", 13)
pdf.set_xy(20, 110)
pdf.multi_cell(170, 7,
    "Vollständige Farbanalyse, Abgleich mit kantonalem\n"
    "Corporate Design und Figma-Tokens sowie Empfehlungen\n"
    "für Korrekturen in SafetyCockpit und FaSi_VIZ.",
    align="L")

pdf.set_fill_color(255, 255, 255)
pdf.set_font("Arial", "B", 10)
pdf.set_xy(20, 180)
infos = [
    ("Dokument",    "Farb-Audit SafetyCockpit v0.0.0.9002"),
    ("FaSi_VIZ",    "v2.6.0 (nach Audit aktualisiert)"),
    ("Erstellt",    datetime.date.today().strftime("%d.%m.%Y")),
    ("Autor",       "Claude Code · Fachstelle Verkehrssicherheit"),
    ("Status",      "Vertraulich – nicht zur Publikation"),
]
for k, v in infos:
    pdf.set_font("Arial", "B", 9)
    pdf.set_xy(20, pdf.get_y())
    pdf.cell(45, 6, k + ":", new_x=XPos.RIGHT, new_y=YPos.LAST)
    pdf.set_font("Arial", "", 9)
    pdf.cell(120, 6, v, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

pdf.set_fill_color(255, 204, 0)
pdf.rect(20, 248, 170, 1, "F")
pdf.set_font("Arial", "", 9)
pdf.set_xy(20, 252)
pdf.cell(0, 5,
    "Kanton Zürich · Baudirektion · Tiefbauamt · FaSi",
    align="L")
pdf.set_text_color(*Bericht.SCHWARZ)

# ══════════════════════════════════════════════════════
# SEITE 2: ZUSAMMENFASSUNG
# ══════════════════════════════════════════════════════
pdf.add_page()
pdf.kapitel_titel("0", "Executive Summary")

pdf.body(
    "Dieser Bericht dokumentiert den vollständigen Farb-Audit des SafetyCockpit-Projekts "
    "(R/Shiny-App, Baudirektion Kanton Zürich). Alle Dateien wurden systematisch auf Farbreferenzen "
    "gescannt, gegen das offizielle CD Kanton Zürich sowie die Figma-Tokens (statistikZH/leu) geprüft "
    "und mit dem FaSi_VIZ Python-Standard abgeglichen. Der Bericht dokumentiert auch den umgekehrten "
    "Weg: Was sollte in einem nächsten Schritt im SafetyCockpit selbst korrigiert werden?"
)

# Statistik-Kacheln
pdf.set_font("Arial", "B", 9)
kacheln = [
    ("85",  "Farben total\ngefunden",       Bericht.ZH_BLAU),
    ("4",   "KONFORM\n(exakter CD-Match)",  (26,127,31)),
    ("~60", "PRÜFEN\n(leu-System, ZH-ok)",  (120,96,0)),
    ("4",   "ABWEICHUNG\nnicht konform",     (183,28,35)),
    ("~17", "FaSi-intern\nfunktional",       (80,80,180)),
]
xstart = 10
for val, lbl, farbe in kacheln:
    pdf.set_fill_color(*farbe)
    pdf.set_draw_color(*farbe)
    pdf.rect(xstart, pdf.get_y(), 36, 22, "F")
    pdf.set_text_color(*Bericht.WEISS)
    pdf.set_font("Arial", "B", 14)
    pdf.set_xy(xstart, pdf.get_y() + 2)
    pdf.cell(36, 8, val, align="C")
    pdf.set_font("Arial", "", 7)
    pdf.set_xy(xstart, pdf.get_y() + 8)
    pdf.multi_cell(36, 3.5, lbl, align="C")
    xstart += 38

pdf.set_text_color(*Bericht.SCHWARZ)
pdf.ln(28)

pdf.hinweis(
    "Wichtigste sofortige Erkenntnis: data/Infografiken.rda enthält Blau=#0070B4 (falsch). "
    "Nur Akzentfarben.rda wurde korrigiert (#0076BD). Infografiken.rda muss noch nachgezogen werden.",
    "rot"
)

pdf.hinweis(
    "schwere_cols in theming.R verwendet R X11 Named Colors (lightsteelblue2, gold, darkgoldenrod1, "
    "tomato2, grey50). Diese stimmen nicht mit der FaSi_VIZ UNFALLSCHWERE_PALETTE überein und sind "
    "plattformabhängig. Harmonisierung empfohlen, bedarf Absprache (visuelle Änderung in allen Plots).",
    "gelb"
)

pdf.hinweis(
    "Positive Bilanz: Alle 54 ktz_palette-Farben, die neue AMPEL_PALETTE (grün/gelb/rot/grau), "
    "softgelb (#FFF5CC) und softalarmrot (#FFD5CC) sowie sachschaden und unbekannt in "
    "UNFALLSCHWERE_PALETTE wurden in FaSi_VIZ v2.6.0 ergänzt.",
    "gruen"
)

# ══════════════════════════════════════════════════════
# SEITE 3–4: VOLLSTÄNDIGER FARBKATALOG
# ══════════════════════════════════════════════════════
pdf.add_page()
pdf.kapitel_titel("1", "Vollständiger Farbkatalog – SafetyCockpit")

pdf.body(
    "Alle nachfolgend aufgeführten Farbwerte wurden durch Scan sämtlicher Quelldateien "
    "(.R, .css, .yml, .json) und durch direktes Laden der R-Datenobjekte (.rda) aus dem "
    "Verzeichnis SafetyCockpit/ ermittelt. Die Konformitätsbewertung bezieht sich auf "
    "das CD Kanton Zürich (7 Kernfarben) sowie die statistikZH/leu-Tokens."
)

# ── 1.1 Palette-Objekte
pdf.abschnitt_titel("1.1  R-Datenobjekte (data/*.rda) – Akzentfarben")

AKZENT = [
    ("blau",       "#0076BD", "KONFORM", "Primary-Farbe, korrigiert von #0070B4"),
    ("dunkelblau", "#00407C", "PRÜFEN",  "Nah an CD Dunkelblau #003B6F"),
    ("tuerkis",    "#00797B", "FaSi-intern", "statistikZH leu"),
    ("gruen",      "#1A7F1F", "FaSi-intern", "Funktion Grün / Ampel"),
    ("bordeaux",   "#B01657", "FaSi-intern", "statistikZH leu"),
    ("magenta",    "#D40053", "FaSi-intern", "statistikZH leu"),
    ("violett",    "#7F3DA7", "FaSi-intern", "statistikZH leu"),
    ("grau60",     "#666666", "PRÜFEN",  "Black 60 ZH; CD Grautext = #4A4A49"),
]

pdf.tabellen_kopf(
    ["Name", "Hex-Wert", "Konformität", "Bemerkung"],
    [30, 28, 32, 100]
)
for row in AKZENT:
    status = row[2].split()[0]
    pdf.tabellen_zeile(list(row), [30, 28, 32, 100], status=status)

pdf.ln(3)

# Swatches Akzentfarben
y0 = pdf.get_y()
for i, (name, hex_, _, _) in enumerate(AKZENT):
    pdf.farb_swatch(hex_, name, 10 + i*24, y0)
pdf.ln(20)

# ── 1.2 Infografiken
pdf.abschnitt_titel("1.2  R-Datenobjekte – Infografiken (17 Einträge)")
pdf.hinweis(
    "KRITISCH: Infografiken['Blau'] = #0070B4 — noch NICHT korrigiert! "
    "Alle anderen Infografiken-Farben stimmen mit FaSi_VIZ tokens.json überein.",
    "rot"
)

INFOGRAFIKEN = [
    ("dunkelblau",    "#00407C", "PRÜFEN",     "leu-System"),
    ("tuerkis",       "#00797B", "FaSi-intern", "leu-System"),
    ("aquamarine",    "#0FA693", "FaSi-intern", "leu-System"),
    ("dunkelgruen",   "#00544C", "FaSi-intern", "leu-System"),
    ("gruen",         "#1A7F1F", "FaSi-intern", "leu-System"),
    ("grasgruen",     "#8A8C00", "FaSi-intern", "leu-System"),
    ("braun",         "#96170F", "FaSi-intern", "leu-System"),
    ("orange",        "#DC7700", "FaSi-intern", "leu-System"),
    ("rot",           "#D93C1A", "FaSi-intern", "Funktion Rot"),
    ("magenta",       "#D40053", "FaSi-intern", "leu-System"),
    ("bordeaux",      "#B01657", "FaSi-intern", "leu-System"),
    ("dunkelrot",     "#7A0049", "FaSi-intern", "leu-System"),
    ("dunkelviolett", "#54268E", "FaSi-intern", "leu-System"),
    ("violett",       "#7F3DA7", "FaSi-intern", "leu-System"),
    ("hellviolett",   "#9572D5", "FaSi-intern", "leu-System"),
    ("cyan",          "#009EE0", "PRÜFEN",     "nahe CD Hellblau #009FE3"),
    ("blau",          "#0070B4", "ABWEICHUNG", "FALSCH – muss #0076BD sein!"),
]

pdf.tabellen_kopf(
    ["Name", "Hex-Wert", "Konformität", "Bemerkung"],
    [35, 28, 32, 95]
)
for row in INFOGRAFIKEN:
    status = row[2].split()[0]
    pdf.tabellen_zeile(list(row), [35, 28, 32, 95], status=status)

pdf.ln(3)

# ── 1.3 Grautoene + Funktion + AkzentfarbenSoft
pdf.add_page()
pdf.abschnitt_titel("1.3  Grautoene, Funktion, AkzentfarbenSoft")

GRAU = [
    ("Black 100 ZH", "#000000", "KONFORM",     "CD Schwarz"),
    ("Black 80 ZH",  "#333333", "PRÜFEN",      "ZH Grauton-System"),
    ("Black 60 ZH",  "#666666", "PRÜFEN",      "ZH Grauton-System"),
    ("Black 40 ZH",  "#949494", "PRÜFEN",      "ZH Grauton-System"),
    ("Black 20 ZH",  "#CCCCCC", "PRÜFEN",      "ZH Grauton-System"),
    ("Black 10 ZH",  "#F0F0F0", "KONFORM",     "CD Grau Hintergrund"),
    ("Black 5 ZH",   "#F7F7F7", "PRÜFEN",      "Sehr nahe CD Hintergrund"),
]
FUNKTION = [
    ("Cyan",  "#009EE0", "PRÜFEN",      "nahe CD Hellblau #009FE3"),
    ("Rot",   "#D93C1A", "FaSi-intern", "Funktion/Alert"),
    ("Gruen", "#1A7F1F", "FaSi-intern", "Funktion/Success"),
]
SOFT = [
    ("Softblau",    "#EDF5FA", "FaSi-intern", "Pastell"),
    ("Blaugrau",    "#E0E8EE", "FaSi-intern", "Pastell"),
    ("Softtürkis",  "#E8F3F2", "FaSi-intern", "Pastell"),
    ("Softgrün",    "#EBF6EB", "FaSi-intern", "Pastell, Gauge-Zone"),
    ("Softbordeaux","#F6E3EA", "FaSi-intern", "Pastell"),
    ("Softrot",     "#FCEDF3", "FaSi-intern", "Pastell (Bordeaux-Soft)"),
    ("Softviolett", "#ECE2F1", "FaSi-intern", "Pastell"),
    ("Black 10 ZH", "#F0F0F0", "KONFORM",     "CD Grau Hintergrund"),
    ("Softgelb*",   "#FFF5CC", "FaSi-intern", "NEU v2.6.0 – Gauge-Zone Mitte"),
    ("Softalarmrot*","#FFD5CC","FaSi-intern", "NEU v2.6.0 – Gauge-Zone Alarm"),
]

pdf.set_font("Arial", "B", 9)
pdf.set_text_color(*Bericht.ZH_DUNKEL)
pdf.cell(0, 5, "Grautoene:", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*Bericht.SCHWARZ)
pdf.tabellen_kopf(["Name", "Hex", "Konformität", "Bemerkung"], [40, 28, 32, 90])
for r in GRAU:
    pdf.tabellen_zeile(list(r), [40, 28, 32, 90], status=r[2].split()[0])

pdf.ln(3)
pdf.set_font("Arial", "B", 9)
pdf.set_text_color(*Bericht.ZH_DUNKEL)
pdf.cell(0, 5, "Funktion (Bootstrap-Semantic):", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*Bericht.SCHWARZ)
pdf.tabellen_kopf(["Name", "Hex", "Konformität", "Bemerkung"], [40, 28, 32, 90])
for r in FUNKTION:
    pdf.tabellen_zeile(list(r), [40, 28, 32, 90], status=r[2].split()[0])

pdf.ln(3)
pdf.set_font("Arial", "B", 9)
pdf.set_text_color(*Bericht.ZH_DUNKEL)
pdf.cell(0, 5, "AkzentfarbenSoft (inkl. 2 neue Einträge v2.6.0):", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(*Bericht.SCHWARZ)
pdf.tabellen_kopf(["Name", "Hex", "Konformität", "Bemerkung"], [40, 28, 32, 90])
for r in SOFT:
    pdf.tabellen_zeile(list(r), [40, 28, 32, 90], status=r[2].split()[0])

# ── 1.4 ktz_palette
pdf.add_page()
pdf.abschnitt_titel("1.4  ktz_palette – 54-Farben Sequenzpalette (statistikZH/leu)")
pdf.body(
    "Die ktz_palette ist die offizielle Infografik-Sequenzpalette des Kantons Zürich "
    "(statistikZH/leu-Paket). Sie besteht aus 54 Einträgen, gegliedert in 6 Reihen à 9 Farben: "
    "[1–9] Satte Hauptfarben · [10–18] Mittlere Töne · [19–27] Helle Töne · "
    "[28–36] Sehr helle Pastelltöne · [37–45] Dunkle Varianten · [46–54] Mitteldunkle Varianten. "
    "Alle 54 Farben wurden in FaSi_VIZ v2.6.0 unter colors.sequential_palette in tokens.json aufgenommen."
)

SEQ_PALETTE = [
    "#009EE0","#FFCC00","#3EA743","#E2001A","#0076E0","#EB690B","#00A1A3","#885EA0","#E30059",
    "#53CCFF","#FFE066","#84D188","#FF5568","#53AEFF","#F8A468","#2FFCFF","#B89EC6","#E15598",
    "#8DDDFF","#FFEB99","#ADE1AF","#FF8D9A","#8DC9FF","#FAC29A","#74FDFF","#CFBED9","#E18EBA",
    "#C6EEFF","#FFF5CC","#D6F0D7","#FFC6CD","#C6E4FF","#FDE1CD","#BAFEFF","#E7DFEC","#FFC6DD",
    "#004F70","#7F6600","#1F5322","#71000C","#003B70","#753506","#005152","#444F70","#72002C",
    "#0076A8","#BF9900","#2E7D32","#A90013","#0059A8","#B04F08","#00797A","#664678","#AA0043",
]

sw_w, sw_h = 19.5, 10
x_start = 10
y0 = pdf.get_y()

for i, hex_ in enumerate(SEQ_PALETTE):
    col = i % 9
    row = i // 9
    x = x_start + col * (sw_w + 1.2)
    y = y0 + row * (sw_h + 5)
    r, g, b = hex_to_rgb(hex_)
    pdf.set_fill_color(r, g, b)
    pdf.set_draw_color(200, 200, 200)
    pdf.rect(x, y, sw_w, sw_h, "FD")
    tc = text_color_for_bg(hex_)
    tr, tg, tb = hex_to_rgb(tc)
    pdf.set_text_color(tr, tg, tb)
    pdf.set_font("Arial", "", 5)
    pdf.set_xy(x, y + sw_h/2 - 2)
    pdf.cell(sw_w, 3, str(i+1), align="C")
    pdf.set_text_color(80, 80, 80)
    pdf.set_font("Arial", "", 5.5)
    pdf.set_xy(x, y + sw_h + 0.5)
    pdf.cell(sw_w, 3, hex_, align="C")

pdf.set_y(y0 + 6 * (sw_h + 5) + 5)
pdf.ln(2)

# ══════════════════════════════════════════════════════
# SEITE 5: HARDCODIERTE FARBEN
# ══════════════════════════════════════════════════════
pdf.add_page()
pdf.kapitel_titel("2", "Hardcodierte Farben in R-Quelldateien")
pdf.body(
    "Nachfolgend alle direkt im Code eingebetteten Farbwerte (nicht über Paletten-Objekte), "
    "mit Quelldatei, Verwendungskontext, Konformitätsbewertung und Empfehlung."
)

# 2.1 schwere_cols
pdf.abschnitt_titel("2.1  theming.R – schwere_cols (Named R Colors)", neu=True)
pdf.hinweis(
    "Diese Farben werden in ALLEN Schwerekarten, Maps und Plots verwendet. "
    "Sie stimmen nicht mit FaSi_VIZ UNFALLSCHWERE_PALETTE überein. "
    "Harmonisierung ist eine visuelle Veränderung und erfordert explizite Freigabe.",
    "gelb"
)

SCHWERE = [
    ("lightsteelblue2","#BCD2EE","Sachschaden/nicht verletzt","ABWEICHUNG","#0076BD (Blau ZH)"),
    ("gold",           "#FFD700","Leichtverletzte",           "ABWEICHUNG","#FFCC00 (Gelb ZH, nahe)"),
    ("darkgoldenrod1", "#FFB90F","Schwerverletzte",           "ABWEICHUNG","#E87600 (Orange ZH)"),
    ("tomato2",        "#EE4000","Getötete",                  "ABWEICHUNG","#B31523 (Dunkelrot)"),
    ("grey50",         "#7F7F7F","unbekannt",                 "ABWEICHUNG","#949494 (Black 40 ZH)"),
]

pdf.tabellen_kopf(
    ["R-Name", "Hex (R X11)", "Verwendung", "Status", "FaSi_VIZ Empfehlung"],
    [32, 26, 40, 26, 66]
)
for r in SCHWERE:
    pdf.tabellen_zeile(list(r), [32, 26, 40, 26, 66], status="ABWEICHUNG")
pdf.ln(3)

# 2.2 gauge_plots
pdf.abschnitt_titel("2.2  gauge_plots.R – Soft-Zonen-Farben")
pdf.hinweis(
    "Die Farben #FFF5CC und #ffd5cc wurden in tokens.json (FaSi_VIZ) als softgelb/softalarmrot "
    "aufgenommen. Im R-Code sind sie noch hardcodiert. Kommentare verweisen auf nicht-existente "
    "Keys in AkzentfarbenSoft.rda (Softgelb, Softrot). Erst nach Ergänzung von AkzentfarbenSoft.rda "
    "kann der Code auf die Palettenobjekte umgestellt werden.",
    "gelb"
)

GAUGE = [
    ("#FFF5CC","gauge_plots.R Zeile 60","Gauge-Zone Q25–Q75 (Mitte/Gelb)","PRÜFEN","= ktz_palette[29]; jetzt in tokens.json als softgelb"),
    ("#ffd5cc","gauge_plots.R Zeile 64","Gauge-Zone >Q75 (Alarm/Rot)","PRÜFEN","nahe ktz_palette[31] #FFC6CD; jetzt als softalarmrot"),
    ("#00000010","cumul/haupt/vs_plot.R","Transparente Füllfl. (KI-Bänder)","KONFORM","Technischer Hilfswert"),
    ("#00000000","cumul/haupt/vs_plot.R","Unsichtbare Linien","KONFORM","Technischer Hilfswert"),
    ("grey","gauge_plots.R Zeile 69","Schwellenwert-Linie (Median)","ABWEICHUNG","#949494 (Black 40 ZH)"),
]

pdf.tabellen_kopf(
    ["Wert", "Datei / Zeile", "Kontext", "Status", "Empfehlung"],
    [26, 50, 48, 22, 44]
)
for r in GAUGE:
    pdf.tabellen_zeile(list(r), [26, 50, 48, 22, 44], status=r[3])
pdf.ln(3)

# 2.3 lagebericht
pdf.abschnitt_titel("2.3  lagebericht_utils.R – PDF-Berichtsfarben")
pdf.hinweis(
    "#1f77b4 (Matplotlib-Blau) wurde bewusst nicht geändert (städtischer Bericht, externe Vorgabe). "
    "#b00020 wurde als nicht weiterverfolgbar eingestuft. "
    "Named Colors (lightgreen, orange, red, beige, lightgrey) sind Prio-2-Empfehlungen: offen.",
    "blau"
)

LAGE = [
    ("#1f77b4","Zeilen 61,70","Titel/Untertitel PDF","ABWEICHUNG","nicht geändert (städt. Bericht)"),
    ("#b00020","safety_cockpit.R","Fehler-Meldung Inline","ABWEICHUNG","nicht weiterverfolgt"),
    ("#999","Zeile 76","Tabellenrahmen","PRÜFEN","→ #949494 (Black 40 ZH) – offen"),
    ("#f3f3f3","Zeile 77","Tabellenkopf Hintergrund","PRÜFEN","→ #F0F0F0 (Black 10 ZH) – offen"),
    ("#666 / #666666","Zeile 102 + mapdensity","Fusszeile, Kartenlinie","PRÜFEN","= Black 60 ZH [OK]"),
    ("lightgreen","Zeile 14,147","Status Reduktion (gut)","ABWEICHUNG","→ #1A7F1F – offen"),
    ("lightgrey","Zeile 148","Status null","ABWEICHUNG","→ #CCCCCC (Black 20 ZH) – offen"),
    ("orange","Zeile 20,149","Status Warnung","ABWEICHUNG","→ #DC7700 – offen"),
    ("red","Zeile 27,150","Status Alert signifikant","ABWEICHUNG","→ #D93C1A – offen"),
    ("beige","Zeile 156","Jahres-Spalten Hintergrund","ABWEICHUNG","→ #F0F0F0 – offen"),
]

pdf.tabellen_kopf(
    ["Wert", "Zeile/Datei", "Kontext", "Status", "Empfehlung"],
    [26, 36, 44, 26, 58]
)
for r in LAGE:
    status_key = "OFFEN" if "offen" in r[4] else r[3]
    pdf.tabellen_zeile(list(r), [26, 36, 44, 26, 58], status=status_key)
pdf.ln(3)

# ══════════════════════════════════════════════════════
# SEITE 6: KAPOBERICHT EXCEL
# ══════════════════════════════════════════════════════
pdf.add_page()
pdf.kapitel_titel("3", "Excel-Kategoriefarben – kapobericht_mod.R")
pdf.body(
    "Der XLSX-Export des Kapoberichts verwendet 20 Farben zur visuellen Unterscheidung von "
    "Verkehrsteilnehmer-Kategorien. Diese wurden als FaSi-intern klassiert. "
    "Einige liegen nahe an ktz_palette-Tönen, wurden aber nie direkt abgeglichen. "
    "Nachfolgend die vollständige Liste mit Ähnlichkeitsanalyse."
)

KAPO = [
    ("#A6A6A6","#F2F2F2","Allgemein (Kopfzeile/Zeile)","—",     "Black 40/5 ZH; nah, nicht identisch"),
    ("#C6E0B4","#E2EFDA","Fussgänger / Kinder",         "—",     "nahe ktz_palette[30] #D6F0D7"),
    ("#F4B084","#F8CBAD","E-Trottinett / Personenwagen","—",     "nahe ktz_palette[15] #F8A468"),
    ("#B4C6E7","#D9E1F2","Velo / Senioren",              "—",     "nahe ktz_palette[32] #C6E4FF"),
    ("#FFE699","#FFF2CC","E-Bike / FG+FGS",              "—",     "nahe ktz_palette[11] #FFE066"),
    ("#ACB9CA","#D6DCE4","Motorrad",                     "—",     "Blaugrau; kein direktes leu-Äquiv."),
    ("#FCE4D6","#F8CBAD","Personenwagen Pastell",        "—",     "nahe ktz_palette[33] #FDE1CD"),
    ("#A9D08E","#C6E0B4","Kinder / Fussgänger",          "—",     "nahe ktz_palette[12] #84D188"),
    ("#8EA9DB","#B4C6E7","Senioren",                     "—",     "nahe ktz_palette[23] #8DC9FF"),
    ("#FFD966","#FFE699","FG / FGS",                     "—",     "nahe ktz_palette[2] #FFCC00"),
]

pdf.tabellen_kopf(
    ["Farbe 1 (Kopf)", "Farbe 2 (Zeile)", "Kategorie", "Status", "Hinweis"],
    [30, 30, 40, 16, 74]
)
for r in KAPO:
    pdf.tabellen_zeile(list(r), [30, 30, 40, 16, 74], status="FaSi-intern")

pdf.ln(4)
pdf.hinweis(
    "Empfehlung: Die Excel-Farben können mittelfristig an die exakten ktz_palette-Töne angeglichen "
    "werden. Damit würden Screen-Darstellung (SafetyCockpit UI) und XLSX-Export dieselbe "
    "Farbgebung verwenden. Voraussetzung: visueller Abnahme durch FaSi.",
    "blau"
)

# ══════════════════════════════════════════════════════
# SEITE 7: DURCHGEFÜHRTE KORREKTUREN
# ══════════════════════════════════════════════════════
pdf.add_page()
pdf.kapitel_titel("4", "Durchgeführte Korrekturen (umgesetzt)")
pdf.body(
    "Folgende Änderungen wurden im Rahmen des Audits tatsächlich implementiert und getestet."
)

ERLEDIGT = [
    ("data/Akzentfarben.rda","Blau: #0070B4 → #0076BD","SafetyCockpit",
     "ERLEDIGT","Figma-Token colors.accent.blau"),
    ("tokens.json","accent_soft: +softgelb #FFF5CC","FaSi_VIZ v2.6.0",
     "ERLEDIGT","aus ktz_palette[29] abgeleitet"),
    ("tokens.json","accent_soft: +softalarmrot #FFD5CC","FaSi_VIZ v2.6.0",
     "ERLEDIGT","aus gauge_plots.R übernommen"),
    ("tokens.json","colors.sequential_palette (54 Farben)","FaSi_VIZ v2.6.0",
     "ERLEDIGT","vollständige ktz_palette"),
    ("fasi_themes.py","UNFALLSCHWERE_PALETTE: +sachschaden +unbekannt","FaSi_VIZ v2.6.0",
     "ERLEDIGT","war 3, jetzt 5 Stufen"),
    ("fasi_themes.py","AMPEL_PALETTE: gruen/gelb/rot/grau","FaSi_VIZ v2.6.0",
     "ERLEDIGT","aus SafetyCockpit Quartillogik abgeleitet"),
    ("fasi_themes.py","get_ampel_color() Funktion","FaSi_VIZ v2.6.0",
     "ERLEDIGT","Schnellzugriff analog get_unfallschwere_color()"),
    ("__init__.py + pyproject.toml","Version 2.5.0 → 2.6.0","FaSi_VIZ v2.6.0",
     "ERLEDIGT","synchron in beiden Dateien"),
    ("tests/test_fasi_zh_viz.py","3 neue Tests (ampel, schwere-5stufen, get_farbe)","FaSi_VIZ v2.6.0",
     "ERLEDIGT","90/90 Tests grün"),
    ("examples/fasi_design_showcase.html","Showcase auf v2.6.0 aktualisiert","FaSi_VIZ v2.6.0",
     "ERLEDIGT","alle neuen Elemente visualisiert"),
]

pdf.tabellen_kopf(
    ["Datei", "Änderung", "Projekt", "Status", "Quelle/Begründung"],
    [45, 55, 28, 20, 42]
)
for r in ERLEDIGT:
    pdf.tabellen_zeile(list(r), [45, 55, 28, 20, 42], status="ERLEDIGT")

# ══════════════════════════════════════════════════════
# SEITE 8: RÜCKWÄRTSWEG – EMPFEHLUNGEN FÜR SAFETYCOCKPIT
# ══════════════════════════════════════════════════════
pdf.add_page()
pdf.kapitel_titel("5", "Rückwärtsweg – Empfehlungen für SafetyCockpit")
pdf.body(
    "Was sollte in einem nächsten Schritt IM SafetyCockpit selbst angepasst, ergänzt oder "
    "konzeptionell geklärt werden? Die Empfehlungen sind nach Priorität gegliedert."
)

# Prio A
pdf.abschnitt_titel("Prio A – Korrekturen (technisch notwendig, kein visueller Impact)", neu=False)

PRIO_A = [
    ("data/Infografiken.rda","Infografiken['Blau'] #0070B4 → #0076BD",
     "Identische Korrektur wie Akzentfarben. sunset_plot.R nutzt Infografiken['Blau']."),
    ("data/AkzentfarbenSoft.rda","Softgelb + Softalarmrot hinzufügen",
     "gauge_plots.R kommentiert auf AkzentfarbenSoft['Softgelb/Softrot'], Keys existieren aber nicht."),
    ("theming.R Z.35","rgb(242,242,242) → Grautoene['Black 10 ZH']",
     "Accordion-Hintergrund: #F2F2F2 statt #F0F0F0. Minimale Differenz, aber inkonsistent."),
    ("gauge_plots.R Z.60,64","Hardcoded #FFF5CC/#ffd5cc → AkzentfarbenSoft['Softgelb'/'Softalarmrot']",
     "Erst nach Ergänzung von AkzentfarbenSoft.rda (Schritt 2 oben)."),
]

pdf.tabellen_kopf(
    ["Datei / Zeile", "Änderung", "Begründung"],
    [45, 65, 80]
)
for r in PRIO_A:
    pdf.tabellen_zeile(list(r), [45, 65, 80], status="OFFEN")
pdf.ln(3)

# Prio B
pdf.abschnitt_titel("Prio B – Harmonisierung schwere_cols (visueller Impact, Absprache nötig)")
pdf.hinweis(
    "Diese Änderung betrifft ALLE Schwere-Visualisierungen (Maps, Zeitreihen, Balken). "
    "Unbedingt visuell prüfen und mit Stevan freigeben, bevor implementiert.",
    "gelb"
)

PRIO_B = [
    ("theming.R Z.5","lightsteelblue2  →  #0076BD","Sachschaden: ZH Blau statt R X11-Grau"),
    ("theming.R Z.6","gold             →  #FFCC00","Leichtverletzt: exakter ZH Gelb"),
    ("theming.R Z.7","darkgoldenrod1   →  #E87600","Schwerverletzt: Orange ZH statt Goldton"),
    ("theming.R Z.8","tomato2          →  #B31523","Getötet: ZH Dunkelrot statt Tomatrot"),
    ("theming.R Z.13","grey50          →  #949494","Unbekannt: Black 40 ZH"),
]

pdf.tabellen_kopf(["Datei / Zeile", "Von (aktuell)", "Zu (FaSi_VIZ Standard)"], [45, 70, 75])
for r in PRIO_B:
    pdf.tabellen_zeile(list(r), [45, 70, 75], status="OFFEN")
pdf.ln(3)

# Prio C
pdf.abschnitt_titel("Prio C – Named Colors ersetzen (lagebericht_utils.R)")
pdf.body(
    "Folgende Named CSS/R-Colors in lagebericht_utils.R sollten durch definierte Hex-Werte "
    "ersetzt werden, um plattformübergreifende Konsistenz sicherzustellen:"
)

PRIO_C = [
    ("lightgreen","#1A7F1F","Reduktion (positiv)"),
    ("orange",    "#DC7700","Warnung (nicht signifikant)"),
    ("red",       "#D93C1A","Alert (signifikant)"),
    ("lightgrey", "#CCCCCC","Status null / kein Wert"),
    ("beige",     "#F0F0F0","Jahres-Spalten Hintergrund"),
    ("#999",      "#949494","Tabellenrahmen (Black 40 ZH)"),
    ("#f3f3f3",   "#F0F0F0","Tabellenkopf (Black 10 ZH)"),
]

pdf.tabellen_kopf(["Aktuell", "Empfehlung", "Kontext"], [40, 40, 110])
for r in PRIO_C:
    pdf.tabellen_zeile(list(r), [40, 40, 110], status="OFFEN")
pdf.ln(3)

# Prio D
pdf.abschnitt_titel("Prio D – Excel-Kategoriefarben angleichen (kapobericht_mod.R)")
pdf.body(
    "Die 20 Excel-Kategoriefarben können an die nächsten ktz_palette-Äquivalente "
    "angeglichen werden, um Konsistenz zwischen UI und XLSX-Export herzustellen. "
    "Voraussetzung: visuelle Freigabe durch FaSi. Beispiele:"
)

PRIO_D = [
    ("#B4C6E7","ktz_palette[32] #C6E4FF","Velo/Senioren – Hellblau"),
    ("#C6E0B4","ktz_palette[30] #D6F0D7","Fussgänger/Kinder – Hellgrün"),
    ("#FFE699","ktz_palette[11] #FFE066","E-Bike/FGS – Hellgelb"),
    ("#F4B084","ktz_palette[15] #F8A468","E-Trotti – Hellorange"),
    ("#8EA9DB","ktz_palette[23] #8DC9FF","Senioren – Hellblau 2"),
]

pdf.tabellen_kopf(["Aktuell", "ktz_palette Äquivalent", "Kategorie"], [35, 55, 100])
for r in PRIO_D:
    pdf.tabellen_zeile(list(r), [35, 55, 100], status="OFFEN")
pdf.ln(3)

# Prio E
pdf.abschnitt_titel("Prio E – Konzeptionelle Klärungen (strategisch)")

KONZEPT = [
    (
        "Federführung schwere_cols Farbwahl",
        "SafetyCockpit (warm gold/amber) vs. FaSi_VIZ (ZH-Palette). Wer ist massgebend? "
        "Soll es eine gemeinsame R-Konstante geben, die auf FaSi_VIZ-Werte zeigt?"
    ),
    (
        "R-Paket für FaSi_VIZ-Konstanten?",
        "Soll es ein dünnes R-Paket geben, das UNFALLSCHWERE_PALETTE, AMPEL_PALETTE "
        "und sequential_palette als R-Vektoren bereitstellt – direkt aus den Python-Tokens "
        "generiert? Würde Doppelung eliminieren."
    ),
    (
        "Ampel-PNG-Dateien (www/ampel_rot.png etc.)",
        "Stimmen die Farben in den PNG-Bildern mit AMPEL_PALETTE überein? "
        "ampel_rot.png sollte #D93C1A verwenden, nicht eine beliebige Rotschattierung."
    ),
    (
        "Sunset-Gradient (sunset_plot.R)",
        "colorRamp zwischen Infografiken['Dunkelblau'] und Infografiken['Blau']. "
        "Nach Korrektur von Infografiken['Blau'] (→ #0076BD) verändert sich der Gradient leicht. "
        "Visuell prüfen."
    ),
]

for titel, text in KONZEPT:
    pdf.set_font("Arial", "B", 9)
    pdf.set_text_color(*Bericht.ZH_DUNKEL)
    pdf.set_x(10)
    pdf.cell(0, 6, "■  " + titel, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_text_color(*Bericht.SCHWARZ)
    pdf.body(text, indent=18)

# ══════════════════════════════════════════════════════
# SEITE 9: CD-REFERENZ UND GESAMTBEWERTUNG
# ══════════════════════════════════════════════════════
pdf.add_page()
pdf.kapitel_titel("6", "CD-Referenz Kanton Zürich und Gesamtbewertung")

pdf.abschnitt_titel("6.1  Offizielle CD-Kernfarben (7 Farben)")
pdf.body(
    "Die nachfolgenden 7 Farben sind die offiziellen Kernfarben des Kantons Zürich "
    "(CD-Vorgabe für SafetyCockpit-Audit). Jede gefundene Farbe wurde gegen diese Referenz geprüft."
)

CD_FARBEN = [
    ("Zürichblau",       "#005CA9", "Primärfarbe"),
    ("Dunkelblau",       "#003B6F", "Sekundärfarbe"),
    ("Hellblau/Akzent",  "#009FE3", "Akzentfarbe"),
    ("Schwarz",          "#000000", "Text, Rahmen"),
    ("Weiss",            "#FFFFFF", "Hintergrund"),
    ("Grau (Text)",      "#4A4A49", "Fliesstext"),
    ("Grau (Hintergrund)","#F0F0F0","Panels, Kacheln"),
]

y0 = pdf.get_y()
sw = 22
for i, (name, hex_, verw) in enumerate(CD_FARBEN):
    x = 10 + i * (sw + 2)
    r, g, b = hex_to_rgb(hex_)
    pdf.set_fill_color(r, g, b)
    pdf.set_draw_color(180, 180, 180)
    pdf.rect(x, y0, sw, 12, "FD")
    tc = text_color_for_bg(hex_)
    tr, tg, tb = hex_to_rgb(tc)
    pdf.set_text_color(tr, tg, tb)
    pdf.set_font("Arial", "", 6)
    pdf.set_xy(x, y0 + 4)
    pdf.cell(sw, 4, hex_, align="C")
    pdf.set_text_color(60, 60, 60)
    pdf.set_font("Arial", "", 7)
    pdf.set_xy(x, y0 + 13)
    pdf.cell(sw, 3, name[:12], align="C")
pdf.set_y(y0 + 20)
pdf.ln(3)

pdf.abschnitt_titel("6.2  Figma-Token Quelle (statistikZH/leu)")
pdf.body(
    "Die authoritative Quelle für alle digitalen Farben ist das GitHub-Repository statistikZH/leu "
    "(Figma-Token-Export). Dieses definiert die erweiterte Farbpalette, die über die 7 CD-Kernfarben "
    "hinausgeht und für Datenvisualisierungen im Kanton Zürich verbindlich ist. "
    "Alle Palettenobjekte in SafetyCockpit (ktz_palette, Akzentfarben, Infografiken etc.) "
    "stammen aus diesem System und gelten daher als 'leu-konform' (PRÜFEN-Status)."
)

pdf.abschnitt_titel("6.3  Gesamtbewertung SafetyCockpit")

GESAMT = [
    ("Palettenobjekte (.rda)","54 + 8 + 10 + 3 + 17 + 7 Farben","analysiert","Teilweise korrigiert"),
    ("schwere_cols (theming.R)","5 Named Colors","nicht konform","Offen - Prio B"),
    ("gauge Soft-Farben","#FFF5CC, #ffd5cc","in FaSi_VIZ ergaenzt","In R noch hardcodiert"),
    ("lagebericht Named Colors","7 Farben","nicht konform","Offen - Prio C"),
    ("kapobericht Excel-Farben","20 Farben","Klassiert FaSi-intern","Offen - Prio D"),
    ("Infografiken[Blau]","#0070B4","FALSCH","Offen - Prio A!"),
    ("Transparenz-Hilfswerte","#00000000, #00000010","Technisch OK","Keine Aktion"),
    ("CSS / YAML / Docker","keine Farben","Keine Farbwerte","Keine Aktion"),
]

pdf.tabellen_kopf(
    ["Bereich", "Umfang", "Analysiert/Status", "Nächster Schritt"],
    [50, 40, 44, 56]
)
for r in GESAMT:
    status = "ERLEDIGT" if "[OK]" in r[2] and "Offen" not in r[3] else \
             "ABWEICHUNG" if "[!]" in r[2] else \
             "OFFEN" if "Offen" in r[3] else "—"
    pdf.tabellen_zeile(list(r), [50, 40, 44, 56], status=status)

pdf.ln(5)
pdf.hinweis(
    "Fazit: Das SafetyCockpit nutzt ein solides, weitgehend konformes Farbsystem auf Basis "
    "der statistikZH/leu-Tokens. Die kritischsten Abweichungen sind (1) schwere_cols mit "
    "R X11 Named Colors statt ZH-Hex-Werten, (2) Infografiken['Blau'] noch auf #0070B4, "
    "und (3) mehrere Named Colors in lagebericht_utils.R. Alle anderen Farben sind entweder "
    "konform oder funktional begründet (FaSi-intern).",
    "gruen"
)

# ══════════════════════════════════════════════════════
# AUSGABE
# ══════════════════════════════════════════════════════
out = "C:/ClaudeAI/Projekte/FaSi_Viz/SafetyCockpit/FaSi_Farb_Audit_SafetyCockpit_v2.6.0.pdf"
pdf.output(out)
print(f"PDF erstellt: {out}")
print(f"Seiten: {pdf.page}")
