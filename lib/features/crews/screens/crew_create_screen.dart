import 'dart:io';

import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/models/crew_model.dart';
import 'package:jihc_volunteers_app/services/auth_service.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';
import 'package:jihc_volunteers_app/services/storage_service.dart';

class CrewCreateScreen extends StatefulWidget {
  const CrewCreateScreen({super.key});

  @override
  State<CrewCreateScreen> createState() => _CrewCreateScreenState();
}

class _CrewCreateScreenState extends State<CrewCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  String _category = 'Community';
  File? _imageFile;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to create a crew.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl;
      final String generatedId = DateTime.now().millisecondsSinceEpoch
          .toString();
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadCrewImage(
          generatedId,
          _imageFile!,
        );
      }

      final CrewModel crew = CrewModel(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: user.uid,
        members: <String>[user.uid],
        category: _category,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _firestoreService.createCrew(crew);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crew created successfully.')),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create crew')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  final File? file = await _storageService
                      .pickImageFromGallery();
                  if (file != null) {
                    setState(() => _imageFile = file);
                  }
                },
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
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
                                Icons.groups_rounded,
                                size: 42,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 10),
                              Text('Add a crew image'),
                            ],
                          ),
                        if (_loading)
                          Container(
                            color: Colors.white.withValues(alpha: 0.72),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Crew name',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Crew name is required.';
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
              const SizedBox(height: 24),
              TealButton(
                label: 'Create crew',
                onPressed: _submit,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
