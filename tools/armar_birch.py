"""Recorta la presentación del Profesor Birch de Rubí/Zafiro (hoja de Rocket Seviper Shadow,
426x1065, fondo negro) en una tira de cuadros iguales alineados por la cabeza de Birch.
Uso: python3 tools/armar_birch.py hoja.png [carpeta_salida]
Sale mundo/propios/intro/birch.png (+ birch.json). La hoja no va en el repo."""
import sys, os, json
SRC=sys.argv[1]
DST=sys.argv[2] if len(sys.argv)>2 else os.path.join(os.path.dirname(__file__),'..','mundo','propios','intro')
from PIL import Image
import numpy as np
a=np.array(Image.open(SRC).convert('RGB')).astype(int)
H,W,_=a.shape
# busca la cabeza de Birch (del cuadro con la Poké Ball, x 228-274, y 6-68) en toda la hoja
t=a[6:30,244:274]
tm=t.sum(2)>0
th,tw=tm.shape
res=[]
for y in range(H-th):
    for x in range(W-tw):
        w=a[y:y+th,x:x+tw]
        eq=(w==t).all(2)&tm
        sc=eq.sum()/tm.sum()
        if sc>0.6: res.append((sc,x,y))
res.sort(reverse=True)
keep=[]
for sc,x,y in res:
    if all(abs(x-k[1])>15 or abs(y-k[2])>15 for k in keep): keep.append((sc,x,y))
keep.sort(key=lambda k:(k[2]//40,k[1]))
for k in keep: print("%.2f %d %d"%k)
print(len(keep))

# ---- recorte de cuadros ----
rows=[]
for k in sorted(keep,key=lambda k:k[2]):
    for r in rows:
        if abs(r[0][2]-k[2])<25: r.append(k);break
    else: rows.append([k])
order=[]
for r in rows: order+=sorted(r,key=lambda k:k[1])
L,R,T,B=75,33,22,62            # ventana alrededor de la cabeza
from scipy import ndimage
m=a.sum(2)>0
m[0:76,58:215]=False          # los sprites chicos y la mochila de la primera fila
m[76:82,0:230]=False
lab,nl=ndimage.label(m,structure=np.ones((3,3)))
own=np.full((H,W),-1)
for c,sl in enumerate(ndimage.find_objects(lab),start=1):
    ys,xs=np.nonzero(lab[sl]==c)
    cy=ys.mean()+sl[0].start; cx=xs.mean()+sl[1].start
    best=None
    for i,(sc,hx,hy) in enumerate(order):
        if hx-L<=cx<=hx+R and hy-T<=cy<=hy+B:
            key=(max(0,-4-(cy-hy))+max(0,(cy-hy)-62), hx if hx+33>=cx else 999)
            if best is None or key<best[0]: best=(key,i)
    if best:
        sub=own[sl]; sub[lab[sl]==c]=best[1]
CW,CH=L+R+1,T+B+1
out=Image.new('RGBA',(CW*len(order),CH),(0,0,0,0))
src=Image.open(SRC).convert('RGBA')
for i,(sc,hx,hy) in enumerate(order):
    for yy in range(CH):
        for xx in range(CW):
            px,py=hx-L+xx,hy-T+yy
            if 0<=px<W and 0<=py<H and own[py,px]==i:
                out.putpixel((i*CW+xx,yy),src.getpixel((px,py)))
# limpia restos oscuros sueltos arriba de cada cuadro (pies de la fila de arriba en la hoja)
px=out.load()
for i in range(len(order)):
    for yy in range(4):
        for xx in range(CW):
            r,g,b,al=px[i*CW+xx,yy]
            if al and r+g+b<150: px[i*CW+xx,yy]=(0,0,0,0)
os.makedirs(DST,exist_ok=True)
out.save(os.path.join(DST,'birch.png'))
json.dump({"celda":[CW,CH],"pies":T+62,"cuadros":len(order),
    "_ayuda":"cuadro 0: Birch parado; 1: con la Poké Ball; 2 en adelante: sale Azurill"},
    open(os.path.join(DST,'birch.json'),'w'),ensure_ascii=False)
print(CW,CH,len(order))
