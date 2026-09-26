import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/constants/app_constants.dart';
import 'package:feedback_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:feedback_app/features/auth/presentation/pages/login_page.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/features/profile/presentation/pages/about_page.dart';
import 'package:feedback_app/features/profile/presentation/bloc/theme_cubit.dart';

/// Profile — account, my reports, preferences (theme, language) and logout.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final name = user?.name ?? 'Citizen';
    final phone = user?.phone ?? '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- account header ----
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    if (phone.isNotEmpty)
                      Text(phone,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const _SectionTitle('My activity'),
          _MyReportsCard(),

          const _SectionTitle('Preferences'),
          Card(
            child: Column(
              children: [
                const _ThemeSelector(),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const _LanguageSelector(),
              ],
            ),
          ),

          const _SectionTitle('Privacy'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Anonymous voting'),
                  subtitle: const Text(
                      'Your votes are always anonymous by design — results can never be traced back to you.'),
                  trailing: const Icon(Icons.check_circle,
                      color: Colors.green, size: 20),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.location_off_outlined),
                  title: const Text('Location sharing'),
                  subtitle: const Text(
                      'Only attached to a report when you choose to.'),
                  isThreeLine: true,
                ),
              ],
            ),
          ),

          const _SectionTitle('About'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text(AppConstants.appName),
              subtitle: const Text(
                  '${AppConstants.appTagline}\nCDAC Final Project — Mobile Computing'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutPage()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.outline)),
    );
  }
}

class _MyReportsCard extends StatelessWidget {
  const _MyReportsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedbackBloc, FeedbackState>(
      buildWhen: (prev, cur) =>
          (cur is FeedbackLoaded && cur.mine) ||
          cur is FeedbackLoading ||
          cur is FeedbackFailure,
      builder: (context, state) {
        final items = switch (state) {
          FeedbackLoaded s when s.mine => s.items,
          _ => const <FeedbackItem>[],
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${items.length}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Text('reports filed',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...items.take(3).map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.description_outlined,
                            size: 20),
                        title: Text(item.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          switch (item.status.name) {
                            'RESOLVED' => 'Resolved',
                            'IN_REVIEW' => 'In Review',
                            _ => 'Open',
                          },
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: switch (item.status.name) {
                                'RESOLVED' => Colors.green,
                                'IN_REVIEW' => Colors.amber.shade800,
                                _ => Colors.orange,
                              }),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FeedbackDetailPage(feedbackId: item.id),
                          ),
                        ),
                      )),
                  if (items.length > 3)
                    TextButton(
                      onPressed: () {},
                      child: Text('View all ${items.length} reports'),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    return ListTile(
      leading: Icon(switch (mode) {
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        _ => Icons.brightness_auto_rounded,
      }),
      title: const Text('Theme'),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18)),
          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 18)),
          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18)),
        ],
        selected: {mode},
        onSelectionChanged: (selection) =>
            context.read<ThemeCubit>().setMode(selection.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.translate),
      title: const Text('Language'),
      subtitle: const Text('English'),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final language in AppLanguage.values)
                  ListTile(
                    title: Text(language.nativeName),
                    subtitle: language == AppLanguage.english
                        ? null
                        : Text(language.subtitle),
                    trailing: language == AppLanguage.english
                        ? const Icon(Icons.check_circle)
                        : null,
                    enabled: language == AppLanguage.english,
                    onTap: () => Navigator.of(sheetContext).pop(),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
