import React, { useState } from 'react';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import DashboardOverview from './components/DashboardOverview';
import LiveRidersMap from './components/LiveRidersMap';
import IncidentsList from './components/IncidentsList';
import PotholeReports from './components/PotholeReports';
import UsersList from './components/UsersList';
import NotificationsCenter from './components/NotificationsCenter';
import AnalyticsCharts from './components/AnalyticsCharts';
import SystemLogs from './components/SystemLogs';

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(true); // Default logged in for demo
  const [adminEmail, setAdminEmail] = useState('admin@potholehazard.com');
  const [adminPassword, setAdminPassword] = useState('AdminPothole2026!');
  const [activeTab, setActiveTab] = useState('overview');

  const handleLogin = (e) => {
    e.preventDefault();
    if (adminEmail && adminPassword) {
      setIsAuthenticated(true);
    }
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
        <div className="w-full max-w-md glass-panel p-8 rounded-2xl shadow-2xl border border-slate-800">
          <div className="text-center mb-8">
            <div className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-red-600 to-amber-500 flex items-center justify-center text-3xl mx-auto mb-4 shadow-lg shadow-red-500/30">
              🛡️
            </div>
            <h1 className="text-2xl font-extrabold text-white tracking-tight">Pothole Hazard</h1>
            <p className="text-xs text-red-400 font-semibold uppercase tracking-wider mt-1">Admin Operations Portal</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-bold uppercase text-slate-400 mb-1.5">Admin Email</label>
              <input
                type="email"
                value={adminEmail}
                onChange={(e) => setAdminEmail(e.target.value)}
                className="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-xl text-white font-medium text-sm focus:outline-none focus:border-red-500"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase text-slate-400 mb-1.5">Password</label>
              <input
                type="password"
                value={adminPassword}
                onChange={(e) => setAdminPassword(e.target.value)}
                className="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-xl text-white font-medium text-sm focus:outline-none focus:border-red-500"
                required
              />
            </div>

            <button
              type="submit"
              className="w-full py-3 bg-gradient-to-r from-red-600 to-red-500 hover:from-red-500 hover:to-red-400 text-white font-bold text-sm rounded-xl shadow-lg shadow-red-600/30 transition"
            >
              Sign In to Command Center
            </button>
          </form>
        </div>
      </div>
    );
  }

  const renderTabContent = () => {
    switch (activeTab) {
      case 'overview':
        return <DashboardOverview onNavigate={setActiveTab} />;
      case 'live-riders':
        return <LiveRidersMap />;
      case 'incidents':
        return <IncidentsList />;
      case 'potholes':
        return <PotholeReports />;
      case 'users':
        return <UsersList />;
      case 'notifications':
        return <NotificationsCenter />;
      case 'analytics':
        return <AnalyticsCharts />;
      case 'logs':
        return <SystemLogs />;
      default:
        return <DashboardOverview onNavigate={setActiveTab} />;
    }
  };

  const getTabTitle = () => {
    switch (activeTab) {
      case 'overview':
        return 'System Overview & Live Monitor';
      case 'live-riders':
        return 'Live GPS Rider Telemetry Map';
      case 'incidents':
        return 'Emergency Crash Incidents Log';
      case 'potholes':
        return 'Community Reported Potholes';
      case 'users':
        return 'Riders & Emergency Contacts';
      case 'notifications':
        return 'Firebase Push Dispatcher';
      case 'analytics':
        return 'Risk Analytics & Heatmaps';
      case 'logs':
        return 'System Audit & Logs';
      default:
        return 'Admin Dashboard';
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-950">
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} onLogout={handleLogout} />
      
      <div className="flex-1 flex flex-col min-w-0">
        <Header title={getTabTitle()} />
        <main className="p-8 flex-1 overflow-y-auto">
          {renderTabContent()}
        </main>
      </div>
    </div>
  );
}
