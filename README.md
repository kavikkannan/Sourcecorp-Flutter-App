# Sourcecorp Flutter Leave Management App

A Flutter mobile application for leave management with role-based access for employees and HR.

## Features

- User authentication with JWT
- Employee leave request submission
- HR dashboard for leave approval/rejection
- Leave balance tracking
- Leave history viewing

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Configure API base URL in `lib/utils/constants.dart`

3. Run the app:
```bash
flutter run
```

## Project Structure

- `lib/models/` - Data models
- `lib/services/` - API and authentication services
- `lib/screens/` - UI screens
- `lib/widgets/` - Reusable widgets
- `lib/utils/` - Constants and theme

