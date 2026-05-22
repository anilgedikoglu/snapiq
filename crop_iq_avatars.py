from PIL import Image
import os

# 4 columns x 2 rows
# Row 1: iq_dahi(140+Einstein), iq_ustun(120-139Tesla), iq_cokzeki(110-119Hawking), iq_ort_ustu(90-109Mozart)
# Row 2: iq_ortalama(80-89glasses), iq_ort_alti(70-79green), iq_sinirda(55-69redcap), iq_dusuk(54-yellow)

NAMES = [
    'iq_dahi',
    'iq_ustun',
    'iq_cokzeki',
    'iq_ort_ustu',
    'iq_ortalama',
    'iq_ort_alti',
    'iq_sinirda',
    'iq_dusuk',
]

SRC     = r"C:\src\reflexiq_app\iq_source.png"
OUT_DIR = r"C:\src\reflexiq_app\assets\iq_avatars"
COLS, ROWS = 4, 2

os.makedirs(OUT_DIR, exist_ok=True)

img = Image.open(SRC).convert("RGBA")
W, H = img.size
print(f"Source: {W}x{H}  cell {W//COLS}x{H//ROWS}")

cell_w = W / COLS   # 384
cell_h = H / ROWS   # 512

# Per-cell padding in pixels
H_PAD  = 10   # remove 10px from left and right of each cell (black gutter)
V_PAD  = 5    # remove 5px from top of each cell
# Portrait takes roughly 72% of the cell height (rest is the text label below)
PORTRAIT_RATIO = 0.72

for idx, name in enumerate(NAMES):
    row = idx // COLS
    col = idx % COLS

    x0 = int(col * cell_w) + H_PAD
    y0 = int(row * cell_h) + V_PAD
    x1 = int((col + 1) * cell_w) - H_PAD
    y1 = int(row * cell_h) + int(cell_h * PORTRAIT_RATIO)

    # Make the crop square (use the shorter side so we don't stretch)
    crop_w = x1 - x0
    crop_h = y1 - y0
    side = min(crop_w, crop_h)
    # Centre the square within the crop area
    cx = x0 + crop_w // 2
    cy = y0 + crop_h // 2
    box = (cx - side//2, cy - side//2, cx + side//2, cy + side//2)

    cropped = img.crop(box).resize((300, 300), Image.LANCZOS)
    out = os.path.join(OUT_DIR, f"{name}.png")
    cropped.save(out, "PNG")
    print(f"  {name}.png  box={box}  {side}x{side}")

print(f"\nDone — 8 avatars saved to {OUT_DIR}")
