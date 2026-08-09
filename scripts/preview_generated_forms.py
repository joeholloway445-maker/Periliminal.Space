#!/usr/bin/env python3
"""Render what the procedural generators will actually produce.

EntityVisual and the PeriHuman race bodies are GDScript, and there is no
Godot binary here — so this mirrors their rules in Python and rasterises the
result with the same software renderer used for the GLB thumbnails. The
shapes, proportions and palettes follow the GDScript; lighting is
approximate.

The point is to decide before spending: if the generated entities already
read as distinct, paying to generate 600 of them is optional.

    python3 scripts/preview_generated_forms.py entities
    python3 scripts/preview_generated_forms.py races
"""

import math
import os
import random
import re
import sys

import numpy as np
from PIL import Image, ImageDraw

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "build", "previews")
SIZE = 300
BG = np.array([18, 18, 22], dtype=np.float32)

# --- mirrored from entity_visual.gd ---------------------------------------
FACTION_PALETTE = {
    "SovereignCrown": [(.72, .60, .22), (.35, .10, .12)],
    "VeiledCurrent": [(.25, .62, .70), (.10, .18, .34)],
    "WildlandsAscendant": [(.42, .62, .28), (.24, .16, .08)],
    "Factionless": [(.55, .53, .58), (.18, .17, .20)],
}
# --- mirrored from race_body_derivation.gd --------------------------------
AFFINITY_BODY = {
    "pow": {"build": .14, "muscle": .18, "shoulder_width": .13, "jaw_width": .08,
            "brow_depth": .06, "neck_thickness": .10},
    "spd": {"build": -.12, "muscle": -.04, "leg_length": .13, "waist": -.09,
            "cheek_fullness": -.07, "height": .05},
    "res": {"build": .16, "muscle": .09, "height": -.08, "neck_thickness": .12,
            "jaw_width": .06, "waist": .07},
    "sty": {"height": .09, "leg_length": .08, "cheekbone_height": .12,
            "cheekbone_width": -.06, "waist": -.07, "nose_width": -.05},
    "lck": {"build": -.06, "eye_size": .09, "eye_spacing": .05, "ear_size": .07,
            "chin_protrusion": -.05},
}


# ---------------------------------------------------------------- raster

def rasterise(prims, size=SIZE, yaw=-32.0, pitch=12.0):
    """prims: list of (vertices Nx3, faces Mx3, rgb 0-1). Returns a PIL image."""
    verts, faces, cols = [], [], []
    off = 0
    for v, f, c in prims:
        verts.append(v)
        faces.append(np.asarray(f) + off)
        cols.append(np.tile(np.asarray(c, dtype=np.float32) * 255.0, (len(f), 1)))
        off += len(v)
    if not verts:
        return None
    v = np.vstack(verts).astype(np.float64)
    f = np.vstack(faces)
    fc = np.vstack(cols)

    v -= (v.min(0) + v.max(0)) / 2.0
    ry, rx = math.radians(yaw), math.radians(pitch)
    v = v @ np.array([[math.cos(ry), 0, math.sin(ry)], [0, 1, 0],
                      [-math.sin(ry), 0, math.cos(ry)]]).T
    v = v @ np.array([[1, 0, 0], [0, math.cos(rx), -math.sin(rx)],
                      [0, math.sin(rx), math.cos(rx)]]).T
    extent = max(v.max(0) - v.min(0))
    if extent <= 0:
        return None
    s = (size * 0.80) / extent
    xs, ys, zs = v[:, 0] * s + size / 2, size / 2 - v[:, 1] * s, v[:, 2] * s

    img = np.repeat(BG[None, None, :], size, 0).repeat(size, 1)
    zbuf = np.full((size, size), -np.inf, dtype=np.float32)
    tri = np.stack([xs[f], ys[f], zs[f]], axis=-1)
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    n = np.divide(n, np.where(ln == 0, 1, ln))
    key = np.clip(n @ np.array([-.35, .62, .78]), 0, 1)
    shade = (0.34 + 0.70 * key)[:, None]
    face_col = np.clip(fc * shade, 0, 255)

    for i in np.argsort(tri[:, :, 2].mean(axis=1)):
        t = tri[i]
        x0, x1 = max(int(t[:, 0].min()), 0), min(int(t[:, 0].max()) + 1, size)
        y0, y1 = max(int(t[:, 1].min()), 0), min(int(t[:, 1].max()) + 1, size)
        if x1 <= x0 or y1 <= y0:
            continue
        yy, xx = np.mgrid[y0:y1, x0:x1]
        px, py = xx + .5, yy + .5
        (ax, ay), (bx, by), (cx, cy) = t[0, :2], t[1, :2], t[2, :2]
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-9:
            continue
        w0 = ((by - cy) * (px - cx) + (cx - bx) * (py - cy)) / den
        w1 = ((cy - ay) * (px - cx) + (ax - cx) * (py - cy)) / den
        w2 = 1 - w0 - w1
        ins = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not ins.any():
            continue
        z = w0 * t[0, 2] + w1 * t[1, 2] + w2 * t[2, 2]
        sub = zbuf[y0:y1, x0:x1]
        win = ins & (z > sub)
        if not win.any():
            continue
        sub[win] = z[win]
        img[y0:y1, x0:x1][win] = face_col[i]
    return Image.fromarray(img.astype(np.uint8))


