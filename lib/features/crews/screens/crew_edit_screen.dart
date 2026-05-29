import 'dart:io';

import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/core/shared_widgets/app_widgets.dart';
import 'package:jihc_volunteers_app/core/theme/app_theme.dart';
import 'package:jihc_volunteers_app/models/crew_model.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';
import 'package:jihc_volunteers_app/services/storage_service.dart';

class CrewEditScreen extends StatefulWidget {
  const CrewEditScreen({super.key, required this.crew});

  final CrewModel crew;

  @override
  State<CrewEditScreen> createState() => _CrewEditScreenState();
}

class _CrewEditScreenState extends State<CrewEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _category;
  File? _imageFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.crew.name);
    _descriptionController = TextEditingController(
      text: widget.crew.description,
    );
    _category = widget.crew.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl = widget.crew.imageUrl;
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadCrewImage(
          widget.crew.id,
          _imageFile!,
        );
      }

      await _firestoreService.updateCrew(widget.crew.id, <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'imageUrl': imageUrl,
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Crew updated.')));
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
      appBar: AppBar(title: const Text('Edit crew')),
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
                        else if (widget.crew.imageUrl != null &&
                            widget.crew.imageUrl!.isNotEmpty)
                          Image.network(widget.crew.imageUrl!, fit: BoxFit.cover)
                        else
                          const Center(
                            child: Icon(
                              Icons.groups_rounded,
                              size: 42,
                              color: AppColors.primary,
                            ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Crew name'),
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
                decoration: const InputDecoration(labelText: 'Category'),
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
                label: 'Save changes',
                onPressed: _save,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
