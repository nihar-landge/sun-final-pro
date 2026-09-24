import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/shared/widgets/cards.dart';
import 'package:feedback_app/shared/widgets/states.dart';

/// Guided multi-step report creation:
/// category → describe → location → similar reports → submit.
/// Photo capture arrives with MinIO upload (Phase 3).
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
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _similarChecked = false;
  List<FeedbackItem> _similar = const [];

  static const _categories = [
    (FeedbackCategory.roads, 'Roads', Icons.construction),
    (FeedbackCategory.electricity, 'Street Lights', Icons.lightbulb_outline),
    (FeedbackCategory.sanitation, 'Waste', Icons.delete_outline),
    (FeedbackCategory.water, 'Water', Icons.water_drop_outlined),
    (FeedbackCategory.transport, 'Traffic', Icons.traffic_outlined),
    (FeedbackCategory.other, 'Public Spaces', Icons.park_outlined),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
        0 => _category != null,
        1 =>
          _titleController.text.trim().isNotEmpty &&
              _descriptionController.text.trim().isNotEmpty,
        2 => _lat != null && _lng != null,
        _ => true,
      };

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _snack('Location permission denied — enter coordinates manually.');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    } catch (_) {
      _snack('Could not get your location. Enter coordinates manually.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackBloc, FeedbackState>(
      listener: (context, state) {
        if (state is FeedbackActionSuccess) {
          final created = state.items.isNotEmpty ? state.items.last : null;
          _showCreated(created);
        } else if (state is FeedbackFailure) {
          _snack(state.message);
        }
      },
      builder: (context, state) {
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
                  child: Text('Report an Issue',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(4, (i) {
                    final active = i <= _step;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
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
                            if (_step < 3) _similarChecked = false;
                          }),
                          child: const Text('Back'),
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
                        child: Text(_step < 3 ? 'Continue' : 'Submit Report'),
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
        return _stepLocation();
      default:
        return _stepSimilar();
    }
  }

  Widget _stepCategory() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is the problem?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: _categories.map((entry) {
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
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What's happening?",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
              hintText: 'Short title, e.g. "Large pothole near the bus stop"'),
          maxLength: 200,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
              hintText: 'Describe the issue — what, where exactly, since when…',
              alignLabelWithHint: true),
          maxLines: 5,
          maxLength: 5000,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _stepLocation() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where is the issue?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 44,
                    color:
                        _lat != null ? scheme.primary : scheme.outline),
                const SizedBox(height: 8),
                Text(
                  _lat != null
                      ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                      : 'No location set yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _lat != null ? scheme.primary : null),
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
                  label: const Text('Use my current location'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your location is used only for this report and helps the '
          'municipality find and fix the issue faster.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _stepSimilar() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Similar reports nearby',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('Reports within 300 m of your location, same category.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        if (!_similarChecked)
          const EmptyState(
            icon: Icons.search,
            title: 'Checking nearby reports…',
          )
        else if (_similar.isEmpty)
          const EmptyState(
            icon: Icons.task_alt,
            title: 'No similar reports',
            subtitle: 'You seem to be the first to spot this here.',
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
                    'We found ${_similar.length} similar report${_similar.length == 1 ? '' : 's'} nearby. '
                    'Supporting an existing report gets it fixed faster.',
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
                      distanceLabel: '<300 m',
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
                    child: Text(
                        'Still want to file your report? Submit below — '
                        'more reports raise priority.',
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
            Text('Report submitted!',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Report #${created.id} · track it from Alerts or Profile',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => FeedbackDetailPage(feedbackId: created.id),
                ));
              },
              child: const Text('Track your report'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
