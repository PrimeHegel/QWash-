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


## Screenshots
### Splash screen / welcome screen
<img width="621" height="970" alt="image" src="https://github.com/user-attachments/assets/b0c8feae-49e7-473a-b1ee-c5df37728bb1" />

### Login and Register screen
<img width="628" height="973" alt="image" src="https://github.com/user-attachments/assets/d389944c-e21c-48bc-b678-5b0c3f2e29da" />
<img width="602" height="973" alt="image" src="https://github.com/user-attachments/assets/9f22a2af-c46f-4c39-9314-6fbbdccb53d3" />

### Home page (user)
<img width="630" height="971" alt="image" src="https://github.com/user-attachments/assets/55f199dc-5258-49d4-99c0-c5604ca4a3f9" />

### laundry detail screen
<img width="620" height="972" alt="image" src="https://github.com/user-attachments/assets/a770e159-4493-4840-8cc7-2343e6ed0864" />

### Laundry add screen 
<img width="623" height="969" alt="image" src="https://github.com/user-attachments/assets/df531958-2655-4c9f-aa40-1e1bbcb48e52" />

### Profile screen
<img width="627" height="971" alt="image" src="https://github.com/user-attachments/assets/e9491372-c2d6-415c-8a0d-aaf3efe556fd" />

### Home screen (admin)
<img width="626" height="970" alt="image" src="https://github.com/user-attachments/assets/bccac283-6f85-4bd4-a024-4930b6546c25" />

### Admin data user management screen
<img width="628" height="970" alt="image" src="https://github.com/user-attachments/assets/ad005fae-e836-4fed-848f-8a5e9dde6218" />

### Admin profile screen
<img width="627" height="974" alt="image" src="https://github.com/user-attachments/assets/cb1e052e-025f-4f73-834a-9cb2017a2952" />


## How to Run

```bash
git clone https://github.com/PrimeHegel/QWash-.git
cd laundry-queue-app
flutter pub get
flutter run

```
## Known Issues
- In admin page, when we close the machine laundry. It doesn't shows not available in the admin home screen

## Credits
- Using FlutterFire  https://firebase.flutter.dev/
- UI Design inspired from Figma









