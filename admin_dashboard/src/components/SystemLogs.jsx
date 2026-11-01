import React from 'react';

export default function SystemLogs() {
  const logs = [
    { time: '2026-08-02 01:22:04', level: 'INFO', msg: '[Socket.io] Client connected: socket_id_89234' },
    { time: '2026-08-02 01:10:00', level: 'WARN', msg: '[SensorFusion] High Confidence Accident Detected (98%) for User Alex Rider' },
    { time: '2026-08-02 01:10:02', level: 'SUCCESS', msg: '[Twilio SMS] Emergency Alert SMS successfully dispatched to +15550192834' },
    { time: '2026-08-02 00:54:12', level: 'INFO', msg: '[Potholes API] Auto-duplicate check passed for report at (37.7769, -122.4164)' },
    { time: '2026-08-02 00:30:15', level: 'INFO', msg: '[Database] MongoDB Connected: cluster0.pothole.mongodb.net' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h3 className="font-bold text-lg text-white">System Audit & Real-time Logs</h3>
        <p className="text-xs text-slate-400">Live operational events, socket pings, and backend service trace logs</p>
      </div>

      <div className="glass-card p-4 font-mono text-xs text-slate-300 space-y-2 bg-slate-950/90 border border-slate-800 rounded-xl max-h-[500px] overflow-y-auto">
        {logs.map((log, index) => (
          <div key={index} className="flex items-start space-x-3 p-2 hover:bg-slate-900 rounded transition">
            <span className="text-slate-500 shrink-0">{log.time}</span>
            <span
              className={`px-1.5 py-0.5 rounded text-[10px] font-bold shrink-0 ${
                log.level === 'WARN'
                  ? 'bg-red-500/20 text-red-400 border border-red-500/40'
                  : log.level === 'SUCCESS'
                  ? 'bg-emerald-500/20 text-emerald-400'
                  : 'bg-blue-500/20 text-blue-400'
              }`}
            >
              {log.level}
            </span>
            <span className="text-slate-200">{log.msg}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
