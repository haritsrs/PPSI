# PPSI - Copilot Instructions

**KiosDarma** is a cross-platform Flutter POS (Point of Sale) system for retail business management. This document guides AI agents on essential architectural patterns, developer workflows, and project-specific conventions.

## Architecture Overview

### Clean Architecture with Separation of Concerns

The codebase follows a strict layered architecture:

- **Models** (`lib/models/`) - Data structures with Firebase marshaling (e.g., `Product.fromFirebase()`, `toFirebase()`)
- **Services** (`lib/services/`) - Stateless business logic & Firebase operations; use static methods or singletons
- **Controllers** (`lib/controllers/`) - ChangeNotifier-based state management; call services, not Firebase directly
- **Pages** (`lib/pages/`) - Entry points that initialize controllers and compose widgets
- **Widgets** (`lib/widgets/`) - Reusable UI components organized by feature (e.g., `widgets/kasir/`, `widgets/products/`)
- **Utils** (`lib/utils/`) - Utility functions (formatting, validation, error handling)
- **Routes** (`lib/routes/`) - Navigation configuration via `AppRoutes` class

**Critical rule**: Pages only initialize controllers; business logic belongs in services; UI composition goes in widgets.

## Firebase Integration Pattern

### Database Service
[DatabaseService](lib/services/database_service.dart) manages Realtime Database operations with user-scoped references:

```dart
// User-scoped reference pattern
DatabaseReference _getUserRef(String path) {
  final userId = currentUserId;
  return _database.child('users').child(userId).child(path);
}
```

All product, transaction, and customer data is stored under `users/{userId}/`. **Never assume globally accessible data paths.**

### Models & Serialization
All models implement Firebase marshaling:

```dart
factory Product.fromFirebase(Map<String, dynamic> data) { ... }
Map<String, dynamic> toFirebase() { ... }
```

Use these for every Firebase read/write to ensure type safety.

### Authentication
[AuthService](lib/services/auth_service.dart) handles Firebase Auth with:
- Rate limiting to prevent brute force attacks
- Input validation (email format checks)
- User-specific error messages (never expose internal Firebase errors)

## State Management & Controllers

Controllers extend `ChangeNotifier` and manage UI state:

```dart
class ProductController extends ChangeNotifier {
  List<Product> _products = [];
  
  Future<void> loadProducts() async {
    _products = await DatabaseService().getProducts();
    notifyListeners(); // Always notify after state changes
  }
  
  @override
  void dispose() {
    // Clean up subscriptions, timers, streams
    super.dispose();
  }
}
```

**Key patterns**:
- Call `notifyListeners()` after every state mutation
- Implement `dispose()` to clean up resources (critical for streams)
- Controllers call services; never call Firebase directly

## Key Features & Services

### 1. **Receipt & Printer System**
- [ReceiptService](lib/services/receipt_service.dart) generates receipt data
- [PrinterCommands](lib/services/printer_commands.dart) implements ESC/POS thermal printer protocol
- Supports both Bluetooth (`flutter_blue_plus`) and USB (`usb_serial`) connections
- Print workflows handle offline scenarios gracefully

### 2. **Report Export**
- [ReportExportService](lib/services/report_export_service.dart) exports to Excel and PDF
- [DataExportService](lib/services/data_export_service.dart) handles Firebase data queries
- Use `excel` and `pdf` packages; format currency via `FormatUtils.formatCurrency()`

### 3. **Barcode Scanning**
- [BarcodeScanner](lib/services/barcode_scanner_service.dart) wraps `mobile_scanner`
- Returns product lookup results; integrate with product controller

### 4. **Payment Integration**
- [XenditService](lib/services/xendit_service.dart) handles QRIS and Virtual Account payments
- Requires `.env` variables: `XENDIT_SECRET_KEY`, `XENDIT_PUBLIC_KEY`
- Payment callbacks update transaction status in database

### 5. **Data Security**
- [SecurityUtils](lib/utils/security_utils.dart) provides encryption/decryption via `encrypt` package
- Audit logging via `DatabaseService._logAuditEvent()` tracks sensitive operations
- Sensitive data (payment info, customer details) must be encrypted before Firebase storage

## Common Development Workflows

### Adding a New Feature

