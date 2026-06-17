# Regenerate ALL app icons + launch logos from snapiqtamkare.png
from PIL import Image
import os

SRC = r"C:\Users\AG\Desktop\snapiqtamkare.png"
src = Image.open(SRC).convert("RGB")
print("source:", src.size, src.mode)

def save(img, path, size, rgb_no_alpha=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    if rgb_no_alpha:
        out = out.convert("RGB")
    out.save(path, "PNG")
    print("  wrote", os.path.relpath(path, r"C:\src\snapiq"), size)

# ── iOS AppIcon.appiconset ────────────────────────────────────────────────
ios = r"C:\src\snapiq\ios\Runner\Assets.xcassets\AppIcon.appiconset"
ios_icons = {
    "Icon-App-20x20@1x.png": 20,  "Icon-App-20x20@2x.png": 40,  "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,  "Icon-App-29x29@2x.png": 58,  "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,  "Icon-App-40x40@2x.png": 80,  "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120, "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,  "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,  # marketing, must be RGB no-alpha
}
print("iOS app icons:")
for name, sz in ios_icons.items():
    save(src, os.path.join(ios, name), sz)

# ── Android mipmaps (legacy ic_launcher) ──────────────────────────────────
android_res = r"C:\src\snapiq\android\app\src\main\res"
android_icons = {
    "mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192,
}
print("Android app icons:")
for folder, sz in android_icons.items():
    save(src, os.path.join(android_res, folder, "ic_launcher.png"), sz)

# ── Splash / launch logos (brand consistency, no leftover old art) ────────
print("Launch logos:")
save(src, os.path.join(android_res, "drawable", "launch_logo.png"), 480)
ios_launch = r"C:\src\snapiq\ios\Runner\Assets.xcassets\LaunchImage.imageset"
save(src, os.path.join(ios_launch, "LaunchImage.png"), 256)
save(src, os.path.join(ios_launch, "LaunchImage@2x.png"), 512)
save(src, os.path.join(ios_launch, "LaunchImage@3x.png"), 768)

# ── Play Store listing icon (512x512) ─────────────────────────────────────
play = r"C:\Users\AG\Desktop\snapiq_play_icon_512.png"
save(src, play, 512)

print("DONE")
