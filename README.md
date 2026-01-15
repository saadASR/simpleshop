# SimpleShop

A modern e-commerce Flutter app with Firebase backend, inspired by Amazon’s design.

## Features

- **User Authentication**: Sign in/up with Firebase Auth
- **Product Catalog**: Browse and search products with real-time updates
- **Shopping Cart**: Add/remove items, view cart drawer
- **Order Management**: View order history and status
- **Admin Panel**: Manage products, users, and delivery
- **Onboarding**: First‑launch tutorial flow
- **Modern UI**: Material 3 theme, reusable components, responsive layout

## Tech Stack

- **Frontend**: Flutter (Material 3)
- **Backend**: Firebase (Firestore, Authentication)
- **Image Storage**: Cloudinary
- **State**: Streams for real‑time data
- **Preferences**: `shared_preferences` for onboarding flag

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.10.7)
- Firebase project configured
- Cloudinary account (for image uploads)

### Installation

1. Clone the repo
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Add Firebase config:
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place in `android/app/` and `ios/Runner/` respectively
4. Run the app:
   ```bash
   flutter run
   ```

### Firebase Setup

- Enable Authentication (Email/Password, Google Sign-In)
- Create Firestore database
- Deploy the security rules from `firestore.rules`
- Configure Cloudinary upload preset and update in admin screens

## Project Structure

```
lib/
├── screens/
│   ├── admin/          # Admin panel
│   ├── auth/           # Sign‑in/up
│   ├── home/           # Landing page
│   ├── navigation/     # Bottom navigation
│   ├── onboarding/     # Splash & tutorial
│   ├── order/          # Orders history
│   ├── products/       # Product list & detail
│   ├── profile/        # User profile
│   └── user/          # Cart, user screens
├── services/
│   └── onboarding_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── app_product_card.dart
    ├── app_search_field.dart
    └── app_section_header.dart
```

## Design System

- **Theme**: `AppTheme.light()` provides consistent colors, typography, and component styles
- **Reusable Widgets**:
  - `AppSectionHeader`: Section titles with optional subtitle/trailing
  - `AppProductCard`: Product grid item with image, name, price, add‑to‑cart
  - `AppSearchField`: Search input with clear button

## Deployment

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Firestore Rules

Deploy the rules in `firestore.rules` to secure your database:

```bash
firebase deploy --only firestore:rules
```


