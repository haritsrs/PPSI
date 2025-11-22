import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';

class AccountController extends ChangeNotifier {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  User? _currentUser;
  File? _selectedImage;

  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get nameController => _nameController;
  TextEditingController get emailController => _emailController;
  bool get isEditing => _isEditing;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  User? get currentUser => _currentUser;
  File? get selectedImage => _selectedImage;

  Future<void> initialize() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    await AuthService.reloadUser();
    _currentUser = AuthService.currentUser;
    _nameController.text = _currentUser?.displayName ?? '';
    _emailController.text = _currentUser?.email ?? '';
    notifyListeners();
  }

  void setEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setUploadingPhoto(bool value) {
    _isUploadingPhoto = value;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    await _loadUserData();
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading = true;
    notifyListeners();

    try {
      String? photoURL;

      // Upload profile picture if selected
      if (_selectedImage != null) {
        photoURL = await AuthService.uploadProfilePicture(_selectedImage!);
      }

      // Update profile with name and photo
      await AuthService.updateUserProfile(
        displayName: _nameController.text.trim(),
        photoURL: photoURL,
      );

      // Reload user data
      await _loadUserData();

      _isEditing = false;
      _selectedImage = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void cancelEdit() {
    _isEditing = false;
    _selectedImage = null;
    _nameController.text = _currentUser?.displayName ?? '';
    _emailController.text = _currentUser?.email ?? '';
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        _isEditing = true;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProfilePicture() async {
    try {
      _isUploadingPhoto = true;
      notifyListeners();

      await AuthService.updateUserProfile(deletePhoto: true);
      await _loadUserData();

      _selectedImage = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  void clearSelectedImage() {
    _selectedImage = null;
    _isEditing = true;
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await AuthService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> sendVerificationEmail() async {
    await AuthService.sendEmailVerification();
  }

  Future<void> checkEmailVerification() async {
    await AuthService.reloadUser();
    await _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

