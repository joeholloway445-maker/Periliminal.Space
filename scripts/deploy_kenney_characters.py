#!/usr/bin/env python3
"""Deploy Kenney CC0 humanoids into godot/assets/models/.

Kenney GLBs reference their atlas as an external `Textures/colormap.png`, so
copying them verbatim yields untextured bodies in Godot. Each is re-packed
with the atlas embedded as a data URI, exactly like the city/nature models.

Two destinations, deliberately:

  npc_human_a … npc_human_l   the 12 mini-characters, wired as the crowd
                              variant set AssetLibrary.instance_variant()
                              reads for anonymous citizens
  kenney_characters/          the 18 blocky characters, kept as a browsable
                              library to assign to slots later

Run after scripts/fetch_kenney_packs.sh has populated /tmp/kenney_packs.
"""

import os
import shutil
import string
import sys
import tempfile

from pygltflib import GLTF2, ImageFormat

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS = os.path.join(REPO, "godot", "assets", "models")
LIBRARY = os.path.join(MODELS, "kenney_characters")
PACKS = os.environ.get("WORK", "/tmp/kenney_packs")


def find_glb(pack, name):
    for root, _dirs, files in os.walk(os.path.join(PACKS, pack)):
        if name in files:
            return os.path.join(root, name)
    return None


def pack_embedded(src, dest):
    """Copy `src` to `dest` with its external textures inlined as data URIs."""
    with tempfile.TemporaryDirectory() as tmp:
        # convert_images resolves relative image URIs against `path`, so the
        # source's own directory has to be what it searches.
        staged = os.path.join(tmp, os.path.basename(src))
        shutil.copy(src, staged)
        src_dir = os.path.dirname(src)
        gltf = GLTF2().load(staged)
        if any(img.uri and not img.uri.startswith("data:") for img in gltf.images):
            gltf.convert_images(ImageFormat.DATAURI, path=src_dir)
        gltf.save_binary(dest)

    with open(dest, "rb") as fh:
        if fh.read(4) != b"glTF":
            os.remove(dest)
            return False
    return True


def main():
    os.makedirs(LIBRARY, exist_ok=True)

    minis = [f"character-{sex}-{ch}.glb"
             for sex in ("female", "male")
             for ch in "abcdef"]
    blocky = [f"character-{ch}.glb" for ch in string.ascii_lowercase[:18]]

    ok = missing = 0

    for slot_letter, name in zip(string.ascii_lowercase, minis):
        src = find_glb("mini-characters", name)
        if src is None:
            print(f"!! mini-characters/{name}: not found")
            missing += 1
            continue
        dest = os.path.join(MODELS, f"npc_human_{slot_letter}.glb")
        if pack_embedded(src, dest):
            print(f"   npc_human_{slot_letter}.glb  <- {name} "
                  f"({os.path.getsize(dest) / 1e6:.2f} MB)")
            ok += 1
        else:
            print(f"!! {name}: bad glb after packing")
            missing += 1

    for name in blocky:
        src = find_glb("blocky-characters", name)
        if src is None:
            print(f"!! blocky-characters/{name}: not found")
            missing += 1
            continue
        dest = os.path.join(LIBRARY, name.replace("character-", "blocky-"))
        if pack_embedded(src, dest):
            ok += 1
        else:
            print(f"!! {name}: bad glb after packing")
            missing += 1

    print(f"\n{ok} deployed, {missing} missing")
    print(f"crowd variants: {MODELS}/npc_human_*.glb")
    print(f"library:        {LIBRARY}/")


if __name__ == "__main__":
    sys.exit(main())
