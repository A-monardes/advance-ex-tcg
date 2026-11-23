import os
import json,collections,re,sys
cs=json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','data','cards_adv.json')))
BY={c['id']:c for c in cs}
FMT={'2003-04':(["ecard1","ecard2","ecard3","ex1","ex2","ex3","ex4","ex5"],26,None),
 '2004-05':(["ex1","ex2","ex3","ex4","ex5","ex6","ex7","ex8","ex9","pop1"],27,None),
 '2005-06':(["ex5","ex6","ex7","ex8","ex9","ex10","ex11","ex12","ex13","pop1","pop2","pop3"],0,[27,28,29,30,31,32,33,35,36]),
 '2006-07':(["ex8","ex9","ex10","ex11","ex12","ex13","ex14","ex15","ex16","pop2","pop3","pop4","pop5","dp1","dpp"],0,list(range(27,41)))}
def legal(cid,f):
    sets,npmax,npok=FMT[f]
    s,n=cid.split('-',1)
    if s=='np':
        n=int(n)
        return (n in npok) if npok else n<=npmax
    return s in sets
def evo(n): return n.replace(' δ','').replace('δ','').strip()
def dname(n): return evo(n).removesuffix(' LV.X')
BASIC_EN={'Grass Energy','Fire Energy','Water Energy','Lightning Energy','Psychic Energy','Fighting Energy','Darkness Energy','Metal Energy'}
def pool(f):
    p=[c for c in cs if legal(c['id'],f)]
    names=collections.defaultdict(list)
    for c in p:
        names[dname(c['name'])].append(c['id'])
    return p,names
BABY={"Pichu":"Pikachu","Magby":"Magmar","Elekid":"Electabuzz","Smoochum":"Jynx","Tyrogue":"Hitmonlee","Cleffa":"Clefairy","Igglybuff":"Jigglypuff"}
def families(f):
    p,names=pool(f)
    parent={}
    for c in p:
        if c['supertype']!='Pokémon': continue
        n=dname(c['name'])
        if c.get('evolves_from'): parent.setdefault(n,set()).add(dname(c['evolves_from']))
    root={}
    def r(n,seen=()):
        if n in seen or not parent.get(n): return n
        # elige un padre que exista en el pool, si no la propia carta es raíz
        ps=[x for x in parent[n] if x in names] or list(parent[n])
        return r(sorted(ps)[0],seen+(n,))
    fam=collections.defaultdict(set)
    for n,ids in names.items():
        if BY[ids[0]]['supertype']!='Pokémon': continue
        fam[r(n)].add(n)
    return fam,names
if __name__=='__main__':
    f=sys.argv[1]
    fam,names=families(f)
    tr=[n for n,i in names.items() if BY[i[0]]['supertype']=='Trainer']
    en=[n for n,i in names.items() if BY[i[0]]['supertype']=='Energy' and n not in BASIC_EN]
    print('nombres',len(names),'familias',len(fam),'entrenadores',len(tr),'energias esp',len(en))
    print('familias con raiz fuera del pool', [k for k in fam if k not in names][:20])
    sz=collections.Counter(len(v) for v in fam.values()); print(sz)
