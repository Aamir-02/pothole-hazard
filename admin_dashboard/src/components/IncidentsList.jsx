import React, { useState } from 'react';

export default function IncidentsList() {
  const [incidents] = useState([
    {
      id: 'INC-901',
      rider: 'Alex Rider',
      phone: '+1 555 019 2834',
      time: '2026-08-02 01:10:00',
      location: 'Expressway Flyover KM 12 (37.7749, -122.4194)',
      confidence: 98,
      accelG: 4.8,
      gyroRadSec: 6.2,
      severity: 'CRITICAL',
      status: 'SENT',
      contactsNotified: 2,
    },
    {
      id: 'INC-899',
      rider: 'Carlos Mendez',
      phone: '+1 555 014 9912',
      time: '2026-08-01 18:45:00',
      location: '5th Ave & Pine Street (37.7833, -122.4167)',
      confidence: 92,
      accelG: 4.1,
      gyroRadSec: 4.5,
      severity: 'HIGH',
      status: 'SENT',
      contactsNotified: 3,
    },
    {
      id: 'INC-895',
      rider: 'Sophia K.',
      phone: '+1 555 018 4421',
      time: '2026-08-01 14:20:00',
      location: 'Downtown Alleyway (37.7651, -122.4241)',
      confidence: 84,
      accelG: 3.5,
      gyroRadSec: 2.1,
      severity: 'MEDIUM',
      status: 'CONFIRMED_SAFE',
      contactsNotified: 0,
    },
  ]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="font-bold text-lg text-white">Emergency Crash Incidents</h3>
          <p className="text-xs text-slate-400">Triggered by Multi-Sensor Fusion Engine (Accel + Gyro + GPS Speed Drop)</p>
        </div>
        <button className="px-4 py-2 bg-red-600 hover:bg-red-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-red-600/30 transition">
          + Test Manual SOS Broadcast
        </button>
      </div>

      <div className="glass-card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-900/80 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
              <tr>
                <th className="p-4">Incident ID</th>
                <th className="p-4">Rider</th>
                <th className="p-4">Time & Location</th>
                <th className="p-4">Confidence</th>
                <th className="p-4">Sensor Telemetry</th>
                <th className="p-4">Severity</th>
                <th className="p-4">Status</th>
                <th className="p-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 text-slate-300">
              {incidents.map((inc) => (
                <tr key={inc.id} className="hover:bg-slate-900/40 transition">
                  <td className="p-4 font-bold text-white">{inc.id}</td>
                  <td className="p-4">
                    <p className="font-bold text-white">{inc.rider}</p>
                    <p className="text-slate-400">{inc.phone}</p>
                  </td>
                  <td className="p-4 max-w-xs">
                    <p className="font-semibold text-slate-200">{inc.location}</p>
                    <p className="text-slate-500 text-[11px] mt-0.5">{inc.time}</p>
                  </td>
                  <td className="p-4">
                    <span className="font-extrabold text-red-400 text-sm">{inc.confidence}%</span>
                  </td>
                  <td className="p-4 font-mono text-[11px]">
                    <div>Accel: <span className="text-amber-400 font-bold">{inc.accelG}G</span></div>
                    <div>Gyro: <span className="text-blue-400 font-bold">{inc.gyroRadSec} rad/s</span></div>
                  </td>
                  <td className="p-4">
                    <span
                      className={`px-2.5 py-1 rounded-full text-[10px] font-extrabold tracking-wider ${
                        inc.severity === 'CRITICAL'
                          ? 'bg-red-500/20 text-red-400 border border-red-500/40'
                          : inc.severity === 'HIGH'
                          ? 'bg-amber-500/20 text-amber-400 border border-amber-500/40'
                          : 'bg-blue-500/20 text-blue-400 border border-blue-500/40'
                      }`}
                    >
                      {inc.severity}
                    </span>
                  </td>
                  <td className="p-4">
                    <span
                      className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                        inc.status === 'SENT' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-800 text-slate-400'
                      }`}
                    >
                      {inc.status} ({inc.contactsNotified} SMS)
                    </span>
                  </td>
                  <td className="p-4 text-right space-x-2">
                    <button className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-lg transition">
                      View Map
                    </button>
                    <button className="px-3 py-1 bg-red-600/20 hover:bg-red-600 text-red-400 hover:text-white text-xs font-bold rounded-lg transition">
                      Dispatch Help
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
