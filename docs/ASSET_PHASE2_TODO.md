# Phase 2 Asset Sourcing — Blockers & Next Steps

## ✅ COMPLETED (Just pushed)
- **30 Kenney casino audio** (cards, chips, dice SFX) → `godot/assets/audio/`
- **3 shader overlays** (CRT, VHS, dither) → `godot/assets/shaders/`
- **3 sample PBR textures** (metal, brick via GitHub) → `godot/assets/textures/`
- **18 hard-mesh models** (Kenney city/nature) from Phase 1

## ❌ BLOCKED (External access issues)

### Textures (PBR for realistic cities)
**Issue:** External texture pack URLs (Polyhaven, OpenGameArt, ambientCG) are redirecting or require auth.

**Solutions for next push:**
1. **Manual asset pack download** — Download locally, extract, commit .zip contents:
   - OpenGameArt urban pack: https://opengameart.org/content/free-urban-textures-buildings-apartments-shop-fronts
   - Free PBR.com direct downloads (no auth): https://www.freepbr.com/c/base-metals/
   - ambientCG API workaround (may require registration): https://ambientcg.com/

2. **Procedural + tint system** (already in code):
   - AssetLibrary.material(slot) uses IdentityLens.world_material() to tint ALL meshes per race
   - Slot-based texture override: if `facade_glass_albedo.png` exists, use it; else use base color
   - This means realistic textures enhance detail on top of race lens (no texture = race color shines)

### Humanoid Models (cat/civilian characters)
**Issue:** 
- Quaternius packs are on Google Drive (requires manual download)
- GitHub TPS-demo is behind redirect/auth
- Itch.io download URLs redirect to Google Drive

**Solutions for next push:**
1. **Quaternius (CC0, rigged, animated)** — Manual download:
   - Ultimate Animated Animals: https://quaternius.itch.io/ultimate-animated-animals
   - Civilian Characters: https://quaternius.itch.io/civiliancharacters
   - Low Poly Humans: https://quaternius.itch.io/lowpolyhumans
   - Download → extract GLBs → deploy as `player_cat.glb`, `npc_human_variant.glb`, etc.

2. **Alternative free sources:**
   - Sketchfab "Free" filter (CC0/CC-BY): https://sketchfab.com/search?q=humanoid&license=c0
   - MixamoLike free rigs (search "free rigged character")
   - Artstation free models section

### Audio (Reality layer ambience + city sounds)
**Issue:** Sonniss GDC 2026 is large (7.47GB); Freesound requires account.

**Solutions:**
1. **Sonniss (Royalty-free, no attribution required):**
   - GDC 2026 direct: https://gdc.sonniss.com/ (download locally)
   - Pick samples: traffic hum, crowd murmur, neon buzz, machine drone for city layers

2. **Freesound.org (CC0, requires account):**
   - City Ambience: https://freesound.org/people/felix.blume/sounds/705049/
   - Slot Machine sounds: https://freesound.org/people/lukaso/packs/4497/
   - Crowd/pedestrian: https://freesound.org/people/OGsoundFX/sounds/423007/

## 📋 ROADMAP FOR PHASE 3

### A. **Texture Coverage (Race × Frame × Mod Visual Variety)**
- Deploy 50+ PBR maps (metal, concrete, brick, glass, asphalt, neon, fabric)
- Map to slots: `facade_*_albedo.png`, `facade_*_normal.png`, `facade_*_roughness.png`, etc.
- Test with AssetLibrary.material() to verify race lens tints on top

### B. **Humanoid Model Set (20 races concept)**
- At minimum: 3–5 distinct character rigs (cat, human, crystalline, void, biotech phenotypes)
- Deploy to `godot/assets/models/` as `character_<race>.glb`
- Wire into HumanIdentity / IdentityLens for per-race appearance

### C. **City Ambience Layers (Reality × District)**
- Create audio slots: `city_traffic_liminal.ogg`, `city_crowd_periliminal.ogg`, etc.
- Per-district packs: Dallas (urban tech), Fort Worth (industrial), Denton (rural), Arlington (commercial)
- Wire into CityAmbience.gd to pick by district + reality layer

### D. **Shader Variations (Frame Sensorium Visual)**
- 20 frame color grades / fog settings
- Procedural tone mapping per frame (Bolt: oversaturated, Behemoth: desaturated, etc.)
- Modulate on top of race lens in IdentityLens.tune_sky()

### E. **Mod Visual Feedback**
- Stat-based particle effects (spd = speed lines, pow = red glow, res = armor plating, lck = sparkle)
- Shader tint variations (mod_strength_scale in blueprint_mesh.gd)

## 🎯 NEXT IMMEDIATE STEP
1. **Manual asset pack downloads** (download locally if behind auth)
2. **Extract + commit** texture + audio files
3. **Update ATTRIBUTION.md** with all new sources + licenses
4. **Wire AssetLibrary slots** for textures (already coded, just needs files)
5. **Create per-race character model stubs** (skeleton GLBs or mesh placeholders)

---

**Estimated completion:** 3-4 hours of manual sourcing + 1-2 hours integration.
**ROI:** Realistic city visuals, diverse humanoid appearances, fully spatialized audio.
