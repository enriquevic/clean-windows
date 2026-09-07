#!/usr/bin/env python3
# Gera CleanWindows.ico - desenho ORIGINAL (janela generica + brilho + paninho de limpeza).
# Nao usa a bandeira/logo da Microsoft. Renderiza grande (1024) e reduz p/ 256/48/32/16.
import sys, math
# Requer Pillow:  pip install pillow
try:
    from PIL import Image  # noqa
except ImportError:
    import sys as _s; _s.exit('Instale o Pillow: pip install pillow')
from PIL import Image, ImageDraw, ImageFilter

S = 1024
img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

def rrect(draw, box, r, fill):
    draw.rounded_rectangle(box, radius=r, fill=fill)

# ---- fundo: circulo com leve degrade (teal -> verde) ----
grad = Image.new('RGBA', (S, S), (0, 0, 0, 0))
gd = ImageDraw.Draw(grad)
for i in range(S):
    t = i / S
    r = int(0x0E + (0x1B - 0x0E) * t)
    g = int(0x7A + (0xB5 - 0x7A) * t)
    b = int(0x69 + (0x4D - 0x69) * t)
    gd.line([(0, i), (S, i)], fill=(r, g, b, 255))
mask = Image.new('L', (S, S), 0)
ImageDraw.Draw(mask).ellipse([40, 40, S - 40, S - 40], fill=255)
img.paste(grad, (0, 0), mask)

# sombra suave interna do circulo (profundidade)
sh = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ImageDraw.Draw(sh).ellipse([40, 40, S - 40, S - 40], outline=(0, 0, 0, 60), width=18)
img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(8)))
d = ImageDraw.Draw(img)

# ---- janela generica (NAO e a bandeira da Microsoft): moldura branca, 4 paineis ----
wx0, wy0, wx1, wy1 = 300, 288, 736, 660
# sombra da janela
shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle([wx0 + 16, wy0 + 26, wx1 + 16, wy1 + 26], radius=34, fill=(0, 0, 0, 90))
img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(22)))
d = ImageDraw.Draw(img)

rrect(d, [wx0, wy0, wx1, wy1], 34, (255, 255, 255, 255))          # moldura
inset = 34
gx0, gy0, gx1, gy1 = wx0 + inset, wy0 + inset, wx1 + inset, wy1 + inset
gx1, gy1 = wx1 - inset, wy1 - inset
rrect(d, [gx0, gy0, gx1, gy1], 14, (0x8E, 0xD8, 0xF0, 255))       # vidro azul claro
# divisorias (cruz) formando 4 paineis - janela comum, sem inclinacao/logo
cx = (gx0 + gx1) // 2
cy = (gy0 + gy1) // 2
bar = 16
d.rectangle([cx - bar // 2, gy0, cx + bar // 2, gy1], fill=(255, 255, 255, 255))
d.rectangle([gx0, cy - bar // 2, gx1, cy + bar // 2], fill=(255, 255, 255, 255))
# reflexo diagonal no vidro
gl = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ImageDraw.Draw(gl).polygon([(gx0, gy0 + 60), (gx0 + 150, gy0), (gx0 + 300, gy0),
                            (gx0, gy0 + 300)], fill=(255, 255, 255, 60))
gl2 = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ImageDraw.Draw(gl2).rectangle([gx0, gy0, gx1, gy1], fill=(255, 255, 255, 255))
img = Image.alpha_composite(img, Image.composite(gl, Image.new('RGBA', (S, S), (0, 0, 0, 0)), gl2.split()[3]))
d = ImageDraw.Draw(img)

# ---- paninho de limpeza passando na janela (retangulo girado, com dobra) ----
cloth = Image.new('RGBA', (S, S), (0, 0, 0, 0))
cd = ImageDraw.Draw(cloth)
cw, ch = 360, 250
cloth_layer = Image.new('RGBA', (cw, ch), (0, 0, 0, 0))
cl = ImageDraw.Draw(cloth_layer)
cl.rounded_rectangle([0, 0, cw, ch], radius=28, fill=(0xFF, 0xC1, 0x07, 255))   # amarelo
cl.rounded_rectangle([0, 0, cw, ch], radius=28, outline=(0xE0, 0xA0, 0x00, 255), width=8)
# costura tracejada
for xx in range(24, cw - 24, 40):
    cl.line([(xx, 22), (xx + 20, 22)], fill=(0xFF, 0xE0, 0x80, 255), width=6)
    cl.line([(xx, ch - 22), (xx + 20, ch - 22)], fill=(0xFF, 0xE0, 0x80, 255), width=6)
# dobra
cl.line([(0, ch * 0.62), (cw, ch * 0.42)], fill=(0xE0, 0xA0, 0x00, 180), width=6)
cloth_rot = cloth_layer.rotate(20, expand=True, resample=Image.BICUBIC)
img.alpha_composite(cloth_rot, (505, 470))

# ---- brilhos/sparkles de "limpo" ----
d = ImageDraw.Draw(img)
def sparkle(cx, cy, rlong, rshort, color):
    d.polygon([(cx, cy - rlong), (cx + rshort, cy - rshort), (cx + rlong, cy),
               (cx + rshort, cy + rshort), (cx, cy + rlong), (cx - rshort, cy + rshort),
               (cx - rlong, cy), (cx - rshort, cy - rshort)], fill=color)
sparkle(410, 250, 60, 16, (255, 255, 255, 255))
sparkle(300, 380, 34, 9, (255, 255, 255, 235))
sparkle(470, 200, 24, 7, (255, 255, 255, 220))

# ---- salvar multi-resolucao ----
sizes = [256, 128, 64, 48, 32, 16]
frames = [img.resize((s, s), Image.LANCZOS) for s in sizes]
frames[0].save('CleanWindows.ico', format='ICO',
               sizes=[(s, s) for s in sizes], append_images=frames[1:])
img.resize((256, 256), Image.LANCZOS).save('CleanWindows-preview.png')
print("CleanWindows.ico gerado (", ', '.join(f'{s}x{s}' for s in sizes), ")")
