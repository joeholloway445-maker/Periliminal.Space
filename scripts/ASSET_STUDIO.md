# Asset Studio — make your own, own the whole pipeline

Everything used to build this project's art lives in `scripts/`. No paid
service, no account, no vendor lock-in: the generators are keyless, the
sourced packs are CC0, and every step is a script you run yourself. This is
the map.

## The three layers of a character

1. **Generated gallery** — a range of ready-made looks per race, so a new
   player starts by *picking* rather than building from zero.
2. **Frames & mods** — gear and body layered on the chosen look.
3. **PeriHuman deep-edit** — for players who want every detail: the
   parametric `HumanDNA` system (`godot/src/perihuman/`) exposes each gene
   (build, jaw, cheekbone, eye size/spacing, skin melanin/redness, age,
   markings…) as a slider. The gallery pick seeds the genome; from there a
   player refines to the minute detail. That two-tier model — quick-start
   gallery, then unlimited refinement — is the answer to "broad range to
   start, deep customization if they want."

## Tools, in the order you'd use them

### Sourced CC0 packs (models, textures, skies)

| Script | Pulls | From |
|---|---|---|
| `fetch_polyhaven_models.py` | photoscanned props + HDRI skies, packed to self-contained GLBs | Poly Haven (CC0) |
| `fetch_polyhaven_textures.sh` | PBR maps per material slot (`RES=2k` for desktop) | Poly Haven (CC0) |
| `fetch_kenney_packs.sh` | any Kenney pack by slug, scrapes the real zip URL | kenney.nl (CC0) |
| `deploy_kenney_characters.py` | embeds Kenney's external atlas into each GLB | — |
| `fetch_osm_cities.py` | real street layouts for the mega-city | OpenStreetMap |

All land under `godot/assets/`. Re-runnable; existing files are skipped.

### Generated art (races, entities, frames, mods)

The pipeline is three steps — compose prompts, run them, view the result:

```bash
# 1. compose a job list. Subjects come from the game's own data
#    (20 races, 600 entity stages, 20 frames, 20 morph rigs). Axes:
#    --sexes male,female   --variants all   --frames all   --morphs all
python3 scripts/prompt_templates.py --matrix --kind race \
    --variants all --sexes male,female --out build/gallery.jsonl

# 2. generate. Keyless via Pollinations (default), or --provider
#    replicate/tripo/meshy with a key. --workers N for parallelism.
python3 scripts/generate_assets.py --jobs build/gallery.jsonl --workers 16

# 3. finish stragglers the image service throttled (retries, skips done)
bash scripts/finish_generation.sh build/gallery.jsonl 16
```

Prompt composition (`prompt_templates.py`) is where the look is controlled:

- **Style** — `LOCKED_PREAMBLE` + `STYLE_BIBLE.md` (photoreal dark-fantasy).
- **Variety** — `VARIANTS`: eight distinct individuals per race so a gallery
  is many people, not one recoloured body. Edit the descriptors to taste.
- **Range** — `ASPECTS` (noble / fearsome / grotesque) spreads the roster so
  it is not all one mood; `SEXES` describes male/female build explicitly.
- **Places** — `LOCATIONS` (the six reality layers + hubs) for `--mode scene`
  key art and lingbot-world inputs; `--mode sprite` ignores location for
  clean cutout.
- **Anatomy** — `NEGATIVE` names the failure modes individually (extra
  fingers, backwards joints…) so bodies come back usable.

### Wiring & review

| Script | Does |
|---|---|
| `build_omnidex_viewer.py` | one offline HTML page to click through every race/frame/mod/entity with its art |
| `render_model_sheet.py` | PNG thumbnails of any GLB, to eyeball before wiring |
| `export_asset_prompts.py` | one job per still-missing asset slot |
| `install_addons.sh` | the web-safe Godot addons the project uses |

In-engine, `IdentityArt.gd` resolves a build to its closest generated sprite
(falling back race+sex+frame+mod → … → race), so the creator fills in as art
is generated rather than needing the whole set first.

## Providers (generate_assets.py)

| Provider | Cost | Notes |
|---|---|---|
| `pollinations` *(default)* | free, keyless | the whole set was built on this |
| `replicate` | ~$0.05–0.20/img | `REPLICATE_API_TOKEN`, any model via `REPLICATE_MODEL` |
| `tripo` / `meshy` | credits | text-to-**3D**, for actual meshes |

Same job files run against any of them — swap `--provider` if you ever want
a specific model or a licence cleaner than Pollinations' routed output.

## Owning it

Nothing here depends on this repo. Copy `scripts/` and the `godot/data/
entity_image_prompts/` briefs into any project and the pipeline runs. The
only external services are Poly Haven / Kenney (CC0 downloads) and
Pollinations (keyless generation) — both free, neither gated.
