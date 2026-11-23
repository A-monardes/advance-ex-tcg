import sys,importlib
from cat import *
from build import parse,BASIC_ID
f=sys.argv[1]; mod=importlib.import_module(sys.argv[2])
fam,names=families(f)
for s in mod.DECKS:
    bad=[]
    for fld in ('pokemon','trainers','energy'):
        for n,k in parse(s.get(fld,'')):
            if n in BASIC_ID: continue
            if '@' in n:
                nn,i=n.split('@')
                if not legal(i,f): bad.append(n)
            elif (n[:-2] if n.endswith(' δ') else n[:-5] if n.endswith(' LV.X') else n) not in names: bad.append(n)
    if bad: print(s['name'],':',', '.join(bad))
