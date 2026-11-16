# Referencias de estilo y diseño

Juegos que el proyecto toma como referencia (para inspirarse, no para copiar sus gráficos):

- **Pokémon Ruby/Sapphire/Emerald, Pokémon Pinball R&S, Advance Wars**: estética base de GBA
  (colores vivos, pixel exacto, marcos gruesos, letra pixel con sombra).
- **Digimon Card Battle (PS1)**: presentación de los duelos de cartas (cartas que se revelan
  en grande, ataques con escena propia) y una campaña con rivales definidos.
- **Yu-Gi-Oh! de GBA**: disposición de la mesa en una pantalla chica, indicadores de fase,
  elección de rivales.
- **Kingdom Hearts: Chain of Memories (GBA)**: interfaz de cartas y armado de mazos.
- **Pokémon Mystery Dungeon (GBA)**: retratos con expresiones junto a los diálogos, menús
  redondeados y paleta suave.
- **Hamtaro: Ham-Ham Heartbreak**: pixel art expresivo y simpático, personajes con encanto.
- **Sonic Advance**: animaciones rápidas y enérgicas, colores saturados.
- **Fondos de caja de PC de la 3ra generación**: temas de los fondos de mesa.

## Hojas de sprites que hay a mano (del usuario, no van en el repo)

Sacadas de los juegos originales: se usan solo en la copia del usuario (`mundo/propios/`,
`efectos/propios/`, `fonts/propia.*`), recortadas con los scripts de `tools/`.

| Hoja | Qué tiene | Se usa en |
|---|---|---|
| Interiores de Rubí/Zafiro/Esmeralda (1920×2864) | todas las casas, centros, escuela de Ciudad Férrica, gimnasios, Liga | la escuela (`tools/armar_escuela.py`) |
| Exteriores de Esmeralda (1408×1104, 11 tilesets) | pasto, árboles, arena, techos, cercas, carteles, edificios de cada ciudad | el patio (`tools/armar_patio.py`) |
| POKémapPARTS, de TimmY (712×295; hecha por fans, no de los juegos) | muebles y objetos sueltos estilo GBA: mesas, bancos, sillones, plantas, estantes, sombrillas | la mesa de duelo (la larga de tapete verde) y los bancos del patio (`tools/armar_patio.py --piezas`) |
| Fondo de la tienda (756×558) | una oficina con computadoras, carteles y estantes | la tienda de cartas (`tools/armar_tienda.py`) |
| Bridgette (567×673) | retrato sin cara y aparte 4 pares de ojos y 2 bocas | la vendedora de la tienda, que parpadea y sonríe |
| Afiches y sobre de ADV (5 imágenes: ex1 a ex5) | arte de cada expansión japonesa | la imagen de cada sobre en la tienda y al abrirlo (`tools/armar_sobres.py`) |
| Presentación del Profesor Birch de Rubí/Zafiro (426×1065), ripeada por Rocket Seviper Shadow (pide crédito) | Birch parado, con la Poké Ball y los cuadros de Azurill saliendo | la introducción de una partida nueva (`tools/armar_birch.py`) |
| Pokémon Overworld sprites (388×391), ripeada por Guille (de Anoe), editada por Team Aqua Grunt Chrisean (dice que el crédito no es necesario) | Pokémon caminando por el mapa, de frente, de costado y de espaldas | Azurill en el patio y Skitty en el aula (`tools/armar_pokemon_mundo.py`) |
| Interiores de Rubí/Zafiro/Esmeralda (1920×2864, fondo a cuadros) | el 2.º piso del Instituto Meteorológico y la oficina de Devon | base de la biblioteca y de la oficina del director (`tools/armar_salas.py`) |
| "POKémapPARTS" de TimmY (a.k.a. Underscore) | estantes y maceta | muebles de la biblioteca y la oficina |
| Objetos de Rubí/Zafiro de Bacon (ninsprites) | vitrinas, diploma, arbolito | muebles de la biblioteca y la oficina |
| Dorso de las cartas (380×526) | el dorso oficial | todas las cartas boca abajo (`tools/armar_dorso.py`) |
| Monedas (29 imágenes: 24 de 192×192 y 5 escaneadas más grandes) | monedas de Poké Ball y de distintos Pokémon | la moneda de cada partida, elegida al azar (`tools/armar_monedas.py`) |
| Íconos de tipo (489×171 y 103×37) | los círculos de cada tipo y los de Incolora y arcoíris | los íconos de Energía en todo el juego (`tools/armar_tipos.py`) |
| Estados de Mystery Dungeon (344×352) | íconos animados: ojo, ojo negado, !, escudo, fuego, pajaritos, flecha, espada, Z, calavera | los íconos de estado sobre los Pokémon del duelo (`tools/armar_estados.py`) |
| NPC de Esmeralda (856×695) | todos los personajes caminando (9 cuadros por fila) | los personajes de los mapas |
| Brendan (protagonista) | caminando y en bici | `jugador.png` |
| Letra de Esmeralda | el abecedario completo | `fonts/propia.fnt` (`tools/hoja_a_fuente.py`) |
| Efectos de ataques de Rubí/Zafiro (491×1926) | llamas, ola, rocas, explosión, estrellas, zarpazo, colmillos, hojas, anillo, rayo | ataques especiales (`tools/hoja_a_efectos.py`) |
| Ataques de fuego de Rubí/Zafiro (1319×1687) | Blast Burn, Blaze Kick, Ember, Fire Blast, Fire Punch, Fire Spin, Flame Wheel, Flamethrower, Overheat, Sacred Fire, Sunny Day, Will-o-Wisp | ataques de fuego (`tools/efectos_fuego.json`) |
| Ataques de veneno de Rubí/Zafiro (720×706) | Acid, Acid Armor, Poison Fang, Poison Gas/Smog, Poison Sting, Poison Tail, Poisonpowder, Sludge | ataques que envenenan (`tools/efectos_veneno.json`) |
| Clima soleado y lluvia de Mystery Dungeon Rojo | pantallas enteras animadas (13 y 61 cuadros) | Groudon y Kyogre |
| Pinball Rubí/Zafiro: interfaz | carteles (Catch 'em, Evo, Travel, Bonus), números, letras, Poké Balls, chispas, rayos | referencia (todavía sin usar) |
| Pinball Rubí/Zafiro: Pokédex | siluetas, retratos e íconos animados de los Pokémon de Hoenn | referencia (todavía sin usar) |
