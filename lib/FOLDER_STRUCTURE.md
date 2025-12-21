# 📁 Improved Folder Structure

## Overview
This project follows a **Feature-First Architecture** for better scalability, maintainability, and team collaboration.

## Structure

```
lib/
├── main.dart                          # App entry point
│
├── core/                              # Shared/core functionality
│   ├── constants/                     # App constants, colors, strings
│   │   └── firebase_options.dart
│   ├── services/                      # Core services used across features
│   │   ├── location_permission.dart
│   │   └── place_service.dart
│   ├── utils/                         # Utility functions, helpers
│   └── widgets/                       # Reusable widgets across features
│
├── features/                          # Feature modules
│   ├── auth/                          # Authentication feature
│   │   ├── controllers/
│   │   └── screens/
│   │       ├── driver_portal.dart     # Login/Signup
│   │       └── driver_details.dart    # Driver registration
│   │
│   ├── dashboard/                     # Main dashboard feature
│   │   ├── screens/
│   │   │   ├── driver_dashboard.dart  # Main dashboard
│   │   │   ├── dashboard.dart         # Dashboard UI
│   │   │   ├── chat_screen.dart
│   │   │   └── secondary.dart
│   │   └── widgets/
│   │       └── driver_navigation.dart
│   │
│   ├── wallet/                        # Wallet feature
│   │   ├── controllers/
│   │   │   ├── wallet_controller.dart # GetX controller
│   │   │   └── wallet_service.dart    # Firebase operations
│   │   ├── screens/
│   │   │   └── wallet_screen.dart
│   │   └── widgets/                   # Wallet-specific widgets
│   │
│   ├── profile/                       # Profile feature
│   │   ├── controllers/
│   │   ├── screens/
│   │   │   └── profile.dart
│   │   └── widgets/
│   │
│   ├── earnings/                      # Earnings feature
│   │   └── screens/
│   │       └── earnings.dart
│   │
│   ├── history/                       # Trip history feature
│   │   └── screens/
│   │       └── history_screen.dart
│   │
│   ├── documents/                     # Documents feature
│   │   └── screens/
│   │       └── document_screen.dart
│   │
│   └── vehicle/                       # Vehicle management feature
│       └── screens/
│           └── vehicle_information_screen.dart
│
└── payment_module/                    # Payment module (existing)
    ├── config/
    ├── controllers/
    ├── models/
    ├── presentation/
    ├── repositories/
    └── services/
```

## Benefits of This Structure

### 1. **Feature Isolation**
- Each feature is self-contained
- Easy to add, remove, or modify features
- Reduces merge conflicts in team development

### 2. **Scalability**
- New features can be added without affecting existing code
- Clear boundaries between different parts of the app
- Easy to understand what each feature does

### 3. **Maintainability**
- Related files are grouped together
- Easy to locate specific functionality
- Reduces cognitive load when working on a feature

### 4. **Reusability**
- Core functionality is shared across features
- Common widgets and services in one place
- Reduces code duplication

### 5. **Team Collaboration**
- Multiple developers can work on different features
- Clear ownership of features
- Easier code reviews

## Feature Structure Template

Each feature should follow this pattern:

```
feature_name/
├── controllers/          # Business logic (GetX controllers)
├── models/              # Data models specific to this feature
├── screens/             # UI screens for this feature
├── widgets/             # Reusable widgets within this feature
└── services/            # API/Database services for this feature
```

## Import Path Updates

After restructuring, update imports:

### Old:
```dart
import 'package:ryde/wallet_screen.dart';
import 'package:ryde/controllers/wallet_controller.dart';
import 'package:ryde/services/wallet_service.dart';
```

### New:
```dart
import 'package:ryde/features/wallet/screens/wallet_screen.dart';
import 'package:ryde/features/wallet/controllers/wallet_controller.dart';
import 'package:ryde/features/wallet/controllers/wallet_service.dart';
```

## Guidelines

### When to Create a New Feature Folder:
- The functionality is self-contained
- It has its own screens and business logic
- It could be developed/tested independently

### When to Use Core:
- Functionality used across multiple features
- Utility functions and helpers
- App-wide constants and configurations
- Reusable widgets used in 3+ features

### When to Use Widgets Folder:
- Feature-specific reusable components
- Only used within that feature
- Not needed elsewhere in the app

## Migration Notes

1. **Wallet Feature** ✅ - Fully migrated with GetX
2. **Auth Feature** ✅ - Screens organized
3. **Dashboard Feature** ✅ - Main screens organized
4. **Other Features** ✅ - Individual feature folders created

## Next Steps for Further Improvement

1. Create barrel files (index.dart) for each feature
2. Add models folders as features grow
3. Implement repositories for data access
4. Add tests folder mirroring the lib structure
5. Create shared theme configuration in core/constants
6. Add routing configuration in core/routes

## Advantages Over Previous Structure

| Before | After |
|--------|-------|
| All files in root lib/ | Organized by features |
| Hard to find related files | Related files together |
| controllers/ folder at root | Controllers within features |
| services/ mixed with features | Core services separated |
| No clear boundaries | Clear feature isolation |
| Difficult to scale | Easy to add features |

---

**Last Updated:** December 21, 2025
**Structure Version:** 2.0
