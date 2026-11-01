import React, { useState } from 'react';

export default function LiveRidersMap() {
  const [selectedRider, setSelectedRider] = useState(null);

  const riders = [
    { id: '1', name: 'Alex Rider', speed: 48, battery: 88, lat: 37.7749, lng: -122.4194, status: 'RIDING', score: 98, lastUpdate: 'Just now' },
    { id: '2', name: 'Maria Santos', speed: 55, battery: 64, lat: 37.7833, lng: -122.4167, status: 'RIDING', score: 92, lastUpdate: '2s ago' },
    { id: '3', name: 'James Wilson', speed: 0, battery: 42, lat: 37.7651, lng: -122.4241, status: 'STOPPED', score: 85, lastUpdate: '15s ago' },
    { id: '4', name: 'Carlos Mendez', speed: 62, battery: 95, lat: 37.7599, lng: -122.4148, status: 'RIDING', score: 95, lastUpdate: '1s ago' },
  ];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2 glass-card p-6 flex flex-col justify-between">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="font-bold text-lg text-white">Live GPS Rider Tracker</h3>
            <p className="text-xs text-slate-400">Streamed via Socket.io WebSocket Telemetry Server</p>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-ping"></span>
            <span className="text-xs font-bold text-emerald-400">4 Active Socket Streams</span>
          </div>
        </div>

        <div className="relative h-96 bg-slate-900 rounded-xl overflow-hidden border border-slate-800 flex items-center justify-center">
          <div className="absolute inset-0 bg-[radial-gradient(#1e293b_1px,transparent_1px)] [background-size:16px_16px] opacity-40"></div>
          
          <div className="relative w-full h-full p-8 flex flex-col justify-between">
            <div className="flex justify-between items-start">
              <div className="bg-slate-950/80 backdrop-blur border border-slate-800 p-3 rounded-xl">
                <p className="text-xs font-semibold text-slate-400">Center Bounding Box</p>
                <p className="text-sm font-bold text-white">San Francisco Urban Region</p>
              </div>
              <div className="bg-slate-950/80 backdrop-blur border border-slate-800 p-2 rounded-xl flex space-x-2">
                <button className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-xs font-bold text-white rounded-lg">Satellite</button>
                <button className="px-3 py-1 bg-red-600 text-xs font-bold text-white rounded-lg">Hazard Heatmap</button>
              </div>
            </div>

            {/* Interactive Map Visual Hotspots */}
            <div className="relative w-full h-48 my-auto border border-slate-800 rounded-2xl bg-slate-950/60 p-4">
              {riders.map((r, i) => (
                <button
                  key={r.id}
                  onClick={() => setSelectedRider(r)}
                  style={{ top: `${20 + i * 20}%`, left: `${15 + i * 22}%` }}
                  className={`absolute transform -translate-x-1/2 -translate-y-1/2 flex items-center space-x-2 px-3 py-1.5 rounded-full font-bold text-xs shadow-xl transition-all ${
                    selectedRider?.id === r.id
                      ? 'bg-gradient-to-r from-red-600 to-amber-500 text-white ring-4 ring-red-500/30 scale-110'
                      : 'bg-slate-800 text-slate-200 border border-slate-700 hover:bg-slate-700'
                  }`}
                >
                  <span>🏍️</span>
                  <span>{r.name}</span>
                  <span className="bg-slate-900/80 text-emerald-400 px-1.5 py-0.5 rounded text-[10px]">
                    {r.speed} km/h
                  </span>
                </button>
              ))}
            </div>

            <div className="flex justify-between items-center text-xs text-slate-400">
              <span>GPS Precision: 2.1 meters</span>
              <span>Updated automatically every 500ms</span>
            </div>
          </div>
        </div>
      </div>

      {/* Selected Rider Details Panel */}
      <div className="glass-card p-6">
        <h3 className="font-bold text-lg text-white mb-4">Rider Telemetry Inspector</h3>

        {selectedRider ? (
          <div className="space-y-4">
            <div className="flex items-center space-x-3 p-3 bg-slate-900 rounded-xl border border-slate-800">
              <div className="w-12 h-12 rounded-full bg-red-600/20 text-red-400 flex items-center justify-center text-2xl font-bold">
                🏍️
              </div>
              <div>
                <h4 className="font-bold text-white text-base">{selectedRider.name}</h4>
                <span className="text-xs font-semibold text-emerald-400">● Status: {selectedRider.status}</span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                <span className="text-xs text-slate-400 font-medium">Live Speed</span>
                <p className="text-xl font-extrabold text-white">{selectedRider.speed} <span className="text-xs font-normal">km/h</span></p>
              </div>

              <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                <span className="text-xs text-slate-400 font-medium">Battery</span>
                <p className="text-xl font-extrabold text-emerald-400">{selectedRider.battery}%</p>
              </div>

              <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                <span className="text-xs text-slate-400 font-medium">Safety Score</span>
                <p className="text-xl font-extrabold text-amber-400">{selectedRider.score}/100</p>
              </div>

              <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                <span className="text-xs text-slate-400 font-medium">GPS Ping</span>
                <p className="text-sm font-bold text-slate-200 mt-1">{selectedRider.lastUpdate}</p>
              </div>
            </div>

            <div className="p-4 bg-slate-900/80 rounded-xl border border-slate-800 text-xs space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-400">Latitude:</span>
                <span className="font-mono text-white">{selectedRider.lat}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400">Longitude:</span>
                <span className="font-mono text-white">{selectedRider.lng}</span>
              </div>
            </div>

            <button className="w-full py-2.5 bg-red-600 hover:bg-red-500 text-white text-xs font-bold rounded-xl shadow-lg shadow-red-600/30 transition">
              Dispatch Safety Check Push Alert
            </button>
          </div>
        ) : (
          <div className="text-center py-16 text-slate-500 text-sm">
            <span className="text-4xl block mb-2">📍</span>
            Select a rider marker on the map to inspect live sensor readings
          </div>
        )}
      </div>
    </div>
  );
}
