# mountain-rescue-app

# Mountain Rescue – Ski Patrol Management System

A **Flutter + Firebase** application for ski patrol and mountain rescue teams.
The app provides two roles: **Rescuer** and **Admin**, offering secure authentication, incident tracking, and report management.

---

## Overview

**Mountain Rescue** helps ski patrol members efficiently record, review, and manage injury reports.
Rescuers can log incidents directly from the field, while administrators monitor all activities, manage users, and generate official reports.

This system is built for clarity, scalability, and real-time collaboration using Flutter and Firebase technologies.

---

## Features

### Rescuer

* Secure login and registration
* Register new injury incidents
* View and manage past injury reports
* Generate PDF injury reports
* Edit profile and upload profile photo
* Password reset functionality

### Admin

* Administrative dashboard with system statistics
* View all injury reports from all rescuers
* Export PDF summaries for each report
* Manage rescuer profiles and system data
* Admin settings with profile photo, name edit, password reset, and support contact
* Generate complete system-level PDF reports

---

## Technology Stack

| Layer            | Technology                                    |
| ---------------- | --------------------------------------------- |
| Framework        | Flutter (Dart)                                |
| Backend          | Firebase (Authentication, Firestore, Storage) |
| State Management | Riverpod                                      |
| PDF Generation   | `pdf`, `printing`                             |
| Media Upload     | `image_picker`, `firebase_storage`            |
| Utilities        | `intl`, `url_launcher`, `package_info_plus`   |

---

## Project Structure

```
lib/
├── data/
│   ├── models/
|   │   ├── injury_model.dart
│   │   └── user_model.dart
│   └── repositories/
|       ├── injury_repository.dart
│       └── auth_repository.dart
│
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   │
│   ├── rescuer/
|   |   ├── injury_detail_screen.dart
│   │   ├── rescuer_home.dart
│   │   ├── past_injuries_screen.dart
│   │   └── settings_screen.dart
│   │
│   ├── admin/
│   │   ├── admin_home.dart
│   │   ├── admin_settings_screen.dart
│   │   └── admin_injuries_screen.dart
│
├── routes/
│   └── app_router.dart
│
├── state/
│   └── providers/
|       ├── user_provider.dart
|       ├── injury_provider.dart
|       ├── role_provider.dart
│       └── auth_provider.dart
│
├── firebase_options.dart
└── main.dart
```

---

## Setup Instructions

### Prerequisites

* Flutter SDK installed (version 3.22 or later)
* Active Firebase project with Authentication, Firestore, and Storage enabled
* FlutterFire CLI configured (`flutterfire configure`)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/mountain-rescue.git
cd mountain-rescue

# Install dependencies
flutter pub get
```

### Firebase Setup

Run the FlutterFire CLI and link your Firebase project:

```bash
flutterfire configure
```

Ensure that `firebase_options.dart` is generated inside `/lib/`.

### Running the App

```bash
flutter run
```

---

## Core Dependencies

| Package             | Purpose                          |
| ------------------- | -------------------------------- |
| `firebase_core`     | Firebase initialization          |
| `firebase_auth`     | Authentication                   |
| `cloud_firestore`   | Realtime database                |
| `firebase_storage`  | File storage (photos, documents) |
| `flutter_riverpod`  | State management                 |
| `image_picker`      | Selecting images for profiles    |
| `pdf`, `printing`   | PDF generation and sharing       |
| `intl`              | Date and time formatting         |
| `url_launcher`      | Opening external links or emails |
| `package_info_plus` | App metadata (version, build)    |

---

## PDF Reports

The system uses the **Dart `pdf`** package to generate detailed and print-ready PDF reports containing:

* Date and time of the incident
* Injury type, severity, and description
* Location of occurrence
* Assigned rescuer details
* Automatically formatted timestamps and metadata

---

## Security

* Firebase Authentication ensures secure user access
* Firestore security rules separate rescuer and admin access levels
* Passwords are encrypted and handled exclusively by Firebase
* Profile and injury photos are stored in Firebase Storage with restricted access

---

## Future Enhancements

* GPS-based injury location tracking
* Advanced filters for injury reports (severity, rescuer, date)
* Digital signatures on PDF reports
* Offline mode and local caching
* Push notifications for new incidents

---

## Use Case Diagram

<img width="763" height="501" alt="mountain_rescue_usecase drawio" src="https://github.com/user-attachments/assets/f628e4c6-85f7-4931-b392-2d97ddff72de" />

---

# Authors

**Andrej Delimanchev**
Faculty of Electrical Engineering and Computer Science (FERI), Maribor
Email: [delimanchev@gmail.com](mailto:delimanchev@gmail.com)
GitHub: [github.com/delimanchev](https://github.com/delimanchev)

**Georgi Dimov**
Faculty of Electrical Engineering and Computer Science (FERI), Maribor
Email: [dimov.goke12@gmail.com](mailto:dimov.goke12@gmail.com)
GitHub: [github.com/Gjoce](https://github.com/Gjoce)
