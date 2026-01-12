# PPSI (KiosDarma) - AI Coding Guidelines

**KiosDarma** is a cross-platform Flutter POS (Point of Sale) system for retail business management. This guide helps AI agents rapidly become productive in this codebase.

## Architecture Overview: Clean Layers with Clear Boundaries

The project strictly separates concerns across these layers:

```
Pages (UI entry points)
    ↓ initializes
Controllers (state management, ChangeNotifier)
    ↓ calls
Services (business logic, Firebase operations)
    ↓ marshals
Models (data structures with fromFirebase/toFirebase methods)
```

### Layer Responsibilities

**Models** (`lib/models/`)
- Pure data structures with Firebase marshaling: `Product.fromFirebase(Map data)` and `toFirebase() → Map`
- Include computed properties (e.g., `isLowStock`, `stockStatus`) only for data representation
- Never add business logic; never make Firebase calls

**Services** (`lib/services/`)
- Stateless; NEVER extend ChangeNotifier
- All Firebase Realtime Database operations use `DatabaseService._getUserRef(path)` pattern for user-scoped data
- Use static methods or singleton pattern (e.g., `AuthService`, `DatabaseService`)
- One responsibility per service; separate concerns (auth, database, storage, payments)
- Handle errors via `toAppException(error, fallbackMessage: '...')` from `error_helper.dart`

**Controllers** (`lib/controllers/`)
- Extend `ChangeNotifier`; manage UI state only
- Call services for data operations; NEVER call Firebase directly
- Always `notifyListeners()` after state mutations
- Implement `dispose()` to clean up streams and subscriptions (critical!)
- Example stream pattern: `StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;` → cleaned in dispose

**Pages** (`lib/pages/`)
- Initialize controller: `ChangeNotifierProvider(create: (_) => ProductController()...)`
- Compose widgets; no business logic

**Widgets** (`lib/widgets/`)
- Reusable UI components organized by feature: `widgets/kasir/`, `widgets/products/`
- Stateful widgets for UI interactions; rely on parent controller for data

**Utils** (`lib/utils/`)
- Stateless functions: `FormatUtils.formatCurrency()`, `FormatUtils.formatDate()`, validation, error conversion
- `error_helper.dart`: converts Firebase exceptions to user-friendly `AppException` subclasses (Indonesian messages)

## Firebase Data Pattern: User-Scoped Isolation

All user data is stored under `users/{uid}/` in Realtime Database:

```dart
// Correct: user-scoped reference
DatabaseReference _getUserRef(String path) {
  final userId = currentUserId;
  return _database.child('users').child(userId).child(path);
}

// Usage in service
Stream<List<Product>> getProductsStream() {
  return _getUserRef('products').onValue.map(...);
}

// NEVER access global paths like _database.child('products')
```

Models serialize/deserialize via:
```dart
factory Product.fromFirebase(Map<String, dynamic> data) {
  return Product(
    id: data['id'] as String? ?? '',
    name: data['name'] as String? ?? '',
    // ... type-safe deserialization
  );
}

Map<String, dynamic> toFirebase() {
  return {
    'name': name,
    'price': price,
    'createdAt': createdAt.toIso8601String(),
    // ... toFirebase EXCLUDES the 'id' field
  };
}
```

## Error Handling & User Messages

**Always use `error_helper.dart`** to convert exceptions:

```dart
try {
  await _databaseService.saveProduct(product);
} catch (error) {
  throw toAppException(
    error,
    fallbackMessage: 'Gagal menyimpan produk. Silakan coba lagi.',
  );
}
```

- Custom `AppException` subclasses: `OfflineException`, `TimeoutRequestException`, `NetworkException`, `UnauthorizedException`, `NotFoundException`, `ServerException`
- **All user-facing messages are in Indonesian**; never expose Firebase error codes to users
- Controllers catch exceptions and display via `SnackBar` with `snackbar_helper.dart`

## State Management Patterns

**Controllers manage state immutably:**
```dart
class ProductController extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  List<Product> get products => _products; // Expose as getter, not setter
  
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _products = await _databaseService.getProducts();
    } catch (error) {
      _errorMessage = toAppException(error).message;
    } finally {
      _isLoading = false;
      notifyListeners(); // Always notify listeners, even on error
    }
  }
  
  @override
  void dispose() {
    _productsSubscription?.cancel(); // Clean up streams!
    super.dispose();
  }
}
```

**Streams & Connectivity:** Controllers listen to `getProductsStream()` and handle offline scenarios via `Connectivity` plugin.

## Common Features & Their Services

| Feature | Key Files |
|---------|-----------|
| Auth & Login | `AuthService`, `LoginController`, `login_page.dart`, `AuthWrapper` |
| Product Management | `ProductService`, `ProductController`, `product_model.dart` |
| Kasir/Transactions | `KasirController`, `TransactionModel`, `receipt_service.dart` |
| Barcode Scanning | `BarcodeScannerService` (wraps `mobile_scanner`); returns product lookup |
| Receipts & Printing | `ReceiptService` (generates receipt data), `PrinterCommands` (ESC/POS thermal printer protocol), `PrinterController` |
| Reports & Export | `ReportExportService` (Excel/PDF via `excel`, `pdf` packages), `DataExportService` (Firebase queries) |
| Payments (QRIS/VA) | `XenditService` (requires `.env`: `XENDIT_SECRET_KEY`, `XENDIT_PUBLIC_KEY`) |
| Settings | `SettingsService`, `SettingsController`, `settings_page.dart` |
| Encryption/Security | `SecurityUtils` (encrypt package), audit logging via `DatabaseService._logAuditEvent()` |

