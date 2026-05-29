import 'dart:io';

import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/models/task_model.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';
import 'package:jihc_volunteers_app/services/storage_service.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController(
    text: '10',
  );
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  String _category = 'Environment';
  DateTime _date = DateTime.now().add(const Duration(days: 3));
  File? _imageFile;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final File? file = await showModalBottomSheet<File?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    final File? picked = await _storageService
                        .pickImageFromGallery();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop(picked);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    final File? picked = await _storageService
                        .pickImageFromCamera();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop(picked);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (file != null) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(context, 'Sign in first to create a task.');
      return;
    }

    final UserModel? profile = await _firestoreService.getUserProfile(user.uid);
    if (profile?.role != AppConstants.administratorRole) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(context, 'Only administrators can create tasks.');
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl;
      final String generatedId = DateTime.now().millisecondsSinceEpoch
          .toString();

      if (_imageFile != null) {
        imageUrl = await _storageService.uploadTaskImage(
          generatedId,
          _imageFile!,
        );
      }

      final TaskModel task = TaskModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        creatorId: user.uid,
        creatorName: user.displayName ?? 'JIHC Student',
        date: _date,
        location: _locationController.text.trim(),
        maxVolunteers: int.tryParse(_capacityController.text) ?? 10,
        volunteers: <String>[],
        status: 'open',
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _firestoreService.createTask(task);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Create task')),
        body: Stack(
          children: <Widget>[
            IgnorePointer(
              ignoring: _loading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GestureDetector(
                        onTap: _pickImage,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                if (_imageFile != null)
                                  Image.file(_imageFile!, fit: BoxFit.cover)
                                else
                                  const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: AppColors.primary,
                                        size: 44,
                                      ),
                                      SizedBox(height: 10),
                                      Text('Add a cover image'),
                                    ],
                                  ),
                                if (_loading)
                                  Container(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Task title is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: AppConstants.taskCategories
                            .where((String category) => category != 'All')
                            .map(
                              (String category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Location is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Volunteer capacity',
                          prefixIcon: Icon(Icons.people_outline_rounded),
                        ),
                        validator: (String? value) {
                          final int? number = int.tryParse(value ?? '');
                          if (number == null || number < 1) {
                            return 'Enter a valid capacity.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() => _date = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.calendar_today_outlined),
                              const SizedBox(width: 12),
                              Text(
                                '${_date.day}/${_date.month}/${_date.year}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TealButton(
                        label: 'Publish task',
                        onPressed: _submit,
                        isLoading: _loading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.82),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
