import React from 'react';

export default function AnalyticsCharts() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="font-bold text-lg text-white">System Analytics & Hazard Risk Heatmaps</h3>
        <p className="text-xs text-slate-400">Statistical breakdown of impact peaks, crash confidence scores & pothole frequency</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Hourly Crash Frequency Chart */}
        <div className="glass-card p-6">
          <h4 className="font-bold text-white text-base mb-4">Peak Riding Hours Crash Frequency</h4>
          <div className="h-48 flex items-end justify-between space-x-2 pt-6 pb-2 border-b border-slate-800 px-2">
            {[15, 25, 45, 80, 95, 60, 40, 75, 90, 100, 65, 30].map((val, i) => (
              <div key={i} className="flex-1 flex flex-col items-center group">
                <div
                  style={{ height: `${val}%` }}
                  className="w-full bg-gradient-to-t from-red-600 to-amber-500 rounded-t group-hover:from-red-500 group-hover:to-amber-400 transition"
                ></div>
                <span className="text-[10px] text-slate-500 mt-2 font-mono">{i * 2}h</span>
              </div>
            ))}
          </div>
          <div className="flex justify-between items-center mt-3 text-xs text-slate-400">
            <span>Peak Accident Risk Zone: 18:00 - 20:00 (Rush Hour)</span>
          </div>
        </div>

        {/* Severity Distribution */}
        <div className="glass-card p-6">
          <h4 className="font-bold text-white text-base mb-4">Pothole Severity Distribution</h4>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-xs font-semibold mb-1">
                <span className="text-red-400">HIGH (Deep > 6 inches / Rim Damage)</span>
                <span className="text-white">42% (77 Reports)</span>
              </div>
              <div className="w-full bg-slate-900 h-3 rounded-full overflow-hidden border border-slate-800">
                <div className="bg-red-600 h-full w-[42%] rounded-full"></div>
              </div>
            </div>

            <div>
              <div className="flex justify-between text-xs font-semibold mb-1">
                <span className="text-amber-400">MEDIUM (Moderate Asphalt Cracking)</span>
                <span className="text-white">38% (70 Reports)</span>
              </div>
              <div className="w-full bg-slate-900 h-3 rounded-full overflow-hidden border border-slate-800">
                <div className="bg-amber-500 h-full w-[38%] rounded-full"></div>
              </div>
            </div>

            <div>
              <div className="flex justify-between text-xs font-semibold mb-1">
                <span className="text-blue-400">LOW (Minor surface degradation)</span>
                <span className="text-white">20% (37 Reports)</span>
              </div>
              <div className="w-full bg-slate-900 h-3 rounded-full overflow-hidden border border-slate-800">
                <div className="bg-blue-500 h-full w-[20%] rounded-full"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
