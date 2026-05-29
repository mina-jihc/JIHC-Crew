import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:jihc_volunteers_app/core/services/imgbb_service.dart';

class StorageService {
  StorageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<File?> pickImageFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) {
      return null;
    }
    return File(file.path);
  }

  Future<File?> pickImageFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) {
      return null;
    }
    return File(file.path);
  }

  Future<String> uploadTaskImage(String taskId, File file) {
    return _uploadFile('tasks/$taskId/cover.jpg', file);
  }

  Future<String> uploadCrewImage(String crewId, File file) {
    return _uploadFile('crews/$crewId/cover.jpg', file);
  }

  Future<String> uploadAvatar(String uid, File file) {
    return _uploadFile('users/$uid/avatar.jpg', file);
  }

  Future<String> _uploadFile(String path, File file) async {
    final String url = await ImgBBService.uploadImage(file);
    if (url.isEmpty) {
      throw StateError('Unable to resolve uploaded file URL.');
    }
    return url;
  }
}
