import re, math, sys
from PIL import Image, ImageDraw
P='/home/claude/ex_tcg/'; M='/tmp/maq/'
W,H=240,160
fnt=open(P+'fonts/gba.fnt').read(); glyph={}
for m in re.finditer(r'char id=(\d+)\s+x=(\d+)\s+y=(\d+)\s+width=(\d+)\s+height=(\d+)\s+xoffset=(-?\d+)\s+yoffset=(-?\d+)\s+xadvance=(\d+)',fnt):
    g=list(map(int,m.groups())); glyph[g[0]]=g[1:]
fimg=Image.open(P+'fonts/gba.png').convert('RGBA')
def text(im,x,y,s,col=(72,72,72),shadow=(208,208,200)):
    for dx,dy,c in ([(1,1,shadow)] if shadow else [])+[(0,0,col)]:
        cx=x
        for ch in s:
            g=glyph.get(ord(ch))
            if not g: cx+=4; continue
            gx,gy,gw,gh,xo,yo,adv=g
            if gw and gh:
                a=fimg.crop((gx,gy,gx+gw,gy+gh)).split()[3]
                im.paste(Image.new('RGBA',(gw,gh),c+(255,)),(cx+xo+dx,y+yo+dy),a)
            cx+=adv
def tw(s): return sum((glyph.get(ord(c)) or [0]*7)[6] or 4 for c in s)

ATK_NAME,DEF_NAME=sys.argv[1],sys.argv[2]; FONDO=sys.argv[3]; FX=sys.argv[4]; ATTACK=sys.argv[5]
DMG=int(sys.argv[6]); DEF_HP=int(sys.argv[7]); ATK_HP=int(sys.argv[8]); WEAK=sys.argv[9]=='1'; OUT=sys.argv[10]
bg=Image.open(M+f'fondos/{FONDO}.png').convert('RGBA')
front=Image.open(M+f'spr/{DEF_NAME}_frente.png').convert('RGBA')
back=Image.open(M+f'spr/{ATK_NAME}_espalda.png').convert('RGBA')
fx=Image.open(P+f'efectos/propios/{FX}.png').convert('RGBA'); FH=fx.size[1]; FXN=fx.size[0]//FH
def hpbox(im,x,y,name,hp,maxhp,player,lvl="HP"):
    w,h=(104,37) if player else (100,29)
    d=ImageDraw.Draw(im)
    # caja R/S: borde oscuro, relleno crema, punta en diagonal
    poly=[(x+2,y),(x+w-6,y),(x+w,y+6),(x+w,y+h-1),(x+2,y+h-1),(x,y+h-3),(x,y+2)]
    d.polygon(poly,fill=(248,248,216,255),outline=(56,72,64,255))
    d.line((x+2,y+h-2,x+w-1,y+h-2),fill=(200,200,168,255))
    text(im,x+7,y+3,name.upper(),(64,64,64),(216,208,176))
    text(im,x+w-30,y+3,"L50",(64,64,64),(216,208,176))
    bx,by=x+w-56,y+16
    d.rectangle((bx-14,by-1,bx+49,by+4),fill=(80,104,96,255))
    text(im,bx-13,by-4,"HP",(248,200,64),(120,88,32))
    frac=max(0,hp)/maxhp; col=(112,248,168) if frac>.5 else (248,224,56) if frac>.2 else (248,88,56)
    d.rectangle((bx,by,bx+48,by+3),fill=(64,64,64,255))
    if frac>0: d.rectangle((bx,by,bx+max(1,int(48*frac)),by+3),fill=col+(255,))
    if player:
        s="%d/%d"%(max(0,hp),maxhp); text(im,x+w-8-tw(s),y+22,s,(64,64,64),(216,208,176))
def textbox(im,s):
    d=ImageDraw.Draw(im)
    d.rectangle((0,112,W,H),fill=(40,48,64,255))
    d.rectangle((2,114,W-3,H-3),fill=(72,88,112,255))
    d.rectangle((5,117,W-6,H-6),fill=(48,56,80,255))
    text(im,12,124,s,(248,248,248),(104,104,120))
