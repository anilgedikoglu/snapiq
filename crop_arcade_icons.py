import sys
import os
from PIL import Image

GAME_IDS = [
    "color_panic", "tap_target", "dont_tap_red", "number_hunter", "memory_flash",
    "shape_strike", "speed_math", "mirror_brain", "sequence_rush", "reaction_wall",
    "focus_hunter", "impulse_control", "tap_rain", "brain_duel", "pattern_master",
]

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "arcade_icons")
COLS, ROWS = 5, 3

def crop_icons(src_path):
    img = Image.open(src_path).convert("RGBA")
    W, H = img.size
    print(f"Image size: {W}x{H}")
    cell_w = W / COLS
    cell_h = H / ROWS
    icon_h_ratio = 0.72
    os.makedirs(OUT_DIR, exist_ok=True)
    for idx, game_id in enumerate(GAME_IDS):
        row = idx // COLS
        col = idx % COLS
        x0 = col * cell_w
        y0 = row * cell_h
        x1 = x0 + cell_w
        y1 = y0 + cell_h * icon_h_ratio
        pad = cell_w * 0.025
        box = (int(x0 + pad), int(y0 + pad), int(x1 - pad), int(y1 - pad))
        cropped = img.crop(box).resize((256, 256), Image.LANCZOS)
        out_path = os.path.join(OUT_DIR, f"{game_id}.png")
        cropped.save(out_path, "PNG")
        print(f"  [{idx+1:2d}] {game_id}.png")
    print(f"\nDone — {len(GAME_IDS)} icons saved to {OUT_DIR}")

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "arcade_icons_source.png"
    crop_icons(src)
