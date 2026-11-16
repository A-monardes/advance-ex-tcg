# Advance EX TCG: base de la historia

Este documento es un punto de partida. Los diálogos, las escenas y los nombres finales los
escribís vos; acá van el mundo, el conflicto y la estructura general. Lo marcado con **(?)**
son decisiones abiertas.

## El mundo

- **Dónde:** Hoenn, en la época de Rubí y Zafiro. Los Pokémon son reales: hay
  entrenadores, gimnasios y la Liga Pokémon de siempre.
- **El juego de cartas:** Devon, la empresa de Ciudad Férrea (Rustboro), lo trajo a la
  región hace poco y es furor entre los chicos. Las expansiones (ex1 a ex5) salen una
  tras otra, cada una con su evento de lanzamiento.
- **La Liga de Cartas de Hoenn:** una liga aparte de la Liga Pokémon. Cada ciudad tiene un
  club de cartas con un líder que entrega un emblema. Con los emblemas se entra al torneo
  final. Para inscribirse hace falta una **licencia de duelista**.
- **Por qué la escuela:** Devon patrocina el primer curso de cartas en la Escuela de
  Entrenadores de Rustboro. Es la forma más rápida de conseguir la licencia, y muchos chicos
  que todavía no pueden salir de viaje con Pokémon encuentran ahí su manera de competir.

## El conflicto (intriga, sin magia)

El juego mueve mucho dinero y mucha fama, y no todos juegan limpio.

- **El Team Magma y el Team Aqua** son dos "equipos" grandes de la liga. De cara al público
  son clubes con patrocinio, ídolos y seguidores. Por detrás, usan el mercado de cartas para
  financiar sus planes de siempre (más tierra, más mar). Compran todas las cajas de una
  tienda para revender las cartas raras, reclutan a los mejores alumnos y presionan a los
  organizadores. Sus mazos son, literalmente, la expansión ex4.
- **La filtración:** cartas de expansiones que todavía no salieron aparecen en manos de
  jugadores de los dos equipos. Alguien de adentro, en Devon o en la liga, les pasa
  información y material antes de tiempo. Eso les da ventaja en los torneos y hunde a las
  tiendas chicas.
- **El misterio que recorre la historia:** ¿quién filtra y por qué? Las pistas aparecen de a
  poco: una carta que nadie debería tener, un sobre con un sello raro, un organizador que
  siempre cambia las reglas a último momento.
  - Sospechosos posibles **(?)**: alguien de Devon resentido, un dirigente de la liga, o
    alguien cercano al jugador (el Director de la escuela, la vendedora de la tienda...).
  - Motivo **(?)**: dinero, venganza contra Devon, o la convicción de que "el juego tiene que
    ser de los que más lo merecen".

## Estructura sugerida (una expansión por arco)

1. **Ruby & Sapphire (ex1): el comienzo.** La escuela de Rustboro, la licencia y el primer
   club.
2. **Sandstorm (ex2): rutas y desierto.** Los equipos empiezan a aparecer en los torneos
   chicos y las tiendas se quedan sin sobres.
3. **Dragon (ex3): la fama.** Un torneo grande, ídolos de los equipos y la primera carta
   filtrada que el jugador ve con sus propios ojos.
4. **Team Magma vs Team Aqua (ex4): la guerra abierta.** Los equipos se enfrentan entre sí y
   la liga se divide. El jugador tiene que elegir en quién confiar.
5. **Hidden Legends (ex5): el lanzamiento.** El torneo de presentación de la última
   expansión es el gran evento final: ahí se descubre quién está detrás de la filtración.

## Capítulo 1: la escuela de Rustboro

- **Regla del capítulo:** ninguna mención del Team Aqua ni del Team Magma. Aparecen recién
  en capítulos posteriores.
- **Presentación (Profesor Birch):** como en Rubí y Zafiro. Birch se presenta, saca a su
  Lotad, cuenta que Devon trajo el juego de cartas a Hoenn, pregunta tu nombre, te anotó en
  el curso de la Escuela de Entrenadores de Rustboro y te ofrece tres mazos iniciales. El
  guion está en `data/intro.json` (se puede reescribir sin tocar código).
- **Inicio:** primer día del curso de cartas. El maestro presenta el curso (patrocinado por
  Devon).
- **Desarrollo:** los compañeros del aula enseñan reglas y consejos. Hay duelos con los dos
  alumnos del aula y, después, con el Director en el patio de duelos. Tras vencerlo se
  habilitan los otros cuatro alumnos del patio.
- **La semilla de la intriga (?):** algún detalle chico que solo cobra sentido más adelante.
  Por ejemplo:
  - un compañero presume una carta que todavía no salió a la venta;
  - un visitante de Devon habla en voz baja con el Director;
  - una caja de sobres de la tienda llega abierta.
- **Cierre:** graduación y licencia de duelista. **(?)** Algún gancho hacia la próxima
  ciudad que no involucre a los equipos (por ejemplo, la invitación a la Liga de Cartas de
  Hoenn o una pista sobre la filtración de cartas).

## Personajes del capítulo 1

| Personaje | Rol | Notas |
|---|---|---|
| Profesor Birch | presentación | te anota en el curso y te da el mazo inicial |
| Jugador (Brendan) | protagonista | sprite de Esmeralda |
| Maestro / Maestra | presentan el curso | guían el tutorial |
| Alumno y Alumna del aula | primeros rivales | la alumna es "la mejor de la clase" |
| Director | jefe del capítulo | en el patio; ¿sabe algo de la filtración? **(?)** |
| Cuatro alumnos del patio | rivales post-Director | Ruby, Sapphire, Forest Guardian, WindBlast |
| Bridgette | tienda | ¿por qué siempre tiene stock cuando nadie más tiene? **(?)** |
| Compañeros del aula (11) | ambiente y tutorial | cada uno puede enseñar algo |
