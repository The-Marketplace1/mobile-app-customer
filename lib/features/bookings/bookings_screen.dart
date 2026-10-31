import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import '../communication/call_button.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late Future<List<Booking>> request;

  @override
  void initState() {
    super.initState();
    request = widget.apiClient.bookings();
  }

  @override
  Widget build(BuildContext context) => PagePadding(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bookings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Your upcoming plans, active work, and completed services.'),
        const SizedBox(height: 20),
        FutureBuilder<List<Booking>>(
          future: request,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'We could not load your bookings.',
                onRetry: () =>
                    setState(() => request = widget.apiClient.bookings()),
              );
            }
            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return SectionCard(
                child: Column(
                  children: [
                    const Text('No bookings yet.'),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => context.go('/discover'),
                      child: const Text('Discover professionals'),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: bookings
                  .map(
                    (booking) => _BookingCard(
                      booking: booking,
                      apiClient: widget.apiClient,
                      onChanged: () =>
                          setState(() => request = widget.apiClient.bookings()),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class _BookingCard extends StatefulWidget {
  const _BookingCard({
    required this.booking,
    required this.apiClient,
    required this.onChanged,
  });

  final Booking booking;
  final ApiClient apiClient;
  final VoidCallback onChanged;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool busy = false;

  Future<void> cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text(
          'Cancellation eligibility and any refund are handled by the booking service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _perform(
      () => widget.apiClient.cancelBooking(widget.booking.id),
      'Booking cancelled.',
    );
  }

  Future<void> reschedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await _perform(
      () => widget.apiClient.rescheduleBooking(
        widget.booking.id,
        scheduledAt: scheduledAt,
      ),
      'Reschedule request sent.',
    );
  }

  Future<void> _perform(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
      widget.onChanged();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The booking could not be updated.')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Avatar(
              name: widget.booking.professionalName,
              url: widget.booking.professionalAvatarUrl,
              radius: 25,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.booking.service,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('with ${widget.booking.professionalName}'),
                ],
              ),
            ),
            StatusPill(widget.booking.status),
          ],
        ),
        const SizedBox(height: 18),
        Text('${widget.booking.date} · ${widget.booking.time}'),
        const SizedBox(height: 4),
        Text(widget.booking.location),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              '₦${widget.booking.amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            if (widget.booking.status == 'active')
              TextButton(
                onPressed: () =>
                    context.push('/bookings/${widget.booking.id}/tracking'),
                child: const Text('Track job'),
              ),
            if (widget.booking.status == 'upcoming' ||
                widget.booking.status == 'active')
              CallButton(
                apiClient: widget.apiClient,
                bookingId: widget.booking.id,
              ),
            if (widget.booking.status == 'completed')
              TextButton(
                onPressed: () =>
                    context.push('/bookings/${widget.booking.id}/review'),
                child: const Text('Review'),
              ),
          ],
        ),
        if (widget.booking.canCancel || widget.booking.canReschedule) ...[
          const Divider(height: 20),
          Wrap(
            spacing: 8,
            children: [
              if (widget.booking.canReschedule)
                OutlinedButton.icon(
                  onPressed: busy ? null : reschedule,
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Reschedule'),
                ),
              if (widget.booking.canCancel)
                TextButton.icon(
                  onPressed: busy ? null : cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ],
        if (widget.booking.status == 'completed')
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  context.push('/bookings/${widget.booking.id}/dispute'),
              child: const Text('Need help?'),
            ),
          ),
      ],
    ),
  );
}

