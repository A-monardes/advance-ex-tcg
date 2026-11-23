"""Informe HTML de los mazos de un formato: report.py <fmt> "<subtítulo>" <res.json> [<res2.json> ...]
Los resultados posteriores reemplazan a los anteriores para los mazos que jugaron contra todos."""
import json,re,html,collections,sys
from cat import *
F=sys.argv[1]; SUB=sys.argv[2]; RES=sys.argv[3:]
specs=open('specs_%s.py'%F.replace('-','_')).read()
sec=None; order=[]
for line in specs.split('\n'):
    m=re.match(r'# -+ (.*?) -+',line)
    if m: sec=m.group(1)
    m=re.match(r'dict\(name="(.*?)"',line)
    if m: order.append((sec,m.group(1)))
SEC={'Team Magma / Team Aqua':'Team Magma y Team Aqua','Especies δ (Holon)':'Especies δ (Holon)'}
d=json.load(open('mazos_%s.json'%F))
r=json.load(open(RES[0])); N=len(d)
games=sum(v['w']+v['l']+v['d'] for v in r.values())//2
for p in RES[1:]:
    r2=json.load(open(p))
    games+=sum(v['w']+v['l']+v['d'] for v in r2.values())//2
    for k,v in r2.items():
        if v['w']+v['l']+v['d']>=2*(N-1)*0.9: r[k]=v
fam,names=families(F)
used={dname(BY[i]['name']) for v in d.values() for i,_ in v['cards']}
def pct(n): v=r[n]; return 100*v['w']/max(1,v['w']+v['l'])
def esc(x): return html.escape(x)
rows=[]
cur=None
for s,n in order:
    if s!=cur:
        rows.append('<tr class="sec"><td colspan="4">%s</td></tr>'%esc(SEC.get(s,s))); cur=s
    deck=d[n]
    pk=collections.OrderedDict(); tr=[]; en=[]
    for i,k in deck['cards']:
        c=BY[i]; nm=c['name']
        if c['supertype']=='Pokémon': pk[nm]=pk.get(nm,0)+k
        elif c['supertype']=='Trainer': tr.append('%d %s'%(k,nm))
        else: en.append('%d %s'%(k,nm))
    # orden: por línea evolutiva aproximada (fase)
    pks=sorted(pk.items(),key=lambda x:0)
    np_=sum(pk.values()); nt=sum(int(x.split()[0]) for x in tr); ne=sum(int(x.split()[0]) for x in en)
    p=pct(n)
    bar='<div class="bar"><span style="width:%d%%"></span></div>'%round(p)
    detail='<details><summary>%d Pokémon · %d Entrenadores · %d Energías</summary><div class="cols"><div><b>Pokémon</b><br>%s</div><div><b>Entrenadores</b><br>%s</div><div><b>Energías</b><br>%s</div></div></details>'%(
        np_,nt,ne,'<br>'.join('%d %s'%(k,esc(x)) for x,k in pks),'<br>'.join(esc(x) for x in tr),'<br>'.join(esc(x) for x in en))
    rows.append('<tr><td class="nm">%s</td><td>%s%s</td><td class="pc">%.0f%%%s</td></tr>'%(esc(n),esc(deck['description']),detail,p,bar))
ps=[pct(n) for _,n in order]
MISS=[n for n in names if n not in used and n not in BASIC_EN]
WHY={"Rocket's Persian ex":"evoluciona de Rocket's Meowth, que no es legal en este formato"}
MISSTXT=''.join('<p class="note"><b>Sin mazo:</b> %s (%s).</p>'%(esc(n),esc(WHY.get(n,'sin lugar todavía'))) for n in MISS)
page='''<!DOCTYPE html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mazos prearmados · @F@</title>
<style>
:root{--ink:#1d2433;--dim:#5b6478;--line:#dfe3ea;--acc:#c03028;--bg:#fbfaf6}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 system-ui,-apple-system,Segoe UI,sans-serif}
main{max-width:1000px;margin:0 auto;padding:28px 20px 60px}
h1{font-size:26px;margin:0 0 4px} .sub{color:var(--dim);margin:0 0 22px}
.kpis{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:22px}
.kpi{background:#fff;border:1px solid var(--line);border-radius:8px;padding:10px 14px;min-width:150px}
.kpi b{display:block;font-size:22px} .kpi span{color:var(--dim);font-size:13px}
p.note{color:var(--dim);font-size:14px;max-width:760px}
table{width:100%;border-collapse:collapse;background:#fff;border:1px solid var(--line);border-radius:8px;overflow:hidden}
td{padding:9px 12px;border-top:1px solid var(--line);vertical-align:top}
tr.sec td{background:#f1efe7;font-weight:600;font-size:13px;letter-spacing:.04em;text-transform:uppercase;color:var(--dim)}
td.nm{font-weight:600;white-space:nowrap} td.pc{width:90px;text-align:right;font-variant-numeric:tabular-nums}
.bar{height:5px;background:#eee;border-radius:3px;margin-top:5px}.bar span{display:block;height:100%;background:var(--ink);border-radius:3px}
details{margin-top:4px;font-size:13px;color:var(--dim)} summary{cursor:pointer}
.cols{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin-top:6px;color:var(--ink)}
@media(max-width:640px){.cols{grid-template-columns:1fr} td.nm{white-space:normal}}
</style></head><body><main>
<h1>Mazos prearmados · formato @F@</h1>
<p class="sub">@SUB@</p>
<div class="kpis">
<div class="kpi"><b>@N@</b><span>mazos</span></div>
<div class="kpi"><b>@COV@</b><span>nombres de carta cubiertos</span></div>
<div class="kpi"><b>@MIN@% – @MAX@%</b><span>victorias, del peor al mejor</span></div>
<div class="kpi"><b>@G@</b><span>partidas simuladas</span></div>
</div>
<p class="note">Cada mazo jugó 2 partidas contra cada uno de los otros @N1@ (una empezando de cada lado), con la IA Normal en los dos lados. Los que quedaban por debajo de ~35% se reforzaron hasta pasarlo. El porcentaje es la proporción de partidas ganadas. Tocá un mazo para ver la lista completa.</p>
@MISS@<table>@ROWS@</table>
</main></body></html>'''.replace('@N@',str(len(order))).replace('@F@',F).replace('@SUB@',esc(SUB)).replace('@N1@',str(N-1)).replace('@G@',str(games)).replace('@COV@','%d / %d'%(len(names)-len(MISS),len(names))).replace('@MIN@','%.0f'%min(ps)).replace('@MAX@','%.0f'%max(ps)).replace('@MISS@',MISSTXT).replace('@ROWS@','\n'.join(rows))
open('/home/claude/mazos/mazos_%s.html'%F,'w').write(page)
print(len(page))
