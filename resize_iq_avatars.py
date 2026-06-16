import sys, os
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image

NAMES = ['iq_dahi','iq_ustun','iq_cokzeki','iq_ort_ustu',
         'iq_ortalama','iq_ort_alti','iq_sinirda','iq_dusuk']
DIR = r"C:\src\snapiq\assets\iq_avatars"

for name in NAMES:
    path = os.path.join(DIR, f"{name}.png")
    img = Image.open(path)
    w, h = img.size
    img_resized = img.resize((400, 400), Image.LANCZOS)
    img_resized.save(path, "PNG", optimize=True)
    sz = round(os.path.getsize(path)/1024)
    print(f"{name}: {w}x{h} -> 400x400  {sz} KB")
