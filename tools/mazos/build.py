"""Arma los mazos de un formato a partir de specs_<fmt>.py y reporta la cobertura por nombre."""
import json,sys,re,importlib,collections
from cat import *
BASIC_ID={'Grass':'ex1-104','Fighting':'ex1-105','Water':'ex1-106','Psychic':'ex1-107','Fire':'ex1-108','Lightning':'ex1-109'}
def basic_id(n,f):
    # Energía básica: el id ex1 si es legal en el formato; si no, la primera versión legal.
    i=BASIC_ID[n]
    if legal(i,f): return i
    return sorted(x for x in BY if BY[x]['name']==n+' Energy' and BY[x]['supertype']=='Energy' and legal(x,f))[0]
def parse(s):
    out=[]
    for part in [p.strip() for p in s.split(',') if p.strip()]:
        m=re.match(r'^(.*?)\s+(\d+)$',part)
        out.append((m.group(1).strip(),int(m.group(2))))
    return out
def pick(name,f,names):
    if '@' in name:
        n,i=name.split('@'); assert legal(i,f),(i,f); return i
    delta=name.endswith(' δ')
    if delta: name=name[:-2]
    lvx=name.endswith(' LV.X')
    if lvx: name=name[:-5]
    if name not in names: raise SystemExit('no existe en %s: %s'%(f,name))
    # "Nombre δ" / "Nombre LV.X" eligen solo esas versiones; "Nombre" prefiere las que no lo son.
    ids=[i for i in names[name] if ('δ' in BY[i]['name'])==delta] or names[name]
    ids=[i for i in ids if ('LV.X' in BY[i]['name'])==lvx] or ids
    if lvx and not any('LV.X' in BY[i]['name'] for i in ids): raise SystemExit('sin LV.X en %s: %s'%(f,name))
    if delta and not any('δ' in BY[i]['name'] for i in ids): raise SystemExit('sin δ en %s: %s'%(f,name))
    return max(ids,key=lambda i:(score(BY[i]), i.startswith('ex')))
def build(spec,f,names,core):
    cards=collections.Counter()
    for n,k in parse(spec.get('pokemon','')): cards[pick(n,f,names)]+=k
    for n,k in parse(spec.get('trainers','')): cards[pick(n,f,names)]+=k
    for n,k in parse(spec.get('energy','')):
        cards[basic_id(n,f) if n in BASIC_ID else pick(n,f,names)]+=k
    has2=any(stage(BY[i])==2 for i in cards if BY[i]['supertype']=='Pokémon')
    hasevo=any(stage(BY[i])>=1 for i in cards if BY[i]['supertype']=='Pokémon')
    def cnt_name(n): return sum(k for i,k in cards.items() if dname(BY[i]['name'])==n)
    total=lambda: sum(cards.values())
    if has2 and cnt_name('Rare Candy')==0 and total()<60:
        cards[pick('Rare Candy',f,names)]+=min(3,60-total())
    guard=0
    while total()<60 and guard<500:
        guard+=1
        for n,mx,cond in core:
            if total()>=60: break
            if cond=='evo' and not hasevo: continue
            if n not in names: continue
            if cnt_name(n)<mx: cards[pick(n,f,names)]+=1
    if total()!=60: print('!! %s tiene %d cartas'%(spec['name'],total()))
    stars=sum(k for i,k in cards.items() if '★' in BY[i]['name'])
    if stars>1: print('!! %s tiene %d Pokémon ★ (máximo 1)'%(spec['name'],stars))
    for n in set(dname(BY[i]['name']) for i in cards):
        if n not in ('Grass Energy','Fire Energy','Water Energy','Lightning Energy','Psychic Energy','Fighting Energy') and cnt_name(n)>4:
            print('!! %s: %d copias de %s'%(spec['name'],cnt_name(n),n))
    return cards
if __name__=='__main__':
    f=sys.argv[1]
    mod=importlib.import_module('specs_'+f.replace('-','_'))
    fam,names=families(f)
    out={}
    used=collections.Counter()
    for spec in mod.DECKS:
        cards=build(spec,f,names,mod.CORE)
        out[spec['name']]={'description':spec['desc'],'format':f,'cards':[[i,k] for i,k in sorted(cards.items(),key=lambda x:(['Pokémon','Trainer','Energy'].index(BY[x[0]]['supertype']),x[0]))]}
        for i in cards: used[dname(BY[i]['name'])]+=1
    # Los nombres de mazo son claves de data/decks.json: no pueden repetirse entre formatos.
    import os,glob
    otros=set()
    dj=json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','data','decks.json')))
    otros|={k for k,v in dj.items() if v.get('format','')!=f}
    for p in glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)),'specs_*.py')):
        g=os.path.basename(p)[6:-3]
        if g!=f.replace('-','_'): otros|={d['name'] for d in importlib.import_module('specs_'+g).DECKS}
    for n in out:
        if n in otros: print('!! nombre repetido en otro formato:',n)
    json.dump(out,open('mazos_%s.json'%f,'w'),ensure_ascii=False,indent=1)
    miss=[n for n in names if n not in used and n not in BASIC_EN]
    print('mazos',len(out),'nombres cubiertos',len(names)-len(miss),'de',len(names))
    bys=collections.defaultdict(list)
    for n in miss: bys[BY[names[n][0]]['supertype']].append(n)
    for k,v in bys.items(): print(' faltan',k,len(v),': '+', '.join(sorted(v)))
