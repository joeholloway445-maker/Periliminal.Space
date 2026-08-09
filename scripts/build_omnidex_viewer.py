#!/usr/bin/env python3
"""Build a browsable Master Omni Dex from the game's data and generated art.

Everything the dex knows lives in the repo already — races with passives and
drawbacks, 600 entity stages with lore, frames, morph rigs — but reading it
means opening five GDScript files. This renders it as one searchable page
that works offline, with the generated art alongside each entry.

Images are referenced by relative path rather than embedded, so the page
stays small and picks up new art on a re-run without regenerating.

    python3 scripts/build_omnidex_viewer.py
    # -> build/omnidex/index.html   (open it directly, no server needed)
"""

import csv
import html
import json
import os
import re
import shutil

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(REPO, "godot", "assets", "entities")
OUT = os.path.join(REPO, "build", "omnidex")


def read(rel):
    p = os.path.join(REPO, rel)
    return open(p, encoding="utf-8").read() if os.path.exists(p) else ""


def collect():
    """Every dex entry, with whatever art exists for it."""
    have = {f[:-4].lower() for f in os.listdir(ART)} if os.path.isdir(ART) else set()
    entries = []

    # --- races: Omni Dex data + the layer-name registers ---
    omni = read("godot/src/data/omni_dex.gd")
    names = read("godot/src/data/race_names.gd")
    registers = {}
    for canon, civil, true_id in re.findall(
            r'"(\w+)":\s*\{"civil": "([^"]*)",\s*"true": "([a-z_]+)"', names):
        registers[true_id] = {"canon": canon, "civil": civil}

    m = re.search(r"const RACES: Dictionary = \{(.*?)\n\}", omni, re.S)
    if m:
        for entry in re.split(r'\n\t"', m.group(1))[1:]:
            rid = entry.split('"', 1)[0]
            g = lambda k: (re.search(r'"%s": "([^"]*)"' % k, entry) or [None, ""])[1]
            reg = registers.get(rid, {})
            entries.append({
                "kind": "race", "id": rid, "name": g("name"),
                "art": rid if rid in have else "",
                "faction": g("faction"),
                "sub": " · ".join(filter(None, [reg.get("canon"), reg.get("civil")])),
                "fields": {"Passive": g("passive"), "Drawback": g("drawback"),
                           "Stat bonus": (re.search(r'"stat_bonus": (\{[^}]*\})', entry)
                                          or [None, ""])[1]},
                "text": g("lore") or g("description"),
            })

    # --- frames ---
    reg_src = read("godot/src/data/omni_dex_registry.gd")
    blk = re.search(r"const FRAMES: Array\[Dictionary\] = \[(.*?)\n\]", reg_src, re.S)
    frame_extra = {}
    fm = re.search(r"const FRAMES: Dictionary = \{(.*?)\n\}", omni, re.S)
    if fm:
        for entry in re.split(r'\n\t"', fm.group(1))[1:]:
            fid = entry.split('"', 1)[0]
            frame_extra[fid] = {
                "desc": (re.search(r'"description": "([^"]*)"', entry) or [None, ""])[1],
                "passive": (re.search(r'"passive": "([^"]*)"', entry) or [None, ""])[1],
                "best": (re.search(r'"best_for": "([^"]*)"', entry) or [None, ""])[1],
            }
    if blk:
        for fid, fname, ftype, frole in re.findall(
                r'\{id="(\w+)", name="([^"]*)", type="(\w+)", role="([^"]*)"\}', blk.group(1)):
            x = frame_extra.get(fid, {})
            entries.append({
                "kind": "frame", "id": fid, "name": fname,
                "art": "frame_" + fid if "frame_" + fid in have else "",
                "faction": "", "sub": "%s · %s" % (ftype, frole),
                "fields": {"Passive": x.get("passive", ""), "Best for": x.get("best", "")},
                "text": x.get("desc", ""),
            })

    # --- morph rigs ---
    rigs = read("godot/src/data/morph_rig_data.gd")
    for mid, mname in re.findall(r'\{id="(\w+)", name="([^"]*)"', rigs):
        seg = re.search(r'id="%s".*?\}' % mid, rigs, re.S)
        seg = seg.group(0) if seg else ""
        g = lambda k: (re.search(r'%s="([^"]*)"' % k, seg) or [None, ""])[1]
        entries.append({
            "kind": "mod", "id": mid, "name": mname,
            "art": "morph_" + mid if "morph_" + mid in have else "",
            "faction": "", "sub": g("bonus"),
            "fields": {"Bonus": g("bonus"), "Drawback": g("drawback")},
            "text": g("desc"),
        })

    # --- entities: the authored prompt set carries the full descriptions ---
    csv_path = os.path.join(REPO, "godot", "data", "entity_image_prompts",
                            "all_600_entities.csv")
    dex = {}
    src = read("godot/src/data/entity_dex_data.gd")
    for block in re.split(r"\n\s*\{id=", src)[1:]:
        mm = re.match(r'"([A-Z0-9\-]+)"', block)
        if mm:
            dex[mm.group(1)] = {
                "faction": (re.search(r'faction="(\w+)"', block) or [None, ""])[1],
                "category": (re.search(r'category="(\w+)"', block) or [None, ""])[1],
                "role": (re.search(r'role="(\w+)"', block) or [None, ""])[1],
            }
    if os.path.exists(csv_path):
        with open(csv_path, newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                eid, stage = row["entity_id"], max(int(row.get("stage", 1)) - 1, 0)
                key = eid.lower() if stage == 0 else "%s_s%d" % (eid.lower(), stage)
                meta = dex.get(eid, {})
                body = row["prompt"]
                cut = body.find("3/4 view.")
                if cut > 0:
                    body = body[cut + 9:]
                entries.append({
                    "kind": "entity", "id": key, "name": row.get("stage_name", eid),
                    "art": key if key in have else "",
                    "faction": meta.get("faction", ""),
                    "sub": " · ".join(filter(None, [
                        eid, meta.get("category", ""), meta.get("role", ""),
                        "stage %d" % (stage + 1)])),
                    "fields": {},
                    "text": body.strip()[:900],
                })
    return entries


def build():
    entries = collect()
    os.makedirs(OUT, exist_ok=True)

    # Copy art next to the page so index.html is self-contained as a folder.
    art_out = os.path.join(OUT, "art")
    os.makedirs(art_out, exist_ok=True)
    copied = 0
    if os.path.isdir(ART):
        for f in os.listdir(ART):
            if f.lower().endswith((".png", ".jpg")):
                dst = os.path.join(art_out, f)
                if not os.path.exists(dst) or os.path.getsize(dst) != os.path.getsize(
                        os.path.join(ART, f)):
                    shutil.copy(os.path.join(ART, f), dst)
                copied += 1

    payload = json.dumps(entries, ensure_ascii=False)
    counts = {}
    for e in entries:
        counts[e["kind"]] = counts.get(e["kind"], 0) + 1
    with_art = sum(1 for e in entries if e["art"])

    page = TEMPLATE.replace("__DATA__", payload) \
                   .replace("__COUNTS__", html.escape(
                       " · ".join("%d %s" % (v, k) for k, v in sorted(counts.items())))) \
                   .replace("__ART__", "%d of %d illustrated" % (with_art, len(entries)))
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as fh:
        fh.write(page)

    print("%d entries (%s), %d images -> %s/index.html"
          % (len(entries), ", ".join("%d %s" % (v, k) for k, v in sorted(counts.items())),
             copied, OUT))


TEMPLATE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Master Omni Dex</title>
<style>
  :root{--bg:#0c0c10;--panel:#15151c;--rule:#26262f;--ink:#c9c7d3;--dim:#7e7b8c;
        --bright:#eceaf3;--accent:#57d3de;
        --mono:ui-monospace,"SF Mono",Menlo,Consolas,monospace;}
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--ink);
       font:15px/1.6 system-ui,-apple-system,"Segoe UI",sans-serif}
  header{position:sticky;top:0;z-index:5;background:rgba(12,12,16,.96);
         backdrop-filter:blur(8px);border-bottom:1px solid var(--rule);padding:14px 20px}
  h1{font-family:var(--mono);font-size:19px;margin:0 0 4px;color:var(--bright);
     letter-spacing:-.01em}
  .meta{font-family:var(--mono);font-size:11px;color:var(--dim)}
  .bar{display:flex;gap:8px;flex-wrap:wrap;margin-top:11px;align-items:center}
  input{flex:1;min-width:180px;background:var(--panel);border:1px solid var(--rule);
        color:var(--ink);padding:8px 11px;border-radius:5px;font-size:14px}
  button{background:var(--panel);border:1px solid var(--rule);color:var(--dim);
         padding:7px 13px;border-radius:5px;cursor:pointer;font-family:var(--mono);
         font-size:11px;letter-spacing:.1em;text-transform:uppercase}
  button.on{color:var(--accent);border-color:var(--accent)}
  button:focus-visible,input:focus-visible{outline:2px solid var(--accent);outline-offset:2px}
  #grid{display:grid;gap:12px;padding:20px;
        grid-template-columns:repeat(auto-fill,minmax(190px,1fr))}
  .card{background:var(--panel);border:1px solid var(--rule);border-radius:7px;
        overflow:hidden;cursor:pointer;transition:border-color .12s,transform .12s}
  .card:hover{border-color:var(--accent);transform:translateY(-2px)}
  .thumb{aspect-ratio:1;background:#0a0a0e;display:flex;align-items:center;
         justify-content:center;overflow:hidden}
  .thumb img{width:100%;height:100%;object-fit:cover;display:block}
  .none{font-family:var(--mono);font-size:10px;color:#44424e;letter-spacing:.1em}
  .cap{padding:8px 10px}
  .cap b{display:block;color:var(--bright);font-size:13.5px;font-weight:600;
         white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  .cap span{font-family:var(--mono);font-size:10px;color:var(--dim);
            display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
  dialog{background:var(--panel);color:var(--ink);border:1px solid var(--rule);
         border-radius:10px;max-width:760px;width:calc(100% - 32px);padding:0}
  dialog::backdrop{background:rgba(0,0,0,.78)}
  .dlg{display:grid;grid-template-columns:300px 1fr;gap:0}
  .dlg img{width:100%;height:100%;object-fit:cover;display:block}
  .dlg .body{padding:20px}
  .dlg h2{font-family:var(--mono);margin:0 0 3px;font-size:20px;color:var(--bright)}
  .dlg .sub{font-family:var(--mono);font-size:11px;color:var(--accent);margin-bottom:14px}
  .dlg dt{font-family:var(--mono);font-size:10px;letter-spacing:.11em;
          text-transform:uppercase;color:var(--dim);margin-top:11px}
  .dlg dd{margin:2px 0 0}
  .dlg p{font-size:13.5px;color:var(--ink);margin:14px 0 0}
  .close{position:absolute;top:10px;right:14px;background:none;border:none;
         color:var(--dim);font-size:22px;padding:4px 8px}
  @media(max-width:620px){.dlg{grid-template-columns:1fr}}
</style></head><body>
<header>
  <h1>MASTER OMNI DEX</h1>
  <div class="meta">__COUNTS__ · __ART__</div>
  <div class="bar">
    <input id="q" placeholder="Search name, id, faction, lore…" autocomplete="off">
    <button data-k="all" class="on">All</button>
    <button data-k="race">Races</button>
    <button data-k="frame">Frames</button>
    <button data-k="mod">Mods</button>
    <button data-k="entity">Entities</button>
    <button id="artonly">Illustrated</button>
  </div>
</header>
<div id="grid"></div>
<dialog id="dlg"><button class="close" onclick="dlg.close()">&times;</button>
  <div class="dlg" id="dlgin"></div></dialog>
<script>
const DATA = __DATA__;
const grid = document.getElementById('grid'), q = document.getElementById('q');
let kind = 'all', artOnly = false;
const esc = s => (s||'').replace(/[&<>"]/g, c =>
  ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));

function shown(){
  const t = q.value.trim().toLowerCase();
  return DATA.filter(e =>
    (kind === 'all' || e.kind === kind) &&
    (!artOnly || e.art) &&
    (!t || (e.name+' '+e.id+' '+e.faction+' '+e.sub+' '+e.text).toLowerCase().includes(t)));
}
function render(){
  const rows = shown();
  grid.innerHTML = rows.map((e,i) => `
    <div class="card" data-i="${DATA.indexOf(e)}">
      <div class="thumb">${e.art
        ? `<img loading="lazy" src="art/${esc(e.art)}.png" alt="${esc(e.name)}">`
        : '<span class="none">NO ART YET</span>'}</div>
      <div class="cap"><b>${esc(e.name)}</b><span>${esc(e.sub||e.kind)}</span></div>
    </div>`).join('') ||
    '<p style="color:var(--dim);font-family:var(--mono)">nothing matches</p>';
}
grid.addEventListener('click', ev => {
  const c = ev.target.closest('.card'); if (!c) return;
  const e = DATA[+c.dataset.i];
  document.getElementById('dlgin').innerHTML = `
    ${e.art ? `<img src="art/${esc(e.art)}.png" alt="${esc(e.name)}">`
            : '<div class="thumb"><span class="none">NO ART YET</span></div>'}
    <div class="body"><h2>${esc(e.name)}</h2>
      <div class="sub">${esc(e.sub || e.kind)}${e.faction ? ' · '+esc(e.faction) : ''}</div>
      <dl>${Object.entries(e.fields||{}).filter(([,v])=>v)
        .map(([k,v])=>`<dt>${esc(k)}</dt><dd>${esc(v)}</dd>`).join('')}</dl>
      <p>${esc(e.text)}</p></div>`;
  document.getElementById('dlg').showModal();
});
document.querySelectorAll('button[data-k]').forEach(b => b.onclick = () => {
  document.querySelectorAll('button[data-k]').forEach(x => x.classList.remove('on'));
  b.classList.add('on'); kind = b.dataset.k; render();
});
document.getElementById('artonly').onclick = ev => {
  artOnly = !artOnly; ev.target.classList.toggle('on', artOnly); render();
};
q.oninput = render;
render();
</script></body></html>
"""

if __name__ == "__main__":
    build()
