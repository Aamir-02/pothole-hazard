import React from 'react';

export default function UsersList() {
  const users = [
    { id: 'USR-1', name: 'Alex Rider', email: 'alex@example.com', phone: '+1 555 019 2834', contactsCount: 4, rideScore: 98, distance: '142.5 km' },
    { id: 'USR-2', name: 'Carlos Mendez', email: 'carlos@example.com', phone: '+1 555 014 9912', contactsCount: 2, rideScore: 92, distance: '89.0 km' },
    { id: 'USR-3', name: 'Maria Santos', email: 'maria@example.com', phone: '+1 555 012 3344', contactsCount: 5, rideScore: 96, distance: '210.4 km' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="font-bold text-lg text-white">Registered Riders & Emergency Contacts</h3>
          <p className="text-xs text-slate-400">Manage user profiles, safety scores, and contact dispatch configurations</p>
        </div>
      </div>

      <div className="glass-card overflow-hidden">
        <table className="w-full text-left text-xs">
          <thead className="bg-slate-900/80 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider">
            <tr>
              <th className="p-4">Rider Name</th>
              <th className="p-4">Email</th>
              <th className="p-4">Phone</th>
              <th className="p-4">Emergency Contacts</th>
              <th className="p-4">Safety Score</th>
              <th className="p-4">Total Distance</th>
              <th className="p-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60 text-slate-300">
            {users.map((u) => (
              <tr key={u.id} className="hover:bg-slate-900/40 transition">
                <td className="p-4 font-bold text-white flex items-center space-x-3">
                  <div className="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center font-bold text-red-400">
                    {u.name[0]}
                  </div>
                  <span>{u.name}</span>
                </td>
                <td className="p-4 text-slate-400">{u.email}</td>
                <td className="p-4 font-mono text-slate-300">{u.phone}</td>
                <td className="p-4">
                  <span className="bg-slate-800 text-slate-200 px-2.5 py-1 rounded-full text-[11px] font-bold">
                    {u.contactsCount} / 10 Contacts
                  </span>
                </td>
                <td className="p-4 font-extrabold text-emerald-400">{u.rideScore} / 100</td>
                <td className="p-4 font-semibold text-white">{u.distance}</td>
                <td className="p-4 text-right">
                  <button className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold rounded-lg transition">
                    Inspect Profile
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
