# Separation of Concerns Analysis - lib/pages

## Summary
This document lists all violations of separation of concerns found in `lib/pages/*_page.dart` files and proposes specific fixes.

---

## Violations by File

### 1. **account_page.dart**

#### Violations:
- **Error handling logic in page** (lines 66-92): `_showSnackBar()` and `_handleAsyncOperation()` methods contain business logic for error handling
- **Repeated error handling pattern**: Multiple try-catch blocks with SnackBar messages

#### Proposed Fixes:
- Move `_showSnackBar()` and `_handleAsyncOperation()` to `lib/utils/snackbar_helper.dart` as reusable utilities
- Controller should handle errors and expose success/error messages as state
- Page should only display messages from controller state

---

### 2. **berita_page.dart**

#### Violations:
- **Direct service call** (line 21): `NewsService.getDefaultNews()` called directly in page
- **No controller**: Missing `BeritaController` to manage state and business logic
- **Timer logic in page** (lines 27-31): Timer for refreshing time display should be in controller
- **Direct service access** (line 44): `AuthService.getUserDisplayName()` called directly

#### Proposed Fixes:
- Create `lib/controllers/berita_controller.dart` to:
  - Manage news data fetching
  - Handle timer for time refresh
  - Expose user display name
- Move service calls to controller
- Page should only initialize controller and display data

---

### 3. **kasir_page.dart**

#### Violations:
- **Complex barcode handling logic** (lines 118-161): `_handleRawKeyEvent()` contains business logic for barcode scanning
- **Error handling in page** (lines 163-173, 195-201, 249-262): Multiple SnackBar error messages
- **Business logic in page** (lines 124-158): Barcode buffer management and product lookup logic

#### Proposed Fixes:
- Move barcode handling logic to `KasirController`:
  - `handleRawKeyEvent()` method
  - Barcode buffer management
  - Product lookup by barcode
- Controller should expose error messages as state
- Page should only handle UI events and delegate to controller

---

### 4. **laporan_page.dart**

#### Violations:
- **Local state in page** (lines 20-23): `_periods`, `_filters`, `_paymentMethods`, `_selectedPeriod` should be in controller
- **State management in page** (lines 69-72): Period selection logic in page

#### Proposed Fixes:
- Move filter options and selected period to `LaporanController`
- Controller should expose these as getters
- Page should only bind to controller state

---

### 5. **login_page.dart**

#### Violations:
- **Error handling logic** (lines 71-85, 87-113): Try-catch blocks with SnackBar messages
- **Business logic in error handling** (lines 101-103): Color determination based on error message content

#### Proposed Fixes:
- Controller should handle errors and expose error state
- Create `lib/utils/snackbar_helper.dart` for consistent SnackBar display
- Page should only display errors from controller state

---

### 6. **logout_page.dart**

#### Violations:
- **Error handling logic** (lines 66-83): Try-catch with SnackBar message

#### Proposed Fixes:
- Controller should handle logout errors
- Page should only display error from controller state

---

### 7. **notification_page.dart**

#### Violations:
- **Direct controller method call in initState** (line 51): `_loadNotifications()` called directly
- **Error handling logic** (lines 68-81, 83-97, 99-121, 123-137, 139-165): Multiple try-catch blocks with SnackBar messages
- **Business logic** (line 86): HapticFeedback should be handled by controller or utility

#### Proposed Fixes:
- Controller should auto-load in `initialize()` method
- Move error handling to controller
- Create utility for HapticFeedback patterns
- Page should only display state from controller

---

### 8. **onboarding_page.dart**

#### Status: ✅ **COMPLIANT**
- Properly uses controller
- Only handles UI orchestration
- No business logic in page

---

### 9. **pelanggan_page.dart**

#### Violations:
- **Error handling pattern** (lines 139-149): `WidgetsBinding.instance.addPostFrameCallback` pattern for error display should be in controller
- **Error message display logic**: Controller error messages displayed via SnackBar in page

