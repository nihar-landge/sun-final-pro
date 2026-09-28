import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/shared/widgets/cards.dart';
import 'package:feedback_app/shared/widgets/states.dart';

/// Guided multi-step report creation:
/// category → describe → photos → location → similar reports → submit.
class ReportWizardPage extends StatefulWidget {
  const ReportWizardPage({super.key});

  @override
  State<ReportWizardPage> createState() => _ReportWizardPageState();
}

class _ReportWizardPageState extends State<ReportWizardPage> {
  int _step = 0;
  FeedbackCategory? _category;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _similarChecked = false;
  List<FeedbackItem> _similar = const [];
  final List<Uint8List> _photoBytes = [];
  final List<String> _photoPaths = [];
  bool _uploading = false;

  List<(FeedbackCategory, String, IconData)> _categories(
          AppLocalizations l10n) =>
      [
        (FeedbackCategory.roads, l10n.wizardCategoryRoads, Icons.construction),
        (FeedbackCategory.electricity, l10n.wizardCategoryStreetLights,
            Icons.lightbulb_outline),
        (FeedbackCategory.sanitation, l10n.wizardCategoryWaste,
            Icons.delete_outline),
        (FeedbackCategory.water, l10n.wizardCategoryWater,
            Icons.water_drop_outlined),
        (FeedbackCategory.transport, l10n.wizardCategoryTraffic,
            Icons.traffic_outlined),
        (FeedbackCategory.other, l10n.wizardCategoryPublicSpaces,
            Icons.park_outlined),
      ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
        0 => _category != null,
        1 =>
          _titleController.text.trim().isNotEmpty &&
              _descriptionController.text.trim().isNotEmpty,
        2 => true, // photos optional (0-3)
        3 => _lat != null && _lng != null,
        _ => true,
      };

  Future<void> _useMyLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        _snackWithAction(
          l10n.wizardLocationBlocked,
          actionLabel: l10n.wizardOpenSettings,
          onAction: () => Geolocator.openAppSettings(),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _snack(l10n.wizardLocationDenied);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
    } catch (_) {
      _snack(l10n.wizardLocationFailed);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onManualCoordsChanged() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    setState(() {
      _lat = (lat != null && lat.abs() <= 90) ? lat : null;
      _lng = (lng != null && lng.abs() <= 180) ? lng : null;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _snackWithAction(String message,
      {required String actionLabel,
      required Future<void> Function() onAction}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: () async {
            await onAction();
          },
        ),
      ));
  }

  /// The differentiating step: check for similar reports nearby before
  /// submitting, using the PostGIS near-me query (~300 m, same category).
  Future<void> _checkSimilar() async {
    if (_lat == null || _lng == null) return;
    setState(() => _similarChecked = true);
    try {
      final nearby = await context
          .read<FeedbackBloc>()
          .repository
          .nearMe(lat: _lat!, lng: _lng!, radiusKm: 0.3);
      setState(() {
        _similar = nearby
            .where((r) => r.category == _category && r.status != FeedbackStatus.resolved)
            .toList();
      });
    } on Failure {
      // Similar-report check is best-effort — never block submission.
    }
  }

  void _submit() {
    context.read<FeedbackBloc>().add(FeedbackSubmitted(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category!,
          latitude: _lat,
          longitude: _lng,
        ));
  }

