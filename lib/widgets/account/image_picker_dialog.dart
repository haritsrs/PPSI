import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class ImagePickerDialog extends StatelessWidget {
  final User? currentUser;
  final File? selectedImage;
  final Function(ImageSource) onPickImage;
  final VoidCallback onDeleteImage;

  const ImagePickerDialog({
    super.key,
    required this.currentUser,
    this.selectedImage,
    required this.onPickImage,
    required this.onDeleteImage,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pilih Foto Profil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Kamera'),
            onTap: () {
              Navigator.of(context).pop();
              onPickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Galeri'),
            onTap: () {
              Navigator.of(context).pop();
              onPickImage(ImageSource.gallery);
            },
          ),
          if (currentUser?.photoURL != null || selectedImage != null)
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                onDeleteImage();
              },
            ),
        ],
      ),
    );
  }
}

