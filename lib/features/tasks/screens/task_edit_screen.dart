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

class TaskEditScreen extends StatefulWidget {
  const TaskEditScreen({super.key, required this.task});

  final TaskModel task;

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late String _category;
  late DateTime _date;
  File? _imageFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _locationController = TextEditingController(text: widget.task.location);
    _capacityController = TextEditingController(
      text: widget.task.maxVolunteers.toString(),
    );
    _category = widget.task.category;
    _date = widget.task.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final UserModel? profile = await _firestoreService.getUserProfile(
      _authService.currentUser?.uid ?? '',
    );
    if (profile?.role != AppConstants.administratorRole) {
      if (!mounted) {
        return;
      }
      showTealErrorSnackBar(
        context,
        'Only administrators can edit tasks.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl = widget.task.imageUrl;
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadTaskImage(
          widget.task.id,
          _imageFile!,
        );
      }

      await _firestoreService.updateTask(widget.task.id, <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'maxVolunteers': int.tryParse(_capacityController.text) ?? 10,
        'category': _category,
        'date': _date,
        'imageUrl': imageUrl,
      });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task updated.')));
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
      appBar: AppBar(title: const Text('Edit task')),
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
                        else if (widget.task.imageUrl != null &&
                            widget.task.imageUrl!.isNotEmpty)
                          Image.network(widget.task.imageUrl!, fit: BoxFit.cover)
                        else
                          const Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.primary,
                              size: 48,
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
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task title'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
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
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
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
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
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
