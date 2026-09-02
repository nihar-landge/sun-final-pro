import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';

/// Report a new issue: category, title, description and optional location.
/// Photo upload to MinIO arrives in phase 2.
class SubmitFeedbackPage extends StatefulWidget {
  const SubmitFeedbackPage({super.key});

  @override
  State<SubmitFeedbackPage> createState() => _SubmitFeedbackPageState();
}

class _SubmitFeedbackPageState extends State<SubmitFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  FeedbackCategory _category = FeedbackCategory.roads;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _locating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location denied — enter coordinates manually')));
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get location — enter coordinates manually')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<FeedbackBloc>().add(FeedbackSubmitted(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          latitude: double.tryParse(_latController.text.trim()),
          longitude: double.tryParse(_lngController.text.trim()),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: BlocConsumer<FeedbackBloc, FeedbackState>(
        listener: (context, state) {
          if (state is FeedbackActionSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop();
          } else if (state is FeedbackFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final submitting = state is FeedbackSubmitting;
          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<FeedbackCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: FeedbackCategory.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name[0].toUpperCase() + c.name.substring(1)),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    maxLength: 200,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a short title' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        labelText: 'What is happening?', alignLabelWithHint: true),
                    maxLines: 4,
                    maxLength: 5000,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Describe the issue' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          decoration: const InputDecoration(labelText: 'Latitude (optional)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          decoration: const InputDecoration(labelText: 'Longitude'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _locating ? null : _useMyLocation,
                    icon: _locating
                        ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: const Text('Use my current location'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit feedback'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
