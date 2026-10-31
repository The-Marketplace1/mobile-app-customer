import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({
    required this.apiClient,
    required this.bookingId,
    super.key,
  });

  final ApiClient apiClient;
  final String bookingId;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final details = TextEditingController();
  String reason = 'Service concern';
  bool busy = false;
  String? error;

  Future<void> submit() async {
    if (details.text.trim().isEmpty) {
      setState(
        () => error = 'Add a few details so support can review the issue.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.apiClient.submitDispute(
        bookingId: widget.bookingId,
        reason: reason,
        details: details.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your dispute was submitted for review.')),
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Your dispute could not be submitted.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PagePadding(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get help with a booking',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Share the issue with the support workflow. Resolution decisions stay with the backend and support teams.',
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(
                    value: 'Service concern',
                    child: Text('Service concern'),
                  ),
                  DropdownMenuItem(
                    value: 'Payment concern',
                    child: Text('Payment concern'),
                  ),
                  DropdownMenuItem(
                    value: 'Safety concern',
                    child: Text('Safety concern'),
                  ),
                ],
                onChanged: (value) => setState(() => reason = value ?? reason),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: details,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  hintText: 'Tell us what happened.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (error != null) ...[
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 10),
        ],
        ElevatedButton(
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Submitting…' : 'Submit securely'),
        ),
      ],
    ),
  );
}

