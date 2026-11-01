import React from 'react';

export default function Header({ title }) {
  return (
    <header className="glass-panel sticky top-0 z-30 px-8 py-4 flex items-center justify-between border-b border-slate-800">
      <div>
        <h2 className="text-xl font-bold text-white tracking-tight">{title}</h2>
        <p className="text-xs text-slate-400">Real-time rider crash monitoring & hazard dispatch system</p>
      </div>

      <div className="flex items-center space-x-4">
        <div className="flex items-center space-x-2 bg-emerald-500/10 border border-emerald-500/30 px-3 py-1.5 rounded-full">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span className="text-xs font-semibold text-emerald-400">Backend Socket Connected</span>
        </div>

        <button className="p-2.5 rounded-xl bg-slate-900 border border-slate-800 text-slate-300 hover:text-white transition">
          🔔
        </button>
      </div>
    </header>
  );
}
