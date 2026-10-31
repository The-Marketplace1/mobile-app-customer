import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    required this.apiClient,
    required this.bookingId,
    super.key,
  });

  final ApiClient apiClient;
  final String bookingId;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final comment = TextEditingController();
  int rating = 5;
  bool busy = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.apiClient.submitReview(
        bookingId: widget.bookingId,
        rating: rating,
        comment: comment.text.trim(),
      );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Your review could not be submitted.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PagePadding(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave a review',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Your feedback helps the next customer choose well.'),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: rating,
                decoration: const InputDecoration(labelText: 'Rating'),
                items: [1, 2, 3, 4, 5]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value stars'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => rating = value ?? 5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comment,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  hintText: 'What should other customers know?',
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
          child: Text(busy ? 'Sending…' : 'Submit review'),
        ),
      ],
    ),
  );
}

