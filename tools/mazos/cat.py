import json,re,sys,collections
from inv import *
def dmg(a):
    d=a.get('damage') or 0
    try: d=int(d)
    except: d=int(re.sub(r'\D','',str(d)) or 0)
    t=a.get('text','') or ''
    m=re.search(r'(\d+) more damage',t)
    if m: d+=int(m.group(1))//2
    if 'each Benched' in t or "each of your opponent's" in t: d+=10
    return d
def score(c):
    if c['supertype']!='Pokémon': return 0
    best=0
    for a in c.get('attacks',[]):
        n=max(1,len(a['cost']))
        best=max(best, dmg(a)/n*1.0 + (8 if a.get('text') and dmg(a)==0 else 0))
    s=best*1.5 + (c.get('hp') or 0)/10 + 6*len(c.get('abilities',[])) - 1.5*(c.get('retreat') or 0)
    if 'ex' in c['subtypes'] or c['name'].endswith(' ex'): s-=4   # da 2 premios
    return round(s,1)
def stage(c):
    st=c['subtypes']
    return 2 if 'Stage 2' in st else 1 if 'Stage 1' in st else 0
def brief(c):
    at='; '.join('%s[%s]%s%s'%(a['name'],''.join(x[0] if x!='Colorless' else 'C' for x in a['cost']),a.get('damage') or '', ('*' if a.get('text') else '')) for a in c.get('attacks',[]))
    ab=''.join(' {%s %s}'%(x['kind'][5:],x['name']) for x in c.get('abilities',[]))
    return '%s %s HP%s %s%s |%s' % (c['id'],'/'.join(t[:3] for t in c['types']),c.get('hp'),'ex ' if c['name'].endswith(' ex') else '',ab,at)
if __name__=='__main__':
    f=sys.argv[1]
    fam,names=families(f)
    out=[]
    for root in sorted(fam, key=lambda r:-max(score(BY[i]) for n in fam[r] for i in names[n])):
        ns=sorted(fam[root], key=lambda n:(stage(BY[names[n][0]]), n))
        out.append('## '+root)
        for n in ns:
            ids=sorted(names[n], key=lambda i:-score(BY[i]))
            out.append('  %s (S%d) x%d  best: %s  [%s]'%(n,stage(BY[ids[0]]),len(ids),brief(BY[ids[0]]),score(BY[ids[0]])))
    tr=sorted(n for n,i in names.items() if BY[i[0]]['supertype']!='Pokémon')
    out.append('## ENTRENADORES Y ENERGÍAS')
    for n in tr:
        c=BY[names[n][0]]
        out.append('  %s [%s] %s'%(n,'/'.join(c['subtypes']),', '.join(names[n][:4])))
    open('cat_%s.txt'%f,'w').write('\n'.join(out)); print(len(out))
