import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> request;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();
  bool editing = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    request = widget.apiClient.profile();
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.apiClient.updateProfile({
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'phone': phone.text.trim(),
        'location': location.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        editing = false;
        request = widget.apiClient.profile();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile could not be saved.')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PagePadding(
    child: FutureBuilder<Map<String, dynamic>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'We could not load your profile.',
            onRetry: () => setState(() => request = widget.apiClient.profile()),
          );
        }
        final profile = snapshot.data ?? const <String, dynamic>{};
        firstName.text = profile['firstName'] as String? ?? '';
        lastName.text = profile['lastName'] as String? ?? '';
        phone.text = profile['phone'] as String? ?? '';
        location.text = profile['location'] as String? ?? '';
        final name = '${firstName.text} ${lastName.text}'.trim().isEmpty
            ? 'Your profile'
            : '${firstName.text} ${lastName.text}'.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Avatar(name: name, radius: 42),
                  const SizedBox(height: 10),
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  Text(profile['email'] as String? ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionCard(
              child: Column(
                children: [
                  _field(firstName, 'First name'),
                  _field(lastName, 'Last name'),
                  _field(phone, 'Phone'),
                  _field(location, 'Location'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (editing)
              ElevatedButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              )
            else
              OutlinedButton(
                onPressed: () => setState(() => editing = true),
                child: const Text('Edit profile'),
              ),
            const SizedBox(height: 8),
            ListTile(
              onTap: () => context.push('/settings'),
              title: const Text('Account and notification settings'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        );
      },
    ),
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      enabled: editing,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