  /// Uploads picked photos to the freshly created report, with progress.
  Future<void> _uploadPhotos(int reportId) async {
    if (_photoBytes.isEmpty) return;
    final repository = context.read<FeedbackBloc>().repository;
    var done = 0;

    void Function(void Function())? updateDialog;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          updateDialog = setDialogState;
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: _photoBytes.length == 1
                      ? null
                      : done / _photoBytes.length,
                ),
                const SizedBox(height: 14),
                Text(AppLocalizations.of(dialogContext).wizardUploadingPhotos),
              ],
            ),
          );
        },
      ),
    );

    for (var i = 0; i < _photoBytes.length; i++) {
      final contentType =
          _photoPaths[i].endsWith('.png') ? 'image/png' : 'image/jpeg';
      try {
        await repository.uploadPhoto(
          reportId,
          FeedbackPhoto(
              path: _photoPaths[i],
              bytes: _photoBytes[i],
              contentType: contentType),
        );
      } on Failure {
        // Report is already saved — a photo failure must not lose it.
      }
      done++;
      updateDialog?.call(() {});
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // close the progress dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackBloc, FeedbackState>(
      listener: (context, state) {
        if (state is FeedbackActionSuccess) {
          final created = state.items.isNotEmpty ? state.items.last : null;
          if (created != null && _photoBytes.isNotEmpty && !_uploading) {
            _uploading = true;
            _uploadPhotos(created.id).then((_) {
              _uploading = false;
              if (mounted) _showCreated(created);
            });
          } else {
            _showCreated(created);
          }
        } else if (state is FeedbackFailure) {
          _snack(state.message);
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        if (state is FeedbackSubmitting) {
          return const Center(child: CircularProgressIndicator());
        }
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.wizardTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(5, (i) {
                    final active = i <= _step;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _stepBody(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _step--;
                            if (_step < 4) _similarChecked = false;
                          }),
                          child: Text(l10n.commonBack),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: !_canContinue
                            ? null
                            : () {
                                if (_step < 3) {
                                  if (_step == 2) _checkSimilar();
                                  setState(() => _step++);
                                } else {
                                  _submit();
                                }
                              },
                        child: Text(_step < 3
                            ? l10n.commonContinue
                            : l10n.wizardSubmitReport),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _stepCategory();
      case 1:
        return _stepDescribe();
      case 2:
        return _stepPhotos();
      case 3:
        return _stepLocation();
      default:
        return _stepSimilar();
    }
  }

  Widget _stepCategory() {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.wizardCategoryQuestion,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: _categories(l10n).map((entry) {
            final (category, label, icon) = entry;
            final selected = _category == category;
            final scheme = Theme.of(context).colorScheme;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _category = category),
              child: Container(
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 26,
                        color: selected ? scheme.primary : scheme.onSurfaceVariant),
                    const SizedBox(height: 6),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepDescribe() {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.wizardDescribeTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(hintText: l10n.wizardTitleHint),
          maxLength: 200,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
              hintText: l10n.wizardDescriptionHint,
              alignLabelWithHint: true),
          maxLines: 5,
          maxLength: 5000,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photoBytes.length >= 3) return;
    final l10n = AppLocalizations.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes.add(bytes);
        _photoPaths.add(picked.path);
      });
    } catch (_) {
      _snack(l10n.wizardPickPhotoError);
    }
  }

  Widget _stepPhotos() {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.wizardAddPhotos,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(l10n.wizardPhotosHint,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < _photoBytes.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _photoBytes[i],
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _photoBytes.removeAt(i);
                          _photoPaths.removeAt(i);
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_photoBytes.length < 3)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final source = await showModalBottomSheet<ImageSource>(
                    context: context,
                    showDragHandle: true,
                    builder: (sheetContext) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt_outlined),
                            title: Text(l10n.wizardTakePhoto),
                            onTap: () =>
                                Navigator.of(sheetContext).pop(ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_outlined),
                            title: Text(l10n.wizardChooseGallery),
                            onTap: () =>
                                Navigator.of(sheetContext).pop(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (source != null) _pickPhoto(source);
                },
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Icon(Icons.add_a_photo_outlined,
                      size: 30, color: scheme.outline),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepLocation() {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasLocation = _lat != null && _lng != null;
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.wizardLocationQuestion,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 44,
                    color: hasLocation ? scheme.primary : scheme.outline),
                const SizedBox(height: 8),
                Text(
                  hasLocation
                      ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                      : l10n.wizardNoLocationYet,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasLocation ? scheme.primary : null),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: Text(l10n.wizardUseMyLocation),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.wizardManualEntryTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: l10n.wizardLatitude,
                  hintText: '18.52043',
                  errorText: _latError(l10n),
                ),
                onChanged: (_) => _onManualCoordsChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lngController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: l10n.wizardLongitude,
                  hintText: '73.85674',
                  errorText: _lngError(l10n),
                ),
                onChanged: (_) => _onManualCoordsChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.wizardLocationNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String? _latError(AppLocalizations l10n) {
    final text = _latController.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value.abs() > 90) return l10n.wizardInvalid;
    return null;
  }

  String? _lngError(AppLocalizations l10n) {
    final text = _lngController.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value.abs() > 180) return l10n.wizardInvalid;
    return null;
  }

  Widget _stepSimilar() {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.wizardSimilarTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(l10n.wizardSimilarSubtitle,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        if (!_similarChecked)
          EmptyState(
            icon: Icons.search,
            title: l10n.wizardCheckingNearby,
          )
        else if (_similar.isEmpty)
          EmptyState(
            icon: Icons.task_alt,
            title: l10n.wizardNoSimilarTitle,
            subtitle: l10n.wizardNoSimilarSubtitle,
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.wizardSimilarFound(_similar.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._similar.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ReportCard(
                      item: item,
                      distanceLabel: l10n.wizardSimilarDistance,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FeedbackDetailPage(feedbackId: item.id),
                      )),
                      onUpvote: () => context
                          .read<FeedbackBloc>()
                          .add(UpvoteRequested(item.id)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.wizardStillFileReport,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCreated(FeedbackItem? created) {
    if (created == null) {
      Navigator.of(context).maybePop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(l10n.wizardSubmittedTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(l10n.wizardSubmittedTrack(created.id),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => FeedbackDetailPage(feedbackId: created.id),
                ));
              },
              child: Text(l10n.wizardTrackReport),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).maybePop();
              },
              child: Text(l10n.wizardBackHome),
            ),
          ],
        ),
      ),
    );
  }
}
