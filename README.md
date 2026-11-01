# 🛡️ Pothole Hazard - Production Motorcycle Crash & Pothole Defense System

**Pothole Hazard** is a production-ready, full-stack Android & Web platform built for motorcycle riders. It continuously monitors rider motion using sensor fusion (Accelerometer + Gyroscope + GPS + Speed) to intelligently detect severe pothole impacts and motorcycle crashes while minimizing false positives. When an accident is confirmed (>90% confidence), the app triggers an immediate full-screen emergency mode with a loud siren, continuous vibration, and a 15-second countdown timer. If unacknowledged, it automatically dispatches emergency SMS alerts with live Google Maps coordinates to emergency contacts, sends Firebase FCM push notifications, uploads incident telemetry to MongoDB, and notifies nearby riders.

---

## 🏗️ Architecture Overview

```mermaid
graph TD
    subgraph Mobile App (Flutter Android)
        A[Sensor Fusion Engine] --> B[Background Foreground Service]
        B --> C{Crash Confidence > 90%?}
        C -- YES --> D[15s Emergency Red Screen + Siren/Vib]
        D -- Countdown Expired / SOS Clicked --> E[Auto SMS Dispatcher]
        D -- I'm Safe Clicked --> F[Cancel Emergency Mode]
        E --> G[Twilio / Native SMS Intent]
        E --> H[REST API Telemetry Sync]
    end

    subgraph Backend Microservices (Node.js + Socket.io)
        H --> I[Express API Controllers]
        I --> J[(MongoDB Atlas)]
        I --> K[Firebase Admin Push SDK]
        I --> L[Real-Time Socket.io Server]
    end

    subgraph Admin Web Operations (React + Vite)
        L --> M[Live GPS Rider Map Tracker]
        I --> N[Incident Audit & Pothole Management]
    end
```

---

## 🧠 Sensor Fusion Crash Detection Specification

To eliminate false alarms (such as walking, speed breakers, or dropping the phone while stationary), the system evaluates multiple sensor streams simultaneously:

1. **Accelerometer Vector ($G$-Force)**: Peak G-force threshold $G \ge 3.8g$ ($37.2 \, m/s^2$).
2. **Gyroscope Angular Velocity**: Angular rotational velocity $\omega \ge 4.0 \, rad/s$ (bike tilt/flip).
3. **GPS Speed Drop**: Sudden velocity deceleration from $v_{before} > 15 \, km/h$ to $v_{after} < 5 \, km/h$ in $<1.5s$.
4. **Phone Orientation Shift**: Pitch/Roll angle shift $\theta > 45^\circ$.
5. **Post-Impact Immobility**: Phone motionless on ground post-impact.

**Trigger Condition**: Accident Alert triggers **only when Confidence Score $\ge 90\%$**.

---

## 📱 Emergency SMS Format

```text
🚨 EMERGENCY ALERT 🚨

Possible motorcycle accident detected.

Rider:
{Rider Name}

Time:
{Current Time}

Location:
https://maps.google.com/?q={Latitude},{Longitude}

Please check immediately.
```

---

## ⚡ Quick Start & Run Instructions

### 1. Node.js Express Backend
```bash
cd backend
npm install
npm run dev
# Running on http://localhost:5000 | Socket.io on port 5000
```

### 2. Sensor Fusion Unit Tests
```bash
cd backend
node tests/sensorFusion.test.js
```

### 3. React Admin Control Dashboard
```bash
cd admin_dashboard
npm install
npm run dev
# Dashboard running on http://localhost:3000
```

### 4. Flutter Android Application
```bash
cd mobile_app
flutter pub get
flutter run
```

### 5. Docker One-Command Stack
```bash
docker-compose up --build
```

---

## 📡 REST API Documentation

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Register new rider profile |
| `POST` | `/api/auth/login` | JWT Authentication login |
| `POST` | `/api/auth/google-login` | Google OAuth authentication |
| `GET`  | `/api/auth/profile` | Retrieve rider settings & score |
| `POST` | `/api/ride/start` | Start foreground ride telemetry session |
| `POST` | `/api/ride/stop` | End ride session & compute fuel/calories |
| `POST` | `/api/incident` | Record crash event & dispatch SMS/FCM alerts |
| `POST` | `/api/incident/cancel` | Cancel SOS alert (Rider clicked "I'm Safe") |
| `GET`  | `/api/contacts` | Fetch emergency contacts (max 10) |
| `POST` | `/api/contacts` | Add new emergency contact |
| `GET`  | `/api/potholes` | Fetch nearby active potholes with heatmap |
| `POST` | `/api/potholes` | Report new pothole with photo & auto duplicate check |
| `POST` | `/api/potholes/:id/upvote` | Upvote/confirm community pothole |
| `POST` | `/api/notifications/send-sos` | Trigger manual SOS alert broadcast |

---

## 🔒 Security & Performance Features

- **JWT Authentication & Passwords**: Passwords salted & hashed with `bcryptjs` (10 rounds).
- **Rate Limiting**: `express-rate-limit` prevents brute force and DDoS.
- **Security Headers**: `helmet` and `cors` enabled.
- **GeoSpatial Indexing**: 2DSphere indexes on MongoDB for $O(1)$ spatial queries.
- **Auto Duplicate Suppression**: Pothole reports submitted within 30m radius automatically convert to upvotes.
