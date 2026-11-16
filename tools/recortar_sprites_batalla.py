from PIL import Image
import numpy as np
from collections import deque
src=np.array(Image.open('/mnt/user-data/uploads/ebe35e9c-image.jpg').convert('RGB')).astype(float)
cx=[8,250,492,734]; cy=[8,250,492]
names=['sceptile','blaziken','swampert']; kinds=['frente','frente_shiny','espalda','espalda_shiny']
bgc=np.array([255,200,107.]); N=64
for r,nm in enumerate(names):
    for c,kd in enumerate(kinds):
        x0,y0=cx[c],cy[r]; s=215/N
        col=np.zeros((N,N,3))
        for j in range(N):
            for i in range(N):
                xa=int(x0+i*s+s*0.3); xb=int(x0+(i+1)*s-s*0.3)+1
                ya=int(y0+j*s+s*0.3); yb=int(y0+(j+1)*s-s*0.3)+1
                col[j,i]=np.median(src[ya:yb,xa:xb].reshape(-1,3),0)
        d=np.abs(col-bgc).max(2)
        bg=np.zeros((N,N),bool); q=deque()
        for i in range(N):
            for p in [(0,i),(i,0),(i,N-1)] + [(N-1,i)]:
                if d[p]<30 and not bg[p]: bg[p]=True; q.append(p)
        while q:
            y,x=q.popleft()
            for yy,xx in ((y+1,x),(y-1,x),(y,x+1),(y,x-1)):
                if 0<=yy<N and 0<=xx<N and not bg[yy,xx] and d[yy,xx]<30: bg[yy,xx]=True; q.append((yy,xx))
        # halo suave: borde pegado al fondo y casi del color del fondo
        pad=np.pad(bg,1); nb=pad[:-2,1:-1]|pad[2:,1:-1]|pad[1:-1,:-2]|pad[1:-1,2:]
        bg|=(~bg)&nb&(d<48)
        out=np.zeros((N,N,4),np.uint8); out[...,:3]=col.clip(0,255); out[...,3]=np.where(bg,0,255)
        im=Image.fromarray(out,'RGBA')
        q2=im.convert('RGB').quantize(colors=15,method=Image.Quantize.MEDIANCUT).convert('RGB'); q2.putalpha(im.split()[3])
        q2.save(f'spr/{nm}_{kd}.png')
sheet=Image.new('RGBA',(64*4*3,64*3*3),(90,90,110,255))
for r,nm in enumerate(names):
    for c,kd in enumerate(kinds):
        sheet.alpha_composite(Image.open(f'spr/{nm}_{kd}.png').resize((192,192),Image.NEAREST),(c*192,r*192))
sheet.save('hoja_ver.png')
