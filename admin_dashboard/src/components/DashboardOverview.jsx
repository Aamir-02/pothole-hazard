import React from 'react';

export default function DashboardOverview({ onNavigate }) {
  const stats = [
    { title: 'Active Riders', value: '42', change: '+12% this hour', color: 'from-blue-600 to-indigo-600', icon: '🏍️' },
    { title: 'Incidents Today', value: '3', change: '-25% vs yesterday', color: 'from-red-600 to-rose-600', icon: '🚨' },
    { title: 'Potholes Reported', value: '184', change: '+24 new today', color: 'from-amber-600 to-orange-600', icon: '🕳️' },
    { title: 'Emergency SMS Sent', value: '12', change: '100% delivered', color: 'from-emerald-600 to-teal-600', icon: '💬' },
  ];

  const recentIncidents = [
    { id: 'INC-901', rider: 'Alex Rider', time: '12 mins ago', confidence: '98%', status: 'SENT', location: 'Expressway Flyover KM 12' },
    { id: 'INC-899', rider: 'Carlos M.', time: '1 hour ago', confidence: '92%', status: 'SENT', location: '5th Ave & Pine Street' },
    { id: 'INC-895', rider: 'Sophia K.', time: '3 hours ago', confidence: '84%', status: 'CANCELLED', location: 'Downtown Alleyway' },
  ];

  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {stats.map((stat, idx) => (
          <div key={idx} className="glass-card p-5 flex flex-col justify-between">
            <div className="flex items-center justify-between mb-4">
              <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{stat.title}</span>
              <span className="text-2xl">{stat.icon}</span>
            </div>
            <div>
              <div className="text-3xl font-extrabold text-white tracking-tight">{stat.value}</div>
              <p className="text-xs text-slate-400 mt-1 font-medium">{stat.change}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Main Grid Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Live Map Preview Card */}
        <div className="lg:col-span-2 glass-card p-6 flex flex-col justify-between">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="font-bold text-lg text-white">Live Rider Telemetry Map</h3>
              <p className="text-xs text-slate-400">Monitoring real-time GPS coordinates & crash confidence scores</p>
            </div>
            <button
              onClick={() => onNavigate('live-riders')}
              className="px-3.5 py-1.5 rounded-lg bg-red-600/20 text-red-400 hover:bg-red-600 hover:text-white text-xs font-bold transition border border-red-500/30"
            >
              Open Full Screen Map ↗
            </button>
          </div>

          <div className="relative h-64 bg-slate-900 rounded-xl overflow-hidden border border-slate-800 flex items-center justify-center">
            {/* Visual Simulated Map Graphic */}
            <div className="absolute inset-0 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-950 opacity-90"></div>
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="relative w-4/5 h-4/5 border border-dashed border-slate-700 rounded-2xl flex items-center justify-center">
                <span className="absolute top-4 left-4 bg-slate-950/80 px-3 py-1 rounded-full text-xs font-bold text-slate-300 border border-slate-700">
                  📍 San Francisco Metropolitan Zone (42 Active Riders)
                </span>
                
                {/* Rider Markers */}
                <div className="absolute top-1/3 left-1/4 animate-bounce flex items-center space-x-2 bg-emerald-600 text-white px-2 py-1 rounded-lg text-xs font-bold shadow-lg">
                  <span>🏍️ Alex R. (45 km/h)</span>
                </div>
                <div className="absolute bottom-1/4 right-1/3 flex items-center space-x-2 bg-blue-600 text-white px-2 py-1 rounded-lg text-xs font-bold shadow-lg">
                  <span>🏍️ Maria P. (52 km/h)</span>
                </div>
                <div className="absolute top-1/2 right-1/4 animate-pulse flex items-center space-x-2 bg-red-600 text-white px-2.5 py-1 rounded-lg text-xs font-bold shadow-lg shadow-red-500/50">
                  <span>🚨 IMPACT! INC-901</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Recent Incident Feed */}
        <div className="glass-card p-6 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-lg text-white">Recent Crashes & Alerts</h3>
              <span className="px-2 py-0.5 rounded bg-red-500/20 text-red-400 text-xs font-bold">LIVE</span>
            </div>

            <div className="space-y-3">
              {recentIncidents.map((inc) => (
                <div key={inc.id} className="p-3 bg-slate-900/60 rounded-xl border border-slate-800 hover:border-slate-700 transition">
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-bold text-sm text-white">{inc.rider}</span>
                    <span
                      className={`text-xs px-2 py-0.5 rounded font-bold ${
                        inc.status === 'SENT' ? 'bg-red-600/30 text-red-400 border border-red-500/30' : 'bg-slate-700 text-slate-300'
                      }`}
                    >
                      {inc.status} ({inc.confidence})
                    </span>
                  </div>
                  <p className="text-xs text-slate-400 truncate">{inc.location}</p>
                  <p className="text-xs text-slate-500 mt-1">{inc.time}</p>
                </div>
              ))}
            </div>
          </div>

          <button
            onClick={() => onNavigate('incidents')}
            className="w-full mt-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold rounded-xl transition"
          >
            View All Incidents →
          </button>
        </div>
      </div>
    </div>
  );
}
