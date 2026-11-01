import React from 'react';

const navItems = [
  { id: 'overview', label: 'Dashboard Overview', icon: '📊' },
  { id: 'live-riders', label: 'Live Riders Map', icon: '🏍️' },
  { id: 'incidents', label: 'Emergency Incidents', icon: '🚨' },
  { id: 'potholes', label: 'Pothole Reports', icon: '🕳️' },
  { id: 'users', label: 'Riders & Contacts', icon: '👥' },
  { id: 'notifications', label: 'Push Notifications', icon: '🔔' },
  { id: 'analytics', label: 'Analytics & Heatmaps', icon: '📈' },
  { id: 'logs', label: 'System Logs', icon: '💻' },
];

export default function Sidebar({ activeTab, setActiveTab, onLogout }) {
  return (
    <aside className="w-64 glass-panel min-h-screen p-5 flex flex-col justify-between border-r border-slate-800">
      <div>
        <div className="flex items-center space-x-3 mb-8 px-2">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-red-600 to-amber-500 flex items-center justify-center text-xl shadow-lg shadow-red-500/20 font-bold">
            🛡️
          </div>
          <div>
            <h1 className="font-extrabold text-lg text-white tracking-wide">Pothole Hazard</h1>
            <p className="text-xs text-red-400 font-medium tracking-wider uppercase">Admin Control</p>
          </div>
        </div>

        <nav className="space-y-1">
          {navItems.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center space-x-3 px-4 py-3 rounded-xl font-medium text-sm transition-all duration-200 ${
                  isActive
                    ? 'bg-gradient-to-r from-red-600 to-red-500 text-white shadow-lg shadow-red-600/30'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
                }`}
              >
                <span className="text-lg">{item.icon}</span>
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>
      </div>

      <div className="pt-6 border-t border-slate-800/80">
        <div className="flex items-center space-x-3 px-2 mb-4">
          <img
            src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100"
            alt="Admin"
            className="w-9 h-9 rounded-full ring-2 ring-red-500/50"
          />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-white truncate">System Admin</p>
            <p className="text-xs text-slate-400 truncate">admin@pothole.com</p>
          </div>
        </div>
        <button
          onClick={onLogout}
          className="w-full flex items-center justify-center space-x-2 py-2.5 px-4 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-400 hover:text-red-400 border border-slate-800 text-xs font-semibold transition"
        >
          <span>🚪 Sign Out</span>
        </button>
      </div>
    </aside>
  );
}
