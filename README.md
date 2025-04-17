# RITian Student App

The **RITian App** is a Flutter-based mobile application designed for students of RIT (Rajiv Institute of Technology, assumed). It provides a centralized platform for managing student activities, including profile management, leave/OD applications, event registration, printing/stationery services, canteen ordering, and payments using a virtual currency called RITZ. The app features a clean UI, persistent login state, and a navigation drawer for easy access to various modules.

## Features

- **Login/Logout**: Secure login with email and password, persisted using `shared_preferences`. Includes a "Forgot Password" option (simulated) and logout from Profile screen or navigation drawer.
- **Profile Management**: Displays student details (name, registration number, department, class, year, RITZ balance) fetched from inline JSON data.
- **Leave/OD Application**: Allows students to apply for Leave or On-Duty (OD) with date selection, optional file attachments, reason input, and a history section with status tracking (Waiting for Class Incharge Approval → Waiting for HoD Approval).
- **Event Registration**: Browse and register for events with details like title, description, organizer, and price. Supports RITZ-based payments and external registration links.
- **Arcade Services**: Upload files for printing (Xerox) with options for copies, color, and print side. Purchase stationery items with a cart system.
- **Canteen Ordering**: Order food items with a cart system, integrated with RITZ payments.
- **RITZ System**: Virtual currency for transactions (events, arcade, canteen), managed via a `UserBalance` class.
- **Navigation Drawer**: Centralized navigation with links to all modules, displaying the logged-in user's name and email.
- **Under Construction Screens**: Placeholder screens for unimplemented features (e.g., GPA Book, Bus Tracking).

## Prerequisites

- **Flutter SDK**: Version 3.7.0 or higher (Dart 2.19.6 or higher).
- **IDE**: Android Studio, VS Code, or any IDE with Flutter support.
- **Emulator/Device**: Android or iOS emulator or physical device for testing.
- **Git**: For cloning the repository.

## Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/your-repo/ritian-app.git
   cd ritian-app
   ```

2. **Install Dependencies**: Ensure `pubspec.yaml` is configured (see below). Run:

   ```bash
   flutter pub get
   ```

3. **Run the App**: Connect a device or start an emulator, then run:

   ```bash
   flutter run
   ```

4. **Build for Release** (optional):

   ```bash
   flutter build apk  # For Android
   flutter build ios  # For iOS
   ```

## Project Structure

```
ritian-app/
├── lib/
│   ├── models/
│   │   ├── event.dart              # Event model for event registration
│   │   ├── food_item.dart          # Food item model for canteen
│   │   └── stationery_item.dart    # Stationery item model for arcade
│   ├── screens/
│   │   ├── arcade_screen.dart      # Printing and stationery services
│   │   ├── canteen_screen.dart     # Food ordering
│   │   ├── event_registration_screen.dart  # Event browsing and registration
│   │   ├── leave_od_screen.dart    # Leave/OD application
│   │   ├── login_screen.dart       # Login with email/password
│   │   ├── payment_screen.dart     # Payment processing for arcade/canteen
│   │   ├── payment_success_screen.dart  # Payment confirmation
│   │   ├── profile_screen.dart     # Student profile with logout
│   │   ├── ritz_purchase_screen.dart  # RITZ purchase (placeholder)
│   │   ├── under_construction_screen.dart  # Placeholder for unimplemented features
│   │   ├── home_screen.dart        # Home screen (assumed)
│   │   └── settings_screen.dart    # Settings screen (assumed)
│   ├── widgets/
│   │   └── custom_navigation_drawer.dart  # Navigation drawer with user info
│   ├── user_provider.dart          # State management for user data
│   └── main.dart                   # App entry point
├── assets/
│   ├── stationery.json             # Stationery item data
│   └── food.json                   # Food item data
├── pubspec.yaml                    # Dependencies and configuration
└── README.md                       # This file
```

## Dependencies

The app uses the following Flutter packages (defined in `pubspec.yaml`):

- `provider: ^6.0.5` - State management for user data.
- `shared_preferences: ^2.2.2` - Persist login state.
- `file_picker: ^6.1.1` - File uploads for leave/OD and arcade.
- `url_launcher: ^6.2.6` - Open external links for event registration.

**pubspec.yaml** snippet:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  file_picker: ^6.1.1
  url_launcher: ^6.2.6
  shared_preferences: ^2.2.2
flutter:
  assets:
    - assets/stationery.json
    - assets/food.json
```

## Usage

1. **Login**:

   - Open the app and enter credentials (e.g., `john.doe@example.com`/`password123` or `jane.smith@example.com`/`password456`).
   - The app saves the login state and navigates to the home screen.
   - On subsequent launches, it skips the login screen if already logged in.

2. **Navigation**:

   - Use the navigation drawer to access modules (Home, Profile, Leave/OD, Arcade, Canteen, Events, etc.).
   - The drawer displays the logged-in user's name and email.

3. **Profile**:

   - View student details (name, registration number, department, class, year, RITZ balance).
   - Click the "Logout" button to clear the login state and return to the login screen.

4. **Leave/OD**:

   - Apply for Leave/OD by selecting dates, uploading optional attachments, and entering a reason.
   - View application history with status (Waiting for Class Incharge Approval → Waiting for HoD Approval).

5. **Arcade**:

   - Upload PDF files for printing with options (copies, color, print side).
   - Add stationery items to a cart and proceed to payment with RITZ.

6. **Canteen**:

   - Browse food items, add to cart, and pay with RITZ.

7. **Events**:

   - Browse events, view details, and register (free or paid with RITZ).
   - Follow external links for registration forms.

8. **Logout**:

   - Logout from the Profile screen or navigation drawer to return to the login screen.

## Development Notes

- **Authentication**: Uses inline JSON for credentials (in `login_screen.dart` and `main.dart`). For production, integrate Firebase Authentication.
- **State Management**: `provider` manages user data (name, email, department, class, year).
- **Data Storage**: Inline JSON for users, events, food, and stationery items. Consider Firestore for dynamic data.
- **RITZ System**: Simulated with `UserBalance` class. Persist balance with `shared_preferences` or a backend.
- **Unimplemented Screens**: `HomeScreen`, `SettingsScreen`, and others (e.g., GPA Book) use `UnderConstructionScreen`. Implement as needed.

## Future Improvements

- **Backend Integration**: Use Firebase for authentication, user data, and leave/OD status updates.
- **Dynamic Data**: Replace inline JSON with Firestore or a REST API.
- **Push Notifications**: Notify users of leave/OD status changes or event updates.
- **Signup Screen**: Allow new users to register.
- **Enhanced Security**: Validate login state and implement session timeouts.
- **UI/UX**: Customize with a consistent theme (e.g., RIT colors) and animations.
- **Additional Features**: Implement GPA Book, Bus Tracking, or Fee Details with real data.

## Troubleshooting

- **BuildAppBar Error**: Ensure `custom_navigation_drawer.dart` is in `lib/widgets/` and imported correctly (`import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';`).
- **Login Issues**: Verify inline JSON data in `login_screen.dart` and `main.dart` matches. Check `shared_preferences` for `user_email`.
- **Navigation**: Confirm all routes are defined in `main.dart`.
- **Dependencies**: Run `flutter pub get` after updating `pubspec.yaml`.
- **Clean Build**:

  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

## License

MIT License

Copyright (c) 2025 Null Pointers

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Contact

Developed by: **Null Pointers**

For issues or contributions, create a pull request or open an issue on the GitHub repository.