# ---------------------------------------------------------------- solids

def _sphere(c, r, seg=10):
    vs, fs = [], []
    for i in range(seg + 1):
        lat = math.pi * i / seg
        for j in range(seg):
            lon = 2 * math.pi * j / seg
            vs.append([c[0] + r * math.sin(lat) * math.cos(lon),
                       c[1] + r * math.cos(lat),
                       c[2] + r * math.sin(lat) * math.sin(lon)])
    for i in range(seg):
        for j in range(seg):
            a = i * seg + j
            b = i * seg + (j + 1) % seg
            fs += [[a, b, a + seg], [b, b + seg, a + seg]]
    return np.array(vs), fs


def _box(c, s):
    x, y, z = s[0] / 2, s[1] / 2, s[2] / 2
    vs = np.array([[c[0] + dx * x, c[1] + dy * y, c[2] + dz * z]
                   for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)])
    fs = [[0, 1, 3], [0, 3, 2], [4, 6, 7], [4, 7, 5], [0, 4, 5], [0, 5, 1],
          [2, 3, 7], [2, 7, 6], [0, 2, 6], [0, 6, 4], [1, 5, 7], [1, 7, 3]]
    return vs, fs


def _cone(base, h, r, seg=8):
    vs = [[base[0], base[1] + h, base[2]]]
    for j in range(seg):
        a = 2 * math.pi * j / seg
        vs.append([base[0] + r * math.cos(a), base[1], base[2] + r * math.sin(a)])
    fs = [[0, 1 + j, 1 + (j + 1) % seg] for j in range(seg)]
    return np.array(vs), fs


def _capsule(c, r, h):
    return _sphere(c, r * 1.1, 9)[0] * [1, h / (2 * r * 1.1), 1] + [0, c[1] * 0, 0], _sphere(c, r, 9)[1]


# ---------------------------------------------------------------- entities

def entity_prims(eid, faction, category, role, stage):
    rng = random.Random(hash((eid, stage)) & 0xFFFFFFFF)
    pal = FACTION_PALETTE.get(faction, FACTION_PALETTE["Factionless"])
    hot, cold = np.array(pal[0]), np.array(pal[1])
    col = cold + (hot - cold) * (0.35 + 0.3 * stage)   # ndarray, so it scales
    p = []

    if category == "Energy":
        v, f = _sphere((0, .75, 0), .42, 10); p.append((v, f, tuple(col)))
        for _ in range(6 + stage * 4):
            a = rng.random() * 6.283
            y = rng.uniform(.5, 1.5)
            v, f = _cone((math.cos(a) * .45, y, math.sin(a) * .45),
                         rng.uniform(.5, 1.0 + stage * .35), .09)
            p.append((v, f, tuple(hot)))
    elif category == "Entropy":
        v, f = _sphere((0, .7, 0), .38, 9); p.append((v, f, tuple(col)))
        for _ in range(4 + stage * 3):
            s = rng.uniform(.18, .42)
            v, f = _box((rng.uniform(-.7, .2), rng.uniform(.2, 1.6), rng.uniform(-.5, .5)),
                        (s, s * rng.uniform(.5, 1.6), s))
            p.append((v, f, tuple(col * rng.uniform(.6, 1.1))))
    elif category == "Gravity":
        v, f = _sphere((0, .9, 0), .55, 11); p.append((v, f, tuple(col)))
        for _ in range(3 + stage * 2):
            a, d = rng.random() * 6.283, rng.uniform(.85, 1.3 + stage * .3)
            v, f = _sphere((math.cos(a) * d, .9 + rng.uniform(-.4, .5), math.sin(a) * d),
                           rng.uniform(.10, .20), 7)
            p.append((v, f, tuple(hot)))
    elif category == "Psyche":
        v, f = _sphere((0, .95, 0), .32, 9)
        p.append((v * [1, 2.6, 1], f, tuple(col)))
        heads = 1 + stage * 3
        for i in range(heads):
            sp = (i / max(heads - 1, 1) - .5) * (.5 + stage * .55)
            v, f = _sphere((math.sin(sp) * .9, 1.85, -math.cos(sp) * .35 + .35), .22, 8)
            p.append((v, f, tuple(hot * .8 + col * .2)))
    elif category == "Quantum":
        for i in range(2 + stage):
            o = i * .16
            v, f = _sphere((rng.uniform(-o, o), .75, rng.uniform(-o, o)), .34, 9)
            p.append((v * [1, 2.1, 1], f, tuple(col * (1 - i * .12))))
    else:  # Matter
        y = 0.0
        for i in range(3 + stage):
            w = rng.uniform(.5, .95) * (1 - i * .09)
            h = rng.uniform(.28, .5)
            v, f = _box((rng.uniform(-.08, .08), y + h / 2, 0), (w, h, w * rng.uniform(.6, 1.0)))
            p.append((v, f, tuple(col * rng.uniform(.85, 1.15))))
            y += h

    if role == "Apex":
        n = 5 + stage * 2
        for i in range(n):
            a = 6.283 * i / n
            v, f = _cone((math.cos(a) * .34, 2.05 + stage * .1, math.sin(a) * .34),
                         .38 + stage * .16, .06)
            p.append((v, f, tuple(hot)))
    return p