1. **Create Model** → `lib/models/feature_model.dart` with Firebase marshaling
2. **Create Service** → `lib/services/feature_service.dart` for Firebase operations
3. **Create Controller** → `lib/controllers/feature_controller.dart` extending `ChangeNotifier`
4. **Create Widgets** → `lib/widgets/feature/` with reusable components
5. **Create Page** → `lib/pages/feature_page.dart` that initializes controller
6. **Register Route** → Add to `AppRoutes` in `lib/routes/app_routes.dart`

### Handling Firebase Errors
Use [ErrorHelper](lib/utils/error_helper.dart) to convert Firebase exceptions:

```dart
try {
  await service.operation();
} catch (error) {
  throw toAppException(error, 
    fallbackMessage: 'Gagal melakukan operasi. Silakan coba lagi.');
}
```

Always provide user-friendly Indonesian error messages; never expose Firebase internals.

### Building & Running

```bash
# Get dependencies
flutter pub get

# Run app (development)
flutter run

# Build APK
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release
```

Generated APK scripts: `build_apk.bat` on Windows.

## Project-Specific Conventions

### Naming
- Classes: `PascalCase` (e.g., `ProductController`, `AuthService`)
- Files: `snake_case` (e.g., `product_controller.dart`, `auth_service.dart`)
- Constants in routes: `/path` format (e.g., `'/kasir'`, `'/produk'`)

### Indonesian Localization
- All user-facing messages, error texts, and UI labels are in Indonesian
- Use `intl` package for date/currency formatting with `'id_ID'` locale
- Initialize date formatting early in `main.dart`: `initializeDateFormatting('id_ID')`

### Theme & Styling
- [AppTheme](lib/themes/app_theme.dart) defines global colors, text styles, and Material design settings
- Use theme colors via `Theme.of(context).primaryColor`, not hardcoded hex values
- Responsive design via [ResponsiveHelper](lib/utils/responsive_helper.dart)

### Image & Asset Handling
- Product images uploaded to Firebase Storage via [StorageService](lib/services/storage_service.dart)
- Use `cached_network_image` for remote images to minimize network calls
- Local assets in `assets/` directory (banners, icons)

### Local Storage
- `shared_preferences` for user preferences (e.g., `has_seen_onboarding`)
- **Do not store sensitive data** (tokens, passwords) in SharedPreferences; use Firebase Auth

## Testing Patterns

While comprehensive test files don't exist, follow these patterns:

- **Unit tests** for utils and formatting functions
- **Widget tests** for reusable widget components
- **Integration tests** for critical flows (login → product → transaction → report)

Test directory structure: `test/` (placeholder exists with `widget_test.dart`)

## Firebase Rules & Security

### Realtime Database Rules
See [firebase_database.rules.json](firebase_database.rules.json):
- User data scoped to `users/{uid}/`
- Authenticated users can read/write only their own data
- Audit logs are append-only

### Storage Rules
See [storage.rules](storage.rules):
- Product images stored under `products/{userId}/`
- Access restricted to authenticated users

Always test rule changes before deployment via Firebase Console.

## Environment & Dependencies

**Key dependencies**:
- `firebase_core`, `firebase_auth`, `firebase_database`, `firebase_storage` - Backend
- `flutter_blue_plus`, `usb_serial` - Printer connectivity
- `mobile_scanner` - Barcode scanning
- `excel`, `pdf`, `printing` - Report generation
- `connectivity_plus` - Network monitoring
- `intl` - Localization

See `pubspec.yaml` for complete list and versions.

---

## Quick Reference

| Task | File(s) |
|------|---------|
| Add authentication | `AuthService`, `LoginController`, `login_page.dart` |
| Add product feature | `ProductService`, `ProductController`, `produk_page.dart` |
| Add custom widget | `lib/widgets/{feature}/` + reference in page |
| Format currency/date | `FormatUtils` in `lib/utils/` |
| Handle Firebase error | `ErrorHelper.toAppException()` |
| Add audit logging | `DatabaseService._logAuditEvent()` |
| Configure printer | `PrinterController`, `settings_page.dart` |
| Export report | `ReportExportService`, `DataExportService` |

---

## When Uncertain

1. **Architecture question?** → Check `lib/{controllers,services,models}/README.md` for layer responsibilities
2. **Firebase operation?** → Reference [DatabaseService](lib/services/database_service.dart) patterns
3. **UI component?** → Look at existing widgets in `lib/widgets/{feature}/`
4. **Error handling?** → Use `ErrorHelper.toAppException()` with Indonesian messages
5. **Printer integration?** → Study [PrinterCommands](lib/services/printer_commands.dart) and [PrinterController](lib/controllers/printer_controller.dart)
