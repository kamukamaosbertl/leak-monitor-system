

# 📘 Leak Monitor System

A real-time water leak detection and monitoring system that provides instant alerts, user response tracking, and detailed reporting through a mobile application.

---

## 🚀 Overview

The **Leak Monitor System** is designed to detect water leaks using sensor data and provide real-time monitoring through a mobile app.

The system integrates:

* 📡 Real-time sensor data (WebSockets)
* 📱 Mobile application (Flutter)
* ⚙️ Backend server (Django REST API)
* 🔔 Push notifications (Firebase Cloud Messaging)

---

## 🧠 Key Features

* ✅ Real-time leak detection
* ✅ Live dashboard updates
* ✅ Push notifications for alerts
* ✅ Role-based access control
* ✅ Alert response tracking
* ✅ Maintenance request system
* ✅ Report generation (PDF & CSV)
* ✅ Google Sign-In authentication

---

## 🏗️ System Architecture

```text
Sensors → WebSocket → Django Backend → Database
                ↓
        Leak Detection Logic
                ↓
     Alerts + Push Notifications (FCM)
                ↓
          Flutter Mobile App
```

---

## ⚙️ Technologies Used

### Frontend

* Flutter (Dart)
* Provider (state management)
* HTTP package

### Backend

* Django
* Django REST Framework
* Django Channels (WebSockets)

### Database

* PostgreSQL

### Notifications

* Firebase Cloud Messaging (FCM)

---

## 👥 User Roles

### 🔑 Super Admin

* Full system control
* Manage users and roles
* Configure system

### 🧑‍💼 Admin

* Monitor system activity
* Manage alerts and reports

### 🧰 Technician

* Respond to alerts
* Update maintenance tasks

### 👷 Worker

* View alerts
* Request assistance

### 👀 Viewer

* Read-only access

---

## 🔔 How It Works

1. Sensors send water flow data continuously
2. Backend processes data in real-time
3. Leak is detected using flow difference (delta)
4. System generates:

   * Alert
   * Notification
   * Stored event
5. Users respond via mobile app
6. Reports are generated from stored leak events

---

## 📱 Installation (Android)

### Build APK

```bash
flutter build apk --release
```

### Locate APK

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Install

* Transfer APK to phone
* Enable "Install unknown apps"
* Install and open

---

## 🔧 Setup Instructions

### 1. Clone repository

```bash
git clone https://github.com/kamukamaosbertl/leak-monitor-system.git
cd leak-monitor
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run app

```bash
flutter run
```

---

## 🌐 Backend Setup

```bash
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

---

## 📊 Reports

The system generates reports containing:

* Leak location
* Water loss
* Estimated cost
* Alert history

Export formats:

* PDF
* CSV

---

## 🔐 Security

* Role-based access control
* JWT authentication
* Protected API endpoints

---

## 💡 Design Decisions

* Only leak events are stored (not all sensor data)
* WebSockets used for real-time updates
* Firebase used for push notifications

---

## ⚠️ Limitations

* Requires active backend server
* Push notifications depend on internet connection
* Some features (e.g., live chat) are not implemented

---

## 🔮 Future Improvements

* AI-based leak prediction
* Advanced analytics dashboard
* Offline support
* Enhanced notification customization

---

## 📞 Support

* Email: kamukamaosbert2023@gmail.com
* Phone: +256 793 702 186

---

## 📌 Author

Developed as a university project demonstrating real-time systems, mobile development, and backend integration.

---

## 🏁 Final Note

This project showcases how modern technologies can be combined to solve real-world problems in monitoring and resource management.




