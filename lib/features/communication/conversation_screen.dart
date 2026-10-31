import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import '../../core/realtime/realtime_client.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.apiClient,
    required this.realtimeClient,
    required this.conversationId,
    super.key,
  });

  final ApiClient apiClient;
  final RealtimeClient realtimeClient;
  final String conversationId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final composer = TextEditingController();
  final imagePicker = ImagePicker();
  late Future<List<Message>> request;
  StreamSubscription<Map<String, dynamic>>? events;
  bool sending = false;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    request = widget.apiClient.messages(widget.conversationId);
    widget.realtimeClient.connect();
    events = widget.realtimeClient.events.listen((event) {
      if (event['conversationId'] == widget.conversationId && mounted) {
        setState(
          () => request = widget.apiClient.messages(widget.conversationId),
        );
      }
    });
  }

  @override
  void dispose() {
    composer.dispose();
    events?.cancel();
    super.dispose();
  }

  Future<void> send() async {
    if (composer.text.trim().isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await widget.apiClient.sendMessage(
        widget.conversationId,
        composer.text.trim(),
      );
      composer.clear();
      if (mounted) {
        setState(
          () => request = widget.apiClient.messages(widget.conversationId),
        );
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message could not be sent.')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> attachImage() async {
    if (uploading) return;
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    setState(() => uploading = true);
    try {
      await widget.apiClient.uploadAttachment(
        conversationId: widget.conversationId,
        file: image,
      );
      if (!mounted) return;
      setState(
        () => request = widget.apiClient.messages(widget.conversationId),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Image sent.')));
    } on DioException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exception.response?.statusCode == 413
                ? 'That image is too large to send.'
                : 'The image could not be uploaded.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Conversation'),
      actions: [
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start protected calls from the linked booking.'),
            ),
          ),
          icon: const Icon(Icons.phone_outlined),
          tooltip: 'Protected call',
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: FutureBuilder<List<Message>>(
            future: request,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return const ErrorState(
                  message: 'We could not load this conversation.',
                );
              }
              final messages = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final mine = message.sender == 'customer';
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFFE8F0E9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(message.body),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: uploading ? null : attachImage,
                  icon: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file_rounded),
                ),
                Expanded(
                  child: TextField(
                    controller: composer,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sending ? null : send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

