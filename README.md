# Laundry Queue App 

A mobile application built using **Flutter** and **Firebase** that enables users to join a laundry queue, view machine availability, and receive notifications when it's their turn.

## Features

###  User Features
- Register & Login (Firebase Auth)
- View available laundry machines
- Join queue based on machine availability
- Receive local notifications when it's their turn
- Edit profile (name & profile picture)
- View position in queue in real-time

###  Admin Features
- View full queue list for each machine
- Remove users from queue
- Set machine status: `Available` / `Unavailable`

##  Tech Stack

| Layer       | Tools                          |
|-------------|--------------------------------|
| Frontend    | Flutter, Dart                  |
| Backend     | Firebase Auth, Cloud Firestore |
| Notification| Flutter Local Notifications    |

##  User Roles

-  **User**
  - Register & Login
  - View the washing machine queue
  - Add to the queue

-  **Admin**
  - Delete the queue
  - Set the washing machine status (available/unavailable)
  - View user data

##  Folder Structure
```
lib/
│
├── model/                     # Data models used across the app (e.g., user model)
│   └── user_model.dart
│
├── providers/                # State management using Provider (e.g., user state)
│   └── user_providers.dart
│
├── screen/                   # All UI screens for both admin and user roles
│   ├── admin_*.dart          # Screens specifically for admin features (contains of user datas in admin screen, admin report message and admin control machine availability and queue).
│   ├── login_screen.dart     # Login screen shared by admin and users
│   ├── register_screen.dart  # User registration screen
│   ├── home_screen.dart      # Main dashboard/home for regular users
│   ├── laundry_*.dart        # Screens related to laundry management (add/view rooms)
│   ├── profile_screen.dart   # View user profile screen
│   ├── edit_profile_screen.dart # Edit user profile
│   ├── notification_screen.dart  # Notification page
│   ├── splash_screen.dart        # Initial splash/loading screen
│   └── report_screen.dart        # Screen to display laundry usage reports
│
├── widgets/                  # Reusable custom UI components/widgets
│   ├── admin_navbar.dart
│   ├── custom_navbar.dart
│
├── firebase_options.dart     # Firebase auto-generated configuration file
└── main.dart                 # Main entry point of the Flutter application

```

## Screenshots
### Splash screen / welcome screen
<img width="621" height="970" alt="image" src="https://github.com/user-attachments/assets/b0c8feae-49e7-473a-b1ee-c5df37728bb1" />

### Login and Register screen
<p float="left">
  <img src="https://github.com/user-attachments/assets/d389944c-e21c-48bc-b678-5b0c3f2e29da" width="400" />
  <img src="https://github.com/user-attachments/assets/9f22a2af-c46f-4c39-9314-6fbbdccb53d3" width="400" />
</p>

### Home page (user)
<img src="https://github.com/user-attachments/assets/55f199dc-5258-49d4-99c0-c5604ca4a3f9" width="400" />

### Laundry detail screen
<img src="https://github.com/user-attachments/assets/a770e159-4493-4840-8cc7-2343e6ed0864" width="400" />

### Laundry add screen 
<img src="https://github.com/user-attachments/assets/df531958-2655-4c9f-aa40-1e1bbcb48e52" width="400" />

### Profile screen
<img src="https://github.com/user-attachments/assets/e9491372-c2d6-415c-8a0d-aaf3efe556fd" width="400" />

### Home screen (admin)
<img src="https://github.com/user-attachments/assets/bccac283-6f85-4bd4-a024-4930b6546c25" width="400" />

### Admin data user management screen
<img src="https://github.com/user-attachments/assets/ad005fae-e836-4fed-848f-8a5e9dde6218" width="400" />

### Admin profile screen
<img src="https://github.com/user-attachments/assets/cb1e052e-025f-4f73-834a-9cb2017a2952" width="400" />

### FIREBASE
<p float="left">
  <img src="https://github.com/user-attachments/assets/1892fd41-0894-4f93-8398-20b5746dd7bc" width="400" />
  <img src="https://github.com/user-attachments/assets/7bd9a283-8fe3-42c3-b75b-c9a907f6d6c2" width="400" />
</p>




## How to Run

```bash
git clone https://github.com/PrimeHegel/QWash-.git
cd laundry-queue-app
flutter pub get
flutter run

```

## Known Issues
- In admin page, when we close the machine laundry. It doesn't shows not available in the admin home screen

## One Thing You Might Be Wondering
_What if there is people using the washing machine without the app?_
Based on our dorm rules, if there is people who using not on their schedule, we can take it out the clothes from the washing machine. 
So, if there is someone who using washing machine but not using the app. We can take it out. 
Actually, we can use IOT for knowing if the washing machine are in use or not. But, we implement this rules for temporary, but if this app useful maybe later on we can put IOT.

## Credits
- Using FlutterFire  https://firebase.flutter.dev/
- UI Design inspired from Figma









