const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

const rooms = {};

wss.on('connection', (ws) => {
  console.log('Client connected');

  ws.on('message', (msg) => {
    console.log('Received:', msg.toString());
    let data;
    try {
      data = JSON.parse(msg);
    } catch (e) {
      ws.send(JSON.stringify({ error: 'Invalid JSON' }));
      return;
    }

    if (data.type === 'create_room') {
      const code = data.code;
      rooms[code] = [ws];
      ws.roomCode = code;
      ws.send(JSON.stringify({ type: 'room_created', code }));
      console.log(`Room created: ${code}`);
    } else if (data.type === 'join_room') {
      const code = data.code;
      if (rooms[code] && rooms[code].length === 1) {
        rooms[code].push(ws);
        ws.roomCode = code;
        ws.send(JSON.stringify({ type: 'room_joined', code }));
        // Notify both clients
        rooms[code].forEach(client => {
          if (client !== ws) {
            client.send(JSON.stringify({ type: 'opponent_joined', code }));
          }
        });
        console.log(`Room joined: ${code}`);
      } else {
        ws.send(JSON.stringify({ error: 'Room not found or full' }));
      }
    }
  });

  ws.on('close', () => {
    if (ws.roomCode && rooms[ws.roomCode]) {
      rooms[ws.roomCode] = rooms[ws.roomCode].filter(client => client !== ws);
      if (rooms[ws.roomCode].length === 0) {
        delete rooms[ws.roomCode];
        console.log(`Room deleted: ${ws.roomCode}`);
      }
    }
  });
});

console.log('WebSocket server started on ws://localhost:8080');