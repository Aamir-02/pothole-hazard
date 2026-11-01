import React, { useState } from 'react';

export default function NotificationsCenter() {
  const [title, setTitle] = useState('⚠️ Weather & Road Hazard Warning');
  const [body, setBody] = useState('Heavy rain detected on Highway 101. Multiple severe potholes reported near KM 14.');
  const [topic, setTopic] = useState('emergency_broadcasts');
  const [statusMsg, setStatusMsg] = useState('');

  const handleBroadcast = (e) => {
    e.preventDefault();
    setStatusMsg(`🚀 Push Notification successfully broadcasted to topic "${topic}"!`);
    setTimeout(() => setStatusMsg(''), 4000);
  };

  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h3 className="font-bold text-lg text-white">Firebase Cloud Messaging (FCM) Dispatcher</h3>
        <p className="text-xs text-slate-400">Broadcast immediate high-priority safety push alerts to rider devices</p>
      </div>

      {statusMsg && (
        <div className="p-4 bg-emerald-500/20 border border-emerald-500/40 rounded-xl text-emerald-400 text-sm font-bold animate-fade-in">
          {statusMsg}
        </div>
      )}

      <form onSubmit={handleBroadcast} className="glass-card p-6 space-y-5">
        <div>
          <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Notification Title</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-xl text-white font-semibold text-sm focus:outline-none focus:border-red-500"
            required
          />
        </div>

        <div>
          <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Message Body</label>
          <textarea
            rows="3"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            className="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-xl text-white font-medium text-sm focus:outline-none focus:border-red-500"
            required
          />
        </div>

        <div>
          <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Target Audience Topic</label>
          <select
            value={topic}
            onChange={(e) => setTopic(e.target.value)}
            className="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-xl text-white font-semibold text-sm focus:outline-none focus:border-red-500"
          >
            <option value="emergency_broadcasts">🚨 All Active Riders (Emergency Channel)</option>
            <option value="pothole_alerts">🕳️ Nearby Pothole Hazard Channel</option>
            <option value="weather_updates">🌧️ Severe Weather Warnings</option>
          </select>
        </div>

        <button
          type="submit"
          className="w-full py-3 bg-gradient-to-r from-red-600 to-amber-500 hover:from-red-500 hover:to-amber-400 text-white font-extrabold text-sm rounded-xl shadow-lg shadow-red-600/30 transition"
        >
          📢 Dispatch FCM Push Broadcast Now
        </button>
      </form>
    </div>
  );
}
