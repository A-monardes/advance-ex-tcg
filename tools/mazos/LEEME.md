# Mazos prearmados por formato

Herramientas para armar los mazos prearmados de cada temporada de modo que **todas las
cartas (por nombre) tengan un lugar en algún mazo viable**.

1. `python3 cat.py 2003-04` escribe `cat_2003-04.txt`: las familias evolutivas del formato,
   con la mejor versión de cada nombre, y la lista de Entrenadores y Energías.
2. Los mazos se escriben a mano en `specs_<formato>.py` (Pokémon, Entrenadores del tema y
   Energía); `CORE` es la lista de Entrenadores genéricos con que se completa hasta 60.
   Un nombre a secas toma la mejor versión normal; `Nombre δ` y `Nombre LV.X` fuerzan esas
   versiones y `Nombre@id` una carta exacta. La Energía básica usa la primera versión legal.
3. `python3 build.py 2003-04` arma `mazos_2003-04.json` y dice qué nombres del formato faltan.
   También avisa si un mazo no llega a 60, pasa de 4 copias, lleva más de un Pokémon ★ o
   repite el nombre de un mazo de otro formato (los nombres son claves de `data/decks.json`).
   `python3 chk.py 2004-05 specs_2003_04` lista los nombres de unos specs que no existen en
   otro formato (sirve para partir de los mazos de la temporada anterior).
4. La viabilidad se mide con la IA (nivel Normal en los dos lados), todos contra todos:
   `godot --headless --script res://tests/mazos_sim.gd -- tools/mazos/mazos_2003-04.json 0 2 res.json`
   (el 0 es la temporada; `solo=Mazo1,Mazo2` prueba solo esos). Un mazo es viable si gana
   al menos ~35 % de sus partidas.
5. `python3 report.py 2003-04 "<subtítulo>" res.json [res2.json ...]` arma un informe HTML con
   la lista y el porcentaje de cada mazo (las corridas parciales posteriores reemplazan los
   resultados de los mazos que volvieron a jugar contra todos).
6. `python3 merge.py 2003-04` los agrega al final de `data/decks.json` con su `"format"`
   (si ya estaban los de ese formato, los reemplaza; el resto del archivo queda igual).

En el duelo libre se ven los mazos del formato elegido (más los del jugador). Los mazos con
`"campaign": true` son los de los rivales de la campaña: no salen en el duelo libre y se
pueden editar en el editor de mazos solo corriendo el juego desde Godot.

Excepción conocida: Rocket's Persian ex en 2006-07 no tiene mazo, porque evoluciona de
Rocket's Meowth y esa carta no es legal en el formato.