## Building & Running

```bash
# Activate locale formatting early in main.dart
await initializeDateFormatting('id_ID', null);

# Load environment variables (before Firebase & Xendit)
await dotenv.load(fileName: ".env");

# Build APK (Windows)
build_apk.bat

# Run development build
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

**Development Environment:**
- Flutter 3.9.2+, Dart 3.9.2+
- Firebase CLI for rules deployment
- `.env` file required for Xendit API keys and Firebase database URL

## Naming & Conventions

- **Files**: `snake_case` (e.g., `product_controller.dart`, `auth_service.dart`)
- **Classes**: `PascalCase` (e.g., `ProductController`, `AuthService`)
- **Routes**: `/path` format (e.g., `'/kasir'`, `'/produk'`)
- **Localization**: All user-facing text is **Indonesian**; use `intl` package for dates/currency with `'id_ID'` locale
- **Dates**: Format via `intl` with `'id_ID'` locale; initialize early in `main.dart`
- **Currency**: Use `FormatUtils.formatCurrency(value)` for "Rp" formatting with thousand separators

## Theme & Responsive Design

- Global colors/styles in [AppTheme](lib/themes/app_theme.dart); use `Theme.of(context).primaryColor`, not hardcoded hex
- Responsive layouts via [ResponsiveHelper](lib/utils/responsive_helper.dart)
- System UI overlay configured in `main.dart`: white navigation bar with dark icons

## Adding a New Feature: Step-by-Step

1. **Create Model** → `lib/models/feature_model.dart` with `fromFirebase()` and `toFirebase()` methods
2. **Create Service** → `lib/services/feature_service.dart` for Firebase operations (static methods or singleton)
3. **Create Controller** → `lib/controllers/feature_controller.dart` extending `ChangeNotifier`; call service, manage state, dispose streams
4. **Create Widgets** → `lib/widgets/feature/` with reusable components
5. **Create Page** → `lib/pages/feature_page.dart` initializing controller via `ChangeNotifierProvider`
6. **Register Route** → Add to `AppRoutes.getRoutes()` in `lib/routes/app_routes.dart`

## Testing (Implicit Patterns, No Test Files)

Follow these patterns when writing tests:
- **Unit tests**: Utility functions and formatting (e.g., currency formatting, validation)
- **Widget tests**: Reusable widget components in isolation
- **Integration tests**: Critical workflows (login → product listing → transaction → report export)

## Firebase Rules & Security

- **Database rules**: `users/{uid}/` scoped data; authenticated users read/write only their own
- **Audit logging**: `DatabaseService._logAuditEvent(action, payload)` for sensitive operations (sanitizes personally identifiable info)
- **Storage rules**: Product images under `products/{userId}/`; access restricted to authenticated users
- Test rule changes in Firebase Console before deployment

## Dependencies & Versions

Key packages (see `pubspec.yaml` for complete list):
- `firebase_core`, `firebase_auth`, `firebase_database`, `firebase_storage` (v11.1.2+)
- `flutter_blue_plus`, `usb_serial` (printer connectivity)
- `mobile_scanner` (barcode scanning)
- `excel`, `pdf`, `printing` (report export)
- `connectivity_plus` (offline detection)
- `intl` (localization), `shared_preferences` (user prefs)
- `flutter_dotenv` (environment variables)
- `encrypt` (data encryption)

## Quick Reference

| Task | File(s) |
|------|---------|
| Add user authentication | `AuthService`, `LoginController`, [login_page.dart](lib/pages/login_page.dart) |
| Add product feature | `ProductService`, `ProductController`, [product_model.dart](lib/models/product_model.dart) |
| Add custom widget | `lib/widgets/{feature}/` + reference in page |
| Format currency/date | `FormatUtils` in `lib/utils/` |
| Handle Firebase error | `error_helper.dart` → `toAppException()` |
| Log sensitive operations | `DatabaseService._logAuditEvent()` |
| Configure printer | `PrinterController`, `PrinterCommands`, [settings_page.dart](lib/pages/settings_page.dart) |
| Export report | `ReportExportService`, `DataExportService` |
| Add payment method | `XenditService`, `transaction_model.dart` |

## When Uncertain

1. **Architecture question?** → Check layer responsibilities above; verify services are stateless and controllers extend ChangeNotifier
2. **Firebase operation?** → Reference [DatabaseService](lib/services/database_service.dart) for user-scoped patterns
3. **UI component?** → Look at existing widgets in `lib/widgets/{feature}/`
4. **Error handling?** → Use `error_helper.dart` with Indonesian messages; never expose internal Firebase codes
5. **Printer integration?** → Study [PrinterCommands](lib/services/printer_commands.dart) and [PrinterController](lib/controllers/printer_controller.dart)
6. **Offline handling?** → Controllers use `Connectivity` plugin to detect network; services handle `SocketException` → `OfflineException`
