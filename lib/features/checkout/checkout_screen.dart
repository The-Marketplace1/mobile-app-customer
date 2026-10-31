import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.apiClient,
    required this.bookingId,
    super.key,
  });

  final ApiClient apiClient;
  final String bookingId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? paymentStatus;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await widget.apiClient.paymentStatus(widget.bookingId);
      if (mounted) {
        setState(() => paymentStatus = response['status'] as String?);
      }
    } on DioException {
      if (mounted) {
        setState(() => error = 'Payment status is unavailable. Try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openCheckout() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await widget.apiClient.startCheckout(widget.bookingId);
      final checkoutUrl = Uri.tryParse(
        response['checkoutUrl'] as String? ?? '',
      );
      if (checkoutUrl == null ||
          checkoutUrl.scheme != 'https' ||
          checkoutUrl.host.isEmpty ||
          checkoutUrl.userInfo.isNotEmpty) {
        throw const FormatException(
          'The payment service did not return a secure checkout link.',
        );
      }
      final opened = await launchUrl(
        checkoutUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw const FormatException('Secure checkout could not be opened.');
      }
      await refreshStatus();
    } on DioException catch (exception) {
      if (mounted) {
        setState(
          () => error = exception.message ?? 'Checkout could not be started.',
        );
      }
    } on FormatException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'succeeded';

  @override
  Widget build(BuildContext context) => PagePadding(
    child: Center(
      child: SectionCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isPaid ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              size: 44,
              color: isPaid
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              isPaid ? 'Booking confirmed' : 'Secure checkout',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isPaid
                  ? 'The payment service confirmed your booking.'
                  : paymentStatus == null
                  ? 'Your booking is ready. Payment is handled by the payment service.'
                  : 'Payment status: $paymentStatus. Complete the hosted checkout, then check again.',
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            if (isPaid)
              ElevatedButton(
                onPressed: () => context.go('/bookings'),
                child: const Text('View bookings'),
              )
            else ...[
              ElevatedButton(
                onPressed: busy ? null : openCheckout,
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Open secure checkout'),
              ),
              TextButton(
                onPressed: busy ? null : refreshStatus,
                child: const Text('Check payment status'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

