import 'package:flutter/material.dart';

import 'package:feedback_app/features/auth/presentation/pages/profile_page.dart';
import 'package:feedback_app/features/feedback/presentation/pages/feedback_list_page.dart';
import 'package:feedback_app/features/polls/presentation/pages/polls_list_page.dart';

/// Bottom-navigation shell for the citizen app: Polls, Feedback, Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [PollsListPage(), FeedbackListPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.poll_outlined), selectedIcon: Icon(Icons.poll), label: 'Polls'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Feedback'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
