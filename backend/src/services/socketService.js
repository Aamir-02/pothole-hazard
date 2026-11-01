const socketIo = require('socket.io');

let io = null;

const initSocket = (server) => {
  io = socketIo(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  io.on('connection', (socket) => {
    console.log(`[Socket.io] Client connected: ${socket.id}`);

    // Join room (e.g. user specific room or 'admin' room)
    socket.on('join_room', (roomName) => {
      socket.join(roomName);
      console.log(`[Socket.io] Socket ${socket.id} joined room: ${roomName}`);
    });

    // Rider telemetry update stream
    socket.on('rider_telemetry', (data) => {
      // Broadcast live rider location & speed to admin room
      socket.to('admin_room').emit('live_rider_update', {
        socketId: socket.id,
        userId: data.userId,
        riderName: data.riderName,
        latitude: data.latitude,
        longitude: data.longitude,
        speedKmh: data.speedKmh,
        batteryPercent: data.batteryPercent,
        timestamp: new Date(),
      });
    });

    // Handle SOS alert trigger from rider
    socket.on('trigger_sos_event', (sosData) => {
      console.log(`[Socket.io] EMERGENCY SOS EVENT TRIGGERED by ${sosData.riderName}`);
      io.emit('emergency_alert_broadcast', sosData);
    });

    socket.on('disconnect', () => {
      console.log(`[Socket.io] Client disconnected: ${socket.id}`);
    });
  });

  return io;
};

const getIo = () => {
  if (!io) {
    throw new Error('Socket.io not initialized!');
  }
  return io;
};

module.exports = {
  initSocket,
  getIo,
};
