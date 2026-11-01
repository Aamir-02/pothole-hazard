import React, { useState } from 'react';

export default function PotholeReports() {
  const [reports, setReports] = useState([
    {
      id: 'PTH-101',
      reporter: 'Alex Rider',
      roadType: 'City Street',
      severity: 'HIGH',
      upvotes: 18,
      address: 'Oakland Ave & 4th Street (37.7769, -122.4164)',
      photoUrl: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=400',
      description: 'Deep 8-inch severe pothole right in center lane!',
      status: 'ACTIVE',
    },
    {
      id: 'PTH-102',
      reporter: 'Carlos Mendez',
      roadType: 'Highway',
      severity: 'MEDIUM',
      upvotes: 9,
      address: 'Expressway Service Lane (37.7709, -122.4214)',
      photoUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=400',
      description: 'Cracked asphalt erosion causing rim damage.',
      status: 'ACTIVE',
    },
    {
      id: 'PTH-103',
      reporter: 'Maria Santos',
      roadType: 'Rural Road',
      severity: 'LOW',
      upvotes: 3,
      address: 'Bay View Boulevard',
      photoUrl: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=400',
      description: 'Loose gravel and shallow pothole near curve.',
      status: 'ACTIVE',
    },
  ]);

  const handleHideDuplicate = (id) => {
    setReports(reports.filter((r) => r.id !== id));
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="font-bold text-lg text-white">Community Pothole Hazard Reports</h3>
          <p className="text-xs text-slate-400">Crowdsourced pothole locations with auto duplicate suppression</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {reports.map((report) => (
          <div key={report.id} className="glass-card overflow-hidden flex flex-col justify-between">
            <div>
              <div className="relative h-44 bg-slate-900 overflow-hidden">
                <img src={report.photoUrl} alt="Pothole" className="w-full h-full object-cover" />
                <div className="absolute top-3 left-3 bg-slate-950/80 backdrop-blur px-2.5 py-1 rounded-full text-xs font-bold text-white border border-slate-700">
                  👍 {report.upvotes} Community Upvotes
                </div>
                <div
                  className={`absolute top-3 right-3 px-2.5 py-1 rounded-full text-[10px] font-extrabold tracking-wider ${
                    report.severity === 'HIGH'
                      ? 'bg-red-600 text-white'
                      : report.severity === 'MEDIUM'
                      ? 'bg-amber-500 text-slate-950'
                      : 'bg-blue-600 text-white'
                  }`}
                >
                  {report.severity} SEVERITY
                </div>
              </div>

              <div className="p-5 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-red-400">{report.id}</span>
                  <span className="text-xs text-slate-400 font-semibold">{report.roadType}</span>
                </div>
                <h4 className="font-bold text-white text-sm">{report.address}</h4>
                <p className="text-xs text-slate-300 line-clamp-2">{report.description}</p>
                <div className="pt-2 text-[11px] text-slate-400 flex justify-between border-t border-slate-800">
                  <span>Reporter: {report.reporter}</span>
                  <span className="text-emerald-400 font-semibold">● {report.status}</span>
                </div>
              </div>
            </div>

            <div className="p-4 bg-slate-900/60 border-t border-slate-800 flex space-x-2">
              <button className="flex-1 py-2 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold rounded-xl transition">
                ✓ Validate Report
              </button>
              <button
                onClick={() => handleHideDuplicate(report.id)}
                className="px-3 py-2 bg-slate-800 hover:bg-red-600/20 text-slate-400 hover:text-red-400 text-xs font-bold rounded-xl transition"
              >
                Hide Duplicate
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
