import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/core/constants/app_constants.dart';
import 'package:feedback_app/core/l10n/entity_labels.dart';
import 'package:feedback_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:feedback_app/features/auth/presentation/pages/login_page.dart';
import 'package:feedback_app/features/feedback/domain/entities/feedback.dart';
import 'package:feedback_app/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_detail_page.dart';
import 'package:feedback_app/features/profile/presentation/pages/about_page.dart';
import 'package:feedback_app/features/profile/presentation/bloc/locale_cubit.dart';
import 'package:feedback_app/features/profile/presentation/bloc/theme_cubit.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';

/// Profile — account, my reports, preferences (theme, language) and logout.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final l10n = AppLocalizations.of(context);
    final user = authState is Authenticated ? authState.user : null;
    final name = user?.name ?? l10n.profileFallbackName;
    final email = user?.email ?? '';

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
                    if (email.isNotEmpty)
                      Text(email,
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
          _SectionTitle(l10n.profileSectionActivity),
          _MyReportsCard(),

          _SectionTitle(l10n.profileSectionPreferences),
          Card(
            child: Column(
              children: [
                const _ThemeSelector(),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const _LanguageSelector(),
              ],
            ),
          ),

          _SectionTitle(l10n.profileSectionPrivacy),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l10n.profileAnonymousVotingTitle),
                  subtitle: Text(l10n.profileAnonymousVotingSubtitle),
                  trailing: const Icon(Icons.check_circle,
                      color: Colors.green, size: 20),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.location_off_outlined),
                  title: Text(l10n.profileLocationSharingTitle),
                  subtitle: Text(l10n.profileLocationSharingSubtitle),
                  isThreeLine: true,
                ),
              ],
            ),
          ),

          _SectionTitle(l10n.profileSectionAbout),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text(AppConstants.appName),
              subtitle: Text(l10n.profileAboutSubtitle(l10n.appTagline)),
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
            label: Text(l10n.profileSignOut),
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

class _MyReportsCard extends StatefulWidget {
  const _MyReportsCard();

  @override
  State<_MyReportsCard> createState() => _MyReportsCardState();
}

class _MyReportsCardState extends State<_MyReportsCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedbackBloc, FeedbackState>(
      buildWhen: (prev, cur) =>
          (cur is FeedbackLoaded && cur.mine) ||
          cur is FeedbackLoading ||
          cur is FeedbackFailure,
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final items = switch (state) {
          FeedbackLoaded s when s.mine => s.items,
          _ => const <FeedbackItem>[],
        };
        final visible = _showAll ? items : items.take(3);
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
                    Text(l10n.profileReportsFiled,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...visible.map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.description_outlined,
                            size: 20),
                        title: Text(item.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          feedbackStatusLabel(context, item.status.name),
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
                  if (!_showAll && items.length > 3)
                    TextButton(
                      onPressed: () => setState(() => _showAll = true),
                      child: Text(l10n.profileViewAllReports(items.length)),
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
      title: Text(AppLocalizations.of(context).profileTheme),
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
    final l10n = AppLocalizations.of(context);
    final current = AppLanguage.forLocale(context.watch<LocaleCubit>().state);
    return ListTile(
      leading: const Icon(Icons.translate),
      title: Text(l10n.profileLanguage),
      subtitle: Text(current.nativeName),
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
                    title: Text(language.nativeName,
                        style: language == current
                            ? TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(sheetContext)
                                    .colorScheme
                                    .primary)
                            : null),
                    trailing: language == current
                        ? Icon(Icons.check_circle,
                            color:
                                Theme.of(sheetContext).colorScheme.primary)
                        : null,
                    onTap: () {
                      context.read<LocaleCubit>().setLocale(language.locale);
                      Navigator.of(sheetContext).pop();
                    },
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