FR=30; TOT=280
msgs=[]
t_msg=60; t_lunge=t_msg+40; t_fx=t_lunge+10; t_hit=t_fx+FXN*3; t_hp=t_hit+16; t_eff=t_hp+40; t_ko=t_eff+40
frames=[]
for f in range(TOT):
    im=Image.new('RGBA',(W,H),(0,0,0,255))
    # entrada: el fondo y los Pokémon se deslizan (enemigo desde la izquierda, vos desde la derecha)
    s=min(1,max(0,(f-10)/30)); s=1-(1-s)**2
    off_e=int(-176*(1-s)); off_p=int(176*(1-s))
    im.alpha_composite(bg,(0,0))
    # el fondo trae plataformas pintadas: las movemos copiando las franjas de cada mitad
    if s<1:
        top=bg.crop((0,40,240,80)); bot=bg.crop((0,92,240,112))
        clean=bg.crop((0,30,240,40)).resize((240,40))
        im.alpha_composite(clean,(0,40)); im.alpha_composite(top,(off_e,40))
        im.alpha_composite(bg.crop((0,82,240,92)).resize((240,20)),(0,92)); im.alpha_composite(bot,(off_p,92))
    lunge=0
    if t_lunge<=f<t_lunge+12: lunge=int(8*math.sin((f-t_lunge)/12*math.pi))
    shake=[3,-3,2,-2,1,-1,0,0][(f-t_hit)%8] if t_hit<=f<t_hit+16 else 0
    sink=0
    if f>=t_ko: sink=min(64,(f-t_ko)*3)
    # enemigo (frente) sobre su plataforma
    ex,ey=144+off_e+shake,6
    blink=t_hit<=f<t_hit+16 and (f//3)%2==0
    if not blink and sink<64:
        spr=front.crop((0,0,64,64-sink))
        im.alpha_composite(spr,(ex,ey+sink))
    # vos (espalda)
    im.alpha_composite(back,(40+off_p+lunge,48-lunge//2))
    # efecto del ataque sobre el enemigo
    if t_fx<=f<t_fx+FXN*3:
        k=(f-t_fx)//3; fr=fx.crop((k*FH,0,k*FH+FH,FH))
        sc=72/FH; fr=fr.resize((int(FH*sc),int(FH*sc)),Image.NEAREST)
        im.alpha_composite(fr,(ex+32-fr.size[0]//2,ey+36-fr.size[1]//2))
    if f in (t_hit,t_hit+1,t_hit+4):
        im.alpha_composite(Image.new('RGBA',(W,112),(248,248,248,140)),(0,0))
    # cajas de PS
    b=min(1,max(0,(f-42)/10))
    hp=DEF_HP
    if f>=t_hp: hp=int(DEF_HP-DMG*min(1,(f-t_hp)/30))
    hpbox(im,int(-110+(110+13)*b),16,DEF_NAME,hp,DEF_HP,False)
    hpbox(im,int(W+4-(W+4-126)*b),74,ATK_NAME,ATK_HP,ATK_HP,True)
    # texto
    if f<t_msg: s_=f"Go! {ATK_NAME.upper()}!" if f>=42 else ""
    elif f<t_eff: s_=f"{ATK_NAME.upper()} used {ATTACK}!"; 
    elif f<t_ko: s_="It's super effective!" if WEAK else f"{DEF_NAME.upper()} took {DMG} damage."
    else: s_=f"Foe {DEF_NAME.upper()} fainted!" if DMG>=DEF_HP else f"{DEF_NAME.upper()} took {DMG} damage."
    t0=42 if f<t_msg else t_msg if f<t_eff else t_eff if f<t_ko else t_ko
    textbox(im,s_[:max(0,(f-t0)*2)])
    # franjas de entrada (como al empezar una batalla)
    if f<12:
        p=f/12; d=ImageDraw.Draw(im)
        for yy in range(0,H,8):
            ww=int(W*(1-p))
            if (yy//8)%2: d.rectangle((0,yy,ww,yy+7),fill=(16,16,24,255))
            else: d.rectangle((W-ww,yy,W,yy+7),fill=(16,16,24,255))
    frames.append(im.convert('RGB').resize((W*3,H*3),Image.NEAREST))
frames[0].save(OUT+'.gif',save_all=True,append_images=frames[1:],duration=33,loop=0)
frames[t_fx+FXN*3//2].save(OUT+'_fx.png'); frames[t_hp+20].save(OUT+'_hp.png')
print('ok')
