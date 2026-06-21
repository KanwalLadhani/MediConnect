import 'package:flutter/material.dart';

class PageShell extends StatelessWidget {
  const PageShell({
    required this.children,
    this.title,
    this.subtitle,
    this.actions,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(actions: actions),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}
