## Convierte los PNG animados de Bulbagarden (Spr_3e_NNN.png) en una tira de cuadros distintos + json
## para mundo/propios/batalla/animados/ (ver scenes/special_fx.gd, gen3_anim).
## Uso: python3 tools/sprites_animados.py <carpeta destino> archivo.png=NUM [archivo.png=NUM ...]
import sys, json, os
from PIL import Image, ImageSequence
NAMES = {1:'bulbasaur',2:'ivysaur',3:'venusaur',4:'charmander',5:'charmeleon',6:'charizard',7:'squirtle',8:'wartortle',9:'blastoise',
 127:'pinsir',150:'mewtwo',151:'mew',152:'chikorita',153:'bayleef',154:'meganium',155:'cyndaquil',156:'quilava',157:'typhlosion',
 158:'totodile',159:'croconaw',160:'feraligatr',214:'heracross',252:'treecko',253:'grovyle',254:'sceptile',255:'torchic',256:'combusken',
 257:'blaziken',258:'mudkip',259:'marshtomp',260:'swampert',335:'zangoose',336:'seviper',382:'kyogre',383:'groudon',384:'rayquaza'}
out = sys.argv[1]
for src, num in [a.split('=') for a in sys.argv[2:]]:
    num = int(num)
    im = Image.open(src)
    frames, ms = [], []
    for f in ImageSequence.Iterator(im):
        frames.append(f.convert('RGBA').copy()); ms.append(f.info.get('duration', 16.7))
    uniq, seq = [], []
    for f in frames:
        b = f.tobytes()
        for i, u in enumerate(uniq):
            if u.tobytes() == b:
                seq.append(i); break
        else:
            uniq.append(f); seq.append(len(uniq) - 1)
    # juntar cuadros iguales seguidos (duración sumada)
    s2, m2 = [], []
    for k, m in zip(seq, ms):
        if s2 and s2[-1] == k:
            m2[-1] += m
        else:
            s2.append(k); m2.append(m)
    # Bulbagarden deja el último cuadro quieto un rato (a veces el alternativo): se saca,
    # al terminar el juego vuelve a la pose del primero
    if len(m2) > 1 and m2[-1] > 500:
        s2.pop(); m2.pop()
    w, h = uniq[0].size
    strip = Image.new('RGBA', (w * len(uniq), h))
    for i, u in enumerate(uniq):
        strip.paste(u, (i * w, 0))
    name = NAMES[num]
    strip.save(os.path.join(out, name + '.png'))
    json.dump({'celda': [w, h], 'cuadros': s2, 'ms': [round(m) for m in m2]}, open(os.path.join(out, name + '.json'), 'w'))
    print(name, len(frames), '->', len(uniq), 'distintos,', len(s2), 'pasos,', round(sum(ms)), 'ms')
