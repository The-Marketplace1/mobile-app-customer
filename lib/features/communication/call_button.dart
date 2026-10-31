import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class CallButton extends StatefulWidget {
  const CallButton({
    required this.apiClient,
    required this.bookingId,
    super.key,
  });

  final ApiClient apiClient;
  final String bookingId;

  @override
  State<CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<CallButton> {
  String? callId;
  bool busy = false;

  Future<void> toggle() async {
    setState(() => busy = true);
    try {
      if (callId == null) {
        final record = await widget.apiClient.requestCall(widget.bookingId);
        setState(() => callId = record.id);
      } else {
        await widget.apiClient.endCall(callId!);
        setState(() => callId = null);
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The protected call could not be completed.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: busy ? null : toggle,
    icon: Icon(callId == null ? Icons.phone_outlined : Icons.call_end),
    label: Text(callId == null ? 'Call' : 'End call'),
  );
}

