"""Generate the original register icon. Optional dependency: Pillow."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
s = 3
im = Image.new('RGB', (1024*s, 1024*s), '#21292b')
d = ImageDraw.Draw(im)
def rect(box, color, radius=0):
    box = tuple(int(v*s) for v in box)
    if radius: d.rounded_rectangle(box, radius=radius*s, fill=color)
    else: d.rectangle(box, fill=color)
def line(points, color, width):
    d.line([(x*s,y*s) for x,y in points], fill=color, width=width*s, joint='curve')
rect((210,420,814,768), '#ffffff', 48)
rect((260,738,764,800), '#ffffff', 24)
rect((318,222,706,456), '#ffffff', 32)
rect((348,252,676,400), '#0d6e66', 16)
line([(459,280),(512,327),(565,280)], '#ffffff', 14)
line([(512,327),(512,374)], '#ffffff', 14)
line([(462,333),(562,333)], '#ffffff', 12)
line([(462,355),(562,355)], '#ffffff', 12)
for y in [484,552]:
    for x in [274,356,438]: rect((x,y,x+54,y+42), '#21292b', 8)
rect((570,484,748,594), '#0d6e66', 14)
line([(602,540),(628,565),(714,514)], '#ffffff', 14)
rect((274,656,748,692), '#21292b', 10)
im = im.resize((1024,1024), Image.Resampling.LANCZOS)
assets=root/'KantanRegister/Assets.xcassets'
for folder, name, entry in [('AppIcon.appiconset','AppIcon.png', {'idiom':'universal','platform':'ios','size':'1024x1024'}), ('AppBrand.imageset','AppBrand.png', {'idiom':'universal'})]:
    dest=assets/folder; dest.mkdir(parents=True,exist_ok=True)
    im.save(dest/name)
    (dest/'Contents.json').write_text(json.dumps({'images':[dict(entry,filename=name)],'info':{'author':'xcode','version':1}},indent=2)+'\n')
(assets/'Contents.json').write_text('{"info":{"author":"xcode","version":1}}\n')
