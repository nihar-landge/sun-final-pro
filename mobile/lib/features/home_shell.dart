import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feedback_app/features/alerts/presentation/bloc/alerts_bloc.dart';
import 'package:feedback_app/features/alerts/presentation/pages/alerts_page.dart';
import 'package:feedback_app/features/feedback/presentation/pages/report_wizard_page.dart';
import 'package:feedback_app/features/home/home_page.dart';
import 'package:feedback_app/features/polls/presentation/pages/polls_list_page.dart';
import 'package:feedback_app/features/profile/presentation/pages/profile_page.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';

/// CivicPulse shell — 5 tabs: Home · Polls · Report · Alerts · Profile.
/// IndexedStack keeps each tab's scroll position and bloc state alive.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onNavigate: _go),
          const PollsListPage(),
          const ReportWizardPage(),
          const AlertsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(
            icon: Icon(_index == 0 ? Icons.home_rounded : Icons.home_outlined),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: Icon(_index == 1 ? Icons.how_to_vote_rounded : Icons.how_to_vote_outlined),
            label: l10n.navPolls,
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _index == 2
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  size: 24,
                  color: _index == 2
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary),
            ),
            label: l10n.navReport,
          ),
          NavigationDestination(
            icon: BlocBuilder<AlertsBloc, AlertsState>(
              builder: (context, state) {
                final unread =
                    state is AlertsLoaded ? state.unreadCount : 0;
                return Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: Icon(_index == 3
                      ? Icons.notifications_rounded
                      : Icons.notifications_outlined),
                );
              },
            ),
            label: l10n.navAlerts,
          ),
          NavigationDestination(
            icon: Icon(_index == 4 ? Icons.person_rounded : Icons.person_outline_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

/// Brand header used across tabs.
class BrandHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const BrandHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