def load_entities(limit):
    src = open(os.path.join(REPO, "godot/src/data/entity_dex_data.gd"), encoding="utf-8").read()
    out = []
    for blk in re.split(r"\n\s*\{id=", src)[1:]:
        m = re.match(r'"([A-Z0-9\-]+)"', blk)
        if not m:
            continue
        stages = re.findall(r'\{name="([^"]*)"', blk)
        out.append({
            "id": m.group(1),
            "faction": (re.search(r'faction="(\w+)"', blk) or [None, "Factionless"])[1],
            "category": (re.search(r'category="(\w+)"', blk) or [None, "Matter"])[1],
            "role": (re.search(r'role="(\w+)"', blk) or [None, ""])[1],
            "name": stages[0] if stages else m.group(1),
            "stages": max(len(stages), 1),
        })
    return out[:limit]


# ---------------------------------------------------------------- races

def race_prims(name, genes, tint=(.62,.58,.55), mark=None, emis=0.0):
    """A crude PeriHuman: proportions driven by the same gene deltas."""
    g = lambda k: genes.get(k, 0.0)
    height = 1.0 + g("height") * .5
    build = 1.0 + g("build") * .9
    musc = 1.0 + g("muscle") * .7
    legs = 1.0 + g("leg_length") * .6
    waist = 1.0 + g("waist") * .8
    sh = 1.0 + g("shoulder_width") * .9
    neck = 1.0 + g("neck_thickness") * .8
    head_w = 1.0 + (g("jaw_width") + g("cheekbone_width")) * .5
    eye = 1.0 + g("eye_size") * .8
    col = tint
    p = []
    hip = .82 * height
    # legs
    for side in (-1, 1):
        v, f = _box((side * .13 * build, hip * .5 * legs, 0),
                    (.17 * build, hip * legs, .19 * build))
        p.append((v, f, col))
    # torso
    v, f = _box((0, hip * legs + .30 * height, 0),
                (.44 * build * waist, .60 * height, .26 * build))
    p.append((v, f, col))
    # shoulders
    v, f = _box((0, hip * legs + .56 * height, 0),
                (.60 * sh * musc, .16 * height, .28 * build))
    p.append((v, f, tuple(np.array(col) * 1.05)))
    # arms
    for side in (-1, 1):
        v, f = _box((side * .34 * sh * musc, hip * legs + .30 * height, 0),
                    (.13 * musc, .52 * height, .14 * musc))
        p.append((v, f, col))
    # neck + head
    v, f = _box((0, hip * legs + .68 * height, 0), (.13 * neck, .10 * height, .13 * neck))
    p.append((v, f, col))
    v, f = _sphere((0, hip * legs + .84 * height, 0), .19 * head_w, 11)
    p.append((v, f, tuple(np.clip(np.array(col) * (1.08 + emis * .5), 0, 1))))
    # marking colour reads as a chest band, the way the lens shows it in game
    if mark:
        v, f = _box((0, hip * legs + .44 * height, .14 * build),
                    (.40 * build * waist, .10 * height, .04))
        p.append((v, f, mark))
    # eyes read scale at thumbnail size
    for side in (-1, 1):
        v, f = _sphere((side * .07 * head_w, hip * legs + .86 * height, .16 * head_w),
                       .030 * eye, 6)
        p.append((v, f, (.09, .09, .12)))
    return p


