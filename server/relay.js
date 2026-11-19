// Relay de partidas en línea de Advance EX TCG.
//
// No sabe nada del juego: une a dos jugadores con un código de sala de 4 letras y les pasa
// los mensajes de uno al otro. La partida la calculan los dos juegos a la vez (el motor es
// determinista: misma semilla y mismas acciones = misma partida).
//
// Mensajes (JSON por WebSocket):
//   cliente -> {"op":"create"}               servidor -> {"op":"created","room":"ABCD"}
//   cliente -> {"op":"join","room":"ABCD"}   servidor -> a los dos {"op":"start","you":0|1}
//   cliente -> {"op":"msg","data":{...}}     servidor -> al otro {"op":"msg","data":{...}}
//   servidor -> {"op":"left"} si el otro se fue · {"op":"error","why":"..."}
//
// Uso: npm install && npm start   (puerto: variable PORT, 8080 si no está)
const http = require("http");
const { WebSocketServer } = require("ws");

const PORT = parseInt(process.env.PORT || "8080", 10);
const LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ";      // sin I ni O (se confunden con 1 y 0)
const rooms = new Map();                           // código -> [host, guest]

const server = http.createServer((req, res) => {
  // Para el chequeo de salud de los servicios gratuitos (Render, etc.)
  res.writeHead(200, { "Content-Type": "text/plain", "Access-Control-Allow-Origin": "*" });
  res.end("Advance EX TCG relay: " + rooms.size + " room(s)\n");
});
const wss = new WebSocketServer({ server, maxPayload: 64 * 1024 });

function send(ws, obj) {
  if (ws && ws.readyState === 1) ws.send(JSON.stringify(obj));
}

function newCode() {
  for (let tries = 0; tries < 1000; tries++) {
    let c = "";
    for (let i = 0; i < 4; i++) c += LETTERS[Math.floor(Math.random() * LETTERS.length)];
    if (!rooms.has(c)) return c;
  }
  return null;
}

function leave(ws) {
  const code = ws.room;
  if (!code || !rooms.has(code)) return;
  const pair = rooms.get(code);
  rooms.delete(code);
  for (const other of pair) {
    if (other && other !== ws) {
      other.room = null;
      send(other, { op: "left" });
    }
  }
}

wss.on("connection", (ws) => {
  ws.alive = true;
  ws.on("pong", () => { ws.alive = true; });
  ws.on("message", (raw) => {
    let m;
    try { m = JSON.parse(raw); } catch (e) { return send(ws, { op: "error", why: "bad json" }); }
    if (m.op === "create") {
      leave(ws);
      const code = newCode();
      if (!code) return send(ws, { op: "error", why: "server full" });
      rooms.set(code, [ws, null]);
      ws.room = code;
      send(ws, { op: "created", room: code });
    } else if (m.op === "join") {
      const code = String(m.room || "").toUpperCase().trim();
      const pair = rooms.get(code);
      if (!pair) return send(ws, { op: "error", why: "no such room" });
      if (pair[1]) return send(ws, { op: "error", why: "room full" });
      leave(ws);
      pair[1] = ws;
      ws.room = code;
      send(pair[0], { op: "start", you: 0, room: code });
      send(pair[1], { op: "start", you: 1, room: code });
    } else if (m.op === "msg") {
      const pair = rooms.get(ws.room);
      if (!pair) return send(ws, { op: "error", why: "not in a room" });
      send(pair[0] === ws ? pair[1] : pair[0], { op: "msg", data: m.data });
    } else if (m.op === "leave") {
      leave(ws);
    }
  });
  ws.on("close", () => leave(ws));
});

// Latido: cierra conexiones muertas (y mantiene vivas las que pasan por proxies)
setInterval(() => {
  for (const ws of wss.clients) {
    if (!ws.alive) { ws.terminate(); continue; }
    ws.alive = false;
    ws.ping();
  }
}, 25000);

server.listen(PORT, () => console.log("relay listening on " + PORT));
