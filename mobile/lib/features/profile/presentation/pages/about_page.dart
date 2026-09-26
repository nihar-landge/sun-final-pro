import 'package:flutter/material.dart';

import 'package:feedback_app/core/constants/app_constants.dart';

/// About CivicPulse — purpose, capabilities and technology stack.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.monitor_heart_outlined,
                  size: 40, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(AppConstants.appName,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(AppConstants.appTagline,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 24),
          Text('What you can do',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...[
            'Participate in public polls with live results',
            'Report local issues with photos and GPS location',
            'Find and support similar reports nearby',
            'Track issue resolution with official updates',
            'Receive push notifications on status changes',
          ].map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          Text('Built with',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tech in const [
                'Flutter', 'Spring Boot', 'PostgreSQL + PostGIS', 'Redis',
                'RabbitMQ', 'Kubernetes', 'Firebase FCM', 'Docker',
              ])
                Chip(label: Text(tech, style: const TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'CDAC Final Project — Mobile Computing\n'
            'Microservices · Clean Architecture · One person, one vote',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
