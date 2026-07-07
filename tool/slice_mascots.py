#!/usr/bin/env python3
"""Slice assets/icons.png into individual transparent-PNG mascots.

Strategy: the source PNG is RGBA where alpha==0 marks true background.
Icon pixels are grouped into 8-connected components (whole strokes/blobs),
and each component is assigned to the icon whose seed centroid is nearest
to the component's own centroid.  Assigning whole components (rather than
individual pixels) keeps far-flung parts of an icon — e.g. the sun's outer
ray tips — with their owner instead of letting a neighbouring seed steal
them along a straight Voronoi boundary.
"""
from PIL import Image
import numpy as np
from scipy import ndimage
import os

SRC = "assets/icons.png"
OUT = "assets/mascots"
PAD      = 0.06  # fractional padding around each tight crop
MIN_AREA = 400   # px² — below this a component is a detached accent (e.g. the
                 # whale's spout ticks) and inherits the owner of the nearest
                 # large component instead of trusting its own centroid

# ── Manual icon regions (x1,y1,x2,y2 in 2048×2048 coords) ──────────────
# Generous rectangles; tightened to actual mask pixels, then padded.
REGIONS = {
    "potted_plant":   (  0,   0,  600,  490),   # extended to catch all leaves
    "sun":            (475, 140,  985,  590),
    "berry_pot":      (975,  45, 1510,  515),
    "big_star":       (1460, 260, 1790,  620),
    "sparkle_DEL":    ( 130, 540,  300,  730),
    "small_star1_DEL":(1730, 160, 1920,  350),
    "small_star2_DEL":(1790, 410, 1985,  610),
    "sad_flower":     (1010, 545, 1270,  985),
    "teacup":         ( 490, 880,  980, 1160),
    "butterfly":      (1310, 710, 1770, 1065),
    "notebook":       ( 150,1040,  575, 1475),
    "fish":           ( 900,1150, 1365, 1425),
    "small_flower":   (1410,1195, 1670, 1450),
    "sprout":         (1700,1095, 2020, 1475),
    "sleepy_cloud":   (  10,1530,  475, 1830),
    "cat":            ( 465,1460,  960, 2040),
    "raining_cloud":  (1030,1440, 1465, 2035),
    "snail":          (1470,1600, 1900, 1985),
}

# ── Seed centroids for Voronoi disambiguation ────────────────────────────
# (cx, cy) hand-picked from the main component of each icon.
SEEDS = {
    "potted_plant":   ( 328,  332),
    "sun":            ( 730,  413),
    "berry_pot":      (1250,  390),
    "big_star":       (1631,  447),
    "sparkle_DEL":    ( 211,  645),
    "small_star1_DEL":(1826,  253),
    "small_star2_DEL":(1888,  515),
    "sad_flower":     (1162,  765),
    "teacup":         ( 707, 1033),
    "butterfly":      (1541,  889),
    "notebook":       ( 300, 1286),
    "fish":           (1139, 1288),
    "small_flower":   (1553, 1323),
    "sprout":         (1859, 1290),
    "sleepy_cloud":   ( 244, 1680),
    "cat":            ( 717, 1750),
    "raining_cloud":  (1248, 1734),
    "snail":          (1679, 1781),
}

# Pre-compute seed arrays for fast distance calculation
seed_names  = list(SEEDS.keys())
seed_cx = np.array([SEEDS[n][0] for n in seed_names], dtype=float)
seed_cy = np.array([SEEDS[n][1] for n in seed_names], dtype=float)

def nearest_seed(px_x, px_y):
    """Return the name of the nearest seed for pixel at (px_x, px_y)."""
    dx = seed_cx - px_x
    dy = seed_cy - px_y
    dists = dx*dx + dy*dy
    return seed_names[int(np.argmin(dists))]

im = Image.open(SRC).convert("RGBA")
a  = np.asarray(im)          # shape (H, W, 4), dtype uint8
H, W = a.shape[:2]

# Background is wherever the source alpha channel is 0.
bg        = (a[:, :, 3] == 0)
rgba_full = a.copy()
mask      = ~bg              # True where icon pixels live

# ── Component-based ownership map ────────────────────────────────────────
# Label 8-connected components of icon pixels, then assign each whole
# component to the seed nearest its centroid.
print("Computing component ownership …", flush=True)
labels, n_comp = ndimage.label(mask, structure=np.ones((3, 3), dtype=int))
centroids = ndimage.center_of_mass(mask, labels, range(1, n_comp + 1))
sizes = ndimage.sum(mask, labels, range(1, n_comp + 1))
comp_owner = np.empty(n_comp + 1, dtype=np.int16)
comp_owner[0] = -1  # background label
small_ids = []
for comp_id, (cy, cx) in enumerate(centroids, start=1):
    if sizes[comp_id - 1] < MIN_AREA:
        small_ids.append(comp_id)
        continue
    dx = seed_cx - cx
    dy = seed_cy - cy
    comp_owner[comp_id] = int(np.argmin(dx * dx + dy * dy))

# Small detached accents: inherit the owner of the nearest large-component
# pixel (their own centroid can sit closer to a neighbouring icon's seed).
if small_ids:
    big_mask = mask & ~np.isin(labels, small_ids)
    _, (near_y, near_x) = ndimage.distance_transform_edt(
        ~big_mask, return_indices=True)
    for comp_id in small_ids:
        cy, cx = (int(round(v)) for v in centroids[comp_id - 1])
        comp_owner[comp_id] = comp_owner[labels[near_y[cy, cx], near_x[cy, cx]]]

# ownership array: -1 = background, >=0 = seed index
ownership = comp_owner[labels]
print(f"Done – {n_comp} components.", flush=True)

# ── Crop each region ────────────────────────────────────────────────────
os.makedirs(OUT, exist_ok=True)
for name, (rx1, ry1, rx2, ry2) in REGIONS.items():
    if name.endswith("_DEL"):
        continue
    my_seed_idx = seed_names.index(name)
    # Tight bbox over ALL pixels owned by this icon (components may extend
    # past the manual region rectangle, e.g. the sun's outer ray tips).
    ys, xs = np.where(ownership == my_seed_idx)
    if len(xs) == 0:
        print(f"  WARNING: no owned pixels for {name} – skipping")
        continue
    fx1, fy1 = int(xs.min()), int(ys.min())
    fx2, fy2 = int(xs.max()), int(ys.max())
    pw = int((fx2 - fx1) * PAD)
    ph = int((fy2 - fy1) * PAD)
    cx1 = max(0,  fx1 - pw)
    cy1 = max(0,  fy1 - ph)
    cx2 = min(W,  fx2 + pw)
    cy2 = min(H,  fy2 + ph)
    # Build the RGBA crop: use Voronoi ownership to zero out non-owned pixels
    crop = rgba_full[cy1:cy2, cx1:cx2].copy()
    own_crop = ownership[cy1:cy2, cx1:cx2]
    # Zero alpha for any pixel not owned by this icon
    crop[own_crop != my_seed_idx, 3] = 0
    Image.fromarray(crop, "RGBA").save(f"{OUT}/{name}.png")
    print(f"{name:24s}  tight=({fx1},{fy1},{fx2},{fy2}) size={fx2-fx1}x{fy2-fy1}")
kept = sum(1 for n in REGIONS if not n.endswith("_DEL"))
print(f"Done – {kept} slices written.")
