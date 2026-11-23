"""Agrega los mazos de mazos_<fmt>.json al final de data/decks.json (el resto del archivo queda igual)."""
import os,json,collections,sys
P=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','data','decks.json')
WIDTH=80
def dump(d):
    out=['{']
    items=list(d.items())
    for k,(n,v) in enumerate(items):
        out.append('  %s: {'%json.dumps(n,ensure_ascii=False))
        out.append('    "description": %s,'%json.dumps(v['description'],ensure_ascii=False))
        if v.get('format'): out.append('    "format": %s,'%json.dumps(v['format']))
        out.append('    "cards": [')
        cs=['[%s, %d]'%(json.dumps(i),c) for i,c in v['cards']]
        rows=[]; cur=''
        for c in cs:
            cand=(cur+', '+c) if cur else c
            if cur and len('      '+cand+',')>WIDTH: rows.append(cur); cur=c
            else: cur=cand
        if cur: rows.append(cur)
        out+= ['      '+r+(',' if j<len(rows)-1 else '') for j,r in enumerate(rows)]
        out.append('    ]')
        out.append('  }'+(',' if k<len(items)-1 else ''))
    out.append('}')
    return '\n'.join(out)+'\n'
def blocks(txt):
    """Separa data/decks.json en (nombre, texto del bloque) sin tocar su formato."""
    lines=txt.rstrip('\n').split('\n')
    assert lines[0]=='{' and lines[-1]=='}'
    out=[]; cur=None
    for ln in lines[1:-1]:
        if ln.startswith('  "') and ln.endswith('{'):
            cur=[json.loads(ln.strip()[:-1].rstrip().rstrip(':')),[ln]]; out.append(cur)
        else:
            cur[1].append(ln)
    return [(n,'\n'.join(b).rstrip(',')) for n,b in out]
if __name__=='__main__':
    # El archivo está armado a mano: los mazos que ya estaban quedan tal cual; los de estos
    # formatos se sacan y se vuelven a agregar al final.
    txt=open(P).read()
    bl=blocks(txt)
    new=collections.OrderedDict()
    for f in sys.argv[1:]:
        new.update(json.load(open('mazos_%s.json'%f),object_pairs_hook=collections.OrderedDict))
    keep=[(n,b) for n,b in bl if n not in new and json.loads('{'+b+'}')[n].get('format') not in sys.argv[1:]]
    body=dump(new)[2:-2].rstrip('\n')
    out='{\n'+',\n'.join(b for _,b in keep)+(',\n'+body if new else '')+'\n}\n'
    d=json.loads(out)
    open(P,'w').write(out)
    print(len(d))