def load_races():
    lore = open(os.path.join(REPO, "godot/src/data/race_lore.gd"), encoding="utf-8").read()
    arch = open(os.path.join(REPO, "godot/src/perihuman/human_race_archetypes.gd"),
                encoding="utf-8").read().split("const RACES", 1)[1]
    names = open(os.path.join(REPO, "godot/src/data/race_names.gd"), encoding="utf-8").read()
    authored = {}
    for _l, nm, body in re.findall(r'#\s*([^\n]*)\n\t"([A-Za-z]+)":\s*\{(.*?)\n\t\},', arch, re.S):
        gm = re.search(r'"genes":\s*\{([^}]*)\}', body)
        authored[nm] = {k: float(v) for k, v in
                        re.findall(r'"(\w+)":\s*(-?[\d.]+)', gm.group(1))} if gm else {}
    display = dict(re.findall(r'"(\w+)":\s*\{"civil": "[^"]*",\s*"true": "([a-z_]+)"', names))
    out = []
    for m in re.finditer(r'"([A-Za-z]+)": \{\s*name = "[^"]*".*?affinity_stats = \[([^\]]*)\]',
                         lore, re.S):
        canon = m.group(1)
        affs = re.findall(r'"(\w+)"', m.group(2))
        a = dict(authored.get(canon, {}))
        genes = dict(a)
        w = 1.0
        for s in affs:
            for gene, val in AFFINITY_BODY.get(s, {}).items():
                if gene in a:
                    continue
                genes[gene] = genes.get(gene, 0.0) + val * w
            w *= 0.65
        blk = re.search(r'"%s":\s*\{(.*?)\n\t\},' % canon, arch, re.S)
        body = blk.group(1) if blk else ""
        def _hex(field):
            h = re.search(r'"%s":\s*"([0-9a-fA-F]{6})"' % field, body)
            if not h:
                return None
            v = h.group(1)
            return tuple(int(v[i:i+2], 16) / 255.0 for i in (0, 2, 4))
        em = re.search(r'"emissive_strength":\s*([\d.]+)', body)
        out.append({"canon": canon, "affs": affs, "genes": genes,
                    "tint": _hex("skin_tint") or (.62, .58, .55),
                    "mark": _hex("marking_color"),
                    "emis": float(em.group(1)) if em else 0.0,
                    "true": display.get(canon, canon).replace("_", " ").title()})
    return out


# ---------------------------------------------------------------- sheets

def sheet(cells, cols, path, cell=SIZE):
    lab = 30
    rows = (len(cells) + cols - 1) // cols
    S = Image.new("RGB", (cols * (cell + 8) + 8, rows * (cell + 8 + lab) + 8), (12, 12, 15))
    d = ImageDraw.Draw(S)
    for i, (label, im) in enumerate(cells):
        r, c = divmod(i, cols)
        x, y = 8 + c * (cell + 8), 8 + r * (cell + 8 + lab)
        if im is not None:
            S.paste(im, (x, y))
        for j, line in enumerate(label.split("\n")[:2]):
            d.text((x + 3, y + cell + 2 + j * 13), line, fill=(168, 168, 180))
    S.save(path)
    return S.size


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "entities"
    os.makedirs(OUT, exist_ok=True)

    if what == "races":
        races = load_races()
        cells = []
        for r in races:
            im = rasterise(race_prims(r["canon"], r["genes"], r["tint"], r["mark"], r["emis"]), yaw=-26, pitch=6)
            cells.append(("%s  (%s)\n%s" % (r["true"], r["canon"], "/".join(r["affs"])), im))
        p = os.path.join(OUT, "sheet_races.png")
        print("races:", len(cells), sheet(cells, 5, p), "->", p)
        return

    ents = load_entities(24)
    cells = []
    for e in ents:
        st = min(e["stages"] - 1, 2)
        im = rasterise(entity_prims(e["id"], e["faction"], e["category"], e["role"], st))
        cells.append(("%s  %s\n%s%s" % (e["name"][:16], e["id"], e["category"],
                                        " · " + e["role"] if e["role"] else ""), im))
    p = os.path.join(OUT, "sheet_entities.png")
    print("entities:", len(cells), sheet(cells, 6, p), "->", p)


if __name__ == "__main__":
    raise SystemExit(main())
