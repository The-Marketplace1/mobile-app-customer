import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PagePadding extends StatelessWidget {
  const PagePadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    child: child,
  );
}

class Avatar extends StatelessWidget {
  const Avatar({required this.name, this.url, this.radius = 24, super.key});

  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE9E2D7),
      backgroundImage: url != null && url!.isNotEmpty
          ? NetworkImage(url!)
          : null,
      child: url == null || url!.isEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({required this.child, this.padding = 18, super.key});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE7F0E9),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF39694D),
        ),
      ),
    ),
  );
}

