import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) => PagePadding(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Messages', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Keep conversations, files, and booking questions together.',
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<Conversation>>(
          future: apiClient.conversations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }
            if (snapshot.hasError) {
              return const ErrorState(message: 'We could not load messages.');
            }
            final conversations = snapshot.data ?? [];
            if (conversations.isEmpty) {
              return const SectionCard(
                child: Text('Your conversations will appear here.'),
              );
            }
            return Column(
              children: conversations
                  .map(
                    (conversation) => _ConversationTile(
                      conversation: conversation,
                      onTap: () => context.push('/messages/${conversation.id}'),
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.white,
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Avatar(
        name: conversation.professionalName,
        url: conversation.professionalAvatarUrl,
        radius: 25,
      ),
      title: Text(conversation.professionalName),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conversation.unreadCount > 0
          ? CircleAvatar(
              radius: 12,
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(fontSize: 11),
              ),
            )
          : const Icon(Icons.chevron_right_rounded),
    ),
  );
}

