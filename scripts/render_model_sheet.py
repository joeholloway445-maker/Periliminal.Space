#!/usr/bin/env python3
"""Render GLB models to PNG thumbnails for review.

There is no GPU (and no Godot binary) in this environment, so this is a small
software rasteriser: load with trimesh, bake any texture down to vertex
colours, project a three-quarter view, and z-buffer the triangles with a
simple key/fill lambert shade. Enough to see silhouette, proportion, and
palette — which is what a "show me the models" pass is actually for.

    python3 scripts/render_model_sheet.py out_dir model.glb [more.glb ...]
"""

import os
import sys

import numpy as np
import trimesh
from PIL import Image

SIZE = 384
BG = np.array([18, 18, 22], dtype=np.float32)
KEY_DIR = np.array([-0.4, 0.7, 0.9], dtype=np.float32)
FILL_DIR = np.array([0.6, 0.1, -0.5], dtype=np.float32)


def load_mesh(path):
    """A single Trimesh with per-vertex colours, or None."""
    obj = trimesh.load(path, force="scene", process=False)
    meshes = []
    for name, geom in obj.geometry.items():
        if not isinstance(geom, trimesh.Trimesh) or geom.faces.shape[0] == 0:
            continue
        g = geom.copy()
        # Bake texture/material down to vertex colours so the rasteriser only
        # has to deal with one colour source.
        try:
            g.visual = g.visual.to_color()
        except Exception:
            pass
        for node in obj.graph.nodes_geometry:
            tf, gname = obj.graph[node]
            if gname == name:
                g.apply_transform(tf)
                break
        meshes.append(g)
    if not meshes:
        return None
    return trimesh.util.concatenate(meshes)


def vertex_colors(mesh):
    n = len(mesh.vertices)
    try:
        vc = np.asarray(mesh.visual.vertex_colors, dtype=np.float32)
        if vc.shape[0] == n and vc[:, :3].max() > 0:
            return vc[:, :3]
    except Exception:
        pass
    return np.full((n, 3), 190.0, dtype=np.float32)


def render(path, size=SIZE):
    mesh = load_mesh(path)
    if mesh is None:
        return None

    v = np.asarray(mesh.vertices, dtype=np.float64).copy()
    f = np.asarray(mesh.faces, dtype=np.int64)
    cols = vertex_colors(mesh)

    # Centre, then a three-quarter view: yaw so the figure is not a flat
    # front elevation, small pitch so we read a little of the top planes.
    v -= (v.min(0) + v.max(0)) / 2.0
    yaw, pitch = np.radians(-32.0), np.radians(12.0)
    ry = np.array([[np.cos(yaw), 0, np.sin(yaw)],
                   [0, 1, 0],
                   [-np.sin(yaw), 0, np.cos(yaw)]])
    rx = np.array([[1, 0, 0],
                   [0, np.cos(pitch), -np.sin(pitch)],
                   [0, np.sin(pitch), np.cos(pitch)]])
    v = v @ ry.T @ rx.T

    extent = max(v.max(0) - v.min(0))
    if extent <= 0:
        return None
    scale = (size * 0.82) / extent
    xs = v[:, 0] * scale + size / 2.0
    ys = size / 2.0 - v[:, 1] * scale   # screen Y grows downward
    zs = v[:, 2] * scale

    img = np.repeat(BG[None, None, :], size, 0).repeat(size, 1)
    zbuf = np.full((size, size), -np.inf, dtype=np.float32)

    tri = np.stack([xs[f], ys[f], zs[f]], axis=-1)          # (F,3,3)
    # Face normal in view space -> lambert against a key and a fill.
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    n = np.divide(n, np.where(ln == 0, 1, ln))
    key = np.clip(n @ (KEY_DIR / np.linalg.norm(KEY_DIR)), 0, 1)
    fill = np.clip(n @ (FILL_DIR / np.linalg.norm(FILL_DIR)), 0, 1)
    shade = (0.30 + 0.62 * key + 0.22 * fill)[:, None]
    face_col = np.clip(cols[f].mean(axis=1) * shade, 0, 255)

    # Painter-ish ordering helps the z-buffer converge on thin shells.
    for i in np.argsort(tri[:, :, 2].mean(axis=1)):
        t = tri[i]
        x0 = max(int(np.floor(t[:, 0].min())), 0)
        x1 = min(int(np.ceil(t[:, 0].max())) + 1, size)
        y0 = max(int(np.floor(t[:, 1].min())), 0)
        y1 = min(int(np.ceil(t[:, 1].max())) + 1, size)
        if x1 <= x0 or y1 <= y0:
            continue

        yy, xx = np.mgrid[y0:y1, x0:x1]
        px, py = xx + 0.5, yy + 0.5
        ax, ay = t[0, 0], t[0, 1]
        bx, by = t[1, 0], t[1, 1]
        cx, cy = t[2, 0], t[2, 1]
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-9:
            continue
        w0 = ((by - cy) * (px - cx) + (cx - bx) * (py - cy)) / den
        w1 = ((cy - ay) * (px - cx) + (ax - cx) * (py - cy)) / den
        w2 = 1.0 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not inside.any():
            continue

        z = w0 * t[0, 2] + w1 * t[1, 2] + w2 * t[2, 2]
        sub = zbuf[y0:y1, x0:x1]
        win = inside & (z > sub)
        if not win.any():
            continue
        sub[win] = z[win]
        img[y0:y1, x0:x1][win] = face_col[i]

    return Image.fromarray(img.astype(np.uint8))


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    out_dir, paths = sys.argv[1], sys.argv[2:]
    os.makedirs(out_dir, exist_ok=True)
    ok = 0
    for p in paths:
        try:
            im = render(p)
        except Exception as exc:  # noqa: BLE001 - report and continue
            print(f"!! {os.path.basename(p)}: {exc}")
            continue
        if im is None:
            print(f"!! {os.path.basename(p)}: no renderable geometry")
            continue
        dest = os.path.join(out_dir, os.path.basename(p).rsplit(".", 1)[0] + ".png")
        im.save(dest)
        ok += 1
    print(f"{ok}/{len(paths)} rendered -> {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