#### Proposed Fixes:
- Controller should expose error state with callbacks or streams
- Use a consistent error display pattern (widget or utility)
- Page should only react to controller state changes

---

### 10. **pengaturan_page.dart**

#### Violations:
- **Error handling pattern** (lines 71-81): Same `WidgetsBinding.instance.addPostFrameCallback` pattern

#### Proposed Fixes:
- Same as pelanggan_page.dart
- Standardize error handling across all pages

---

### 11. **produk_page.dart**

#### Violations:
- **Error handling pattern** (lines 92-102): Same `WidgetsBinding.instance.addPostFrameCallback` pattern
- **Hardcoded dialog content** (lines 231-252): `_showScanDialog()` contains hardcoded UI content that should be a widget
- **Business logic** (line 183): HapticFeedback should be in utility

#### Proposed Fixes:
- Extract `_showScanDialog()` content to `lib/widgets/products/scan_barcode_dialog.dart`
- Move error handling to controller
- Create utility for HapticFeedback

---

### 12. **register_page.dart**

#### Violations:
- **Error handling logic** (lines 71-98): Try-catch with SnackBar messages
- **Business logic in error handling** (lines 86-88): Color determination based on error content
- **Hardcoded AppBar** (lines 104-129): Custom AppBar styling should be extracted to widget

#### Proposed Fixes:
- Move error handling to controller
- Extract AppBar to `lib/widgets/auth/back_button_app_bar.dart` or similar
- Use snackbar utility for consistent error display

---

### 13. **auth_wrapper.dart**

#### Status: ✅ **COMPLIANT**
- Only handles routing logic
- No business logic violations

---

## Cross-Cutting Issues

### 1. **Error Handling Pattern**
**Issue**: Multiple pages use inconsistent error handling:
- Some use try-catch with SnackBar
- Some use `WidgetsBinding.instance.addPostFrameCallback`
- Some have helper methods

**Proposed Solution**:
- Create `lib/utils/snackbar_helper.dart` with:
  ```dart
  class SnackbarHelper {
    static void showSuccess(BuildContext context, String message);
    static void showError(BuildContext context, String message);
    static void showInfo(BuildContext context, String message);
  }
  ```
- Controllers should expose error/success messages as state
- Pages should react to controller state changes

### 2. **HapticFeedback Usage**
**Issue**: HapticFeedback calls scattered across pages

**Proposed Solution**:
- Create `lib/utils/haptic_helper.dart`:
  ```dart
  class HapticHelper {
    static void lightImpact();
    static void mediumImpact();
    static void heavyImpact();
  }
  ```
- Or move to controller methods that trigger haptics

### 3. **Missing Controllers**
**Issue**: `berita_page.dart` has no controller

**Proposed Solution**:
- Create `lib/controllers/berita_controller.dart`

### 4. **Repeated UI Patterns**
**Issue**: Custom AppBars, error display patterns repeated across pages

**Proposed Solution**:
- Extract to reusable widgets in `lib/widgets/`

---

## Priority Fixes

### High Priority:
1. Create `berita_controller.dart` for berita_page.dart
2. Move barcode handling logic from kasir_page.dart to KasirController
3. Create `snackbar_helper.dart` utility
4. Standardize error handling across all pages

### Medium Priority:
5. Move filter state from laporan_page.dart to LaporanController
6. Extract hardcoded dialogs to widgets (scan dialog, custom AppBars)
7. Create `haptic_helper.dart` utility

### Low Priority:
8. Extract helper methods from account_page.dart to utilities
9. Refactor error display patterns to use consistent approach

---

## Files to Create/Modify

### New Files:
1. `lib/controllers/berita_controller.dart`
2. `lib/utils/snackbar_helper.dart`
3. `lib/utils/haptic_helper.dart`
4. `lib/widgets/products/scan_barcode_dialog.dart`
5. `lib/widgets/auth/back_button_app_bar.dart`

### Files to Modify:
1. All page files (remove error handling, move logic to controllers)
2. Controllers (add error state management, move business logic from pages)

