import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class ProfessionalScreen extends StatelessWidget {
  const ProfessionalScreen({
    required this.apiClient,
    required this.professionalId,
    super.key,
  });

  final ApiClient apiClient;
  final String professionalId;

  @override
  Widget build(BuildContext context) => FutureBuilder<Professional>(
    future: apiClient.professional(professionalId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LoadingState();
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return const ErrorState(message: 'This professional is unavailable.');
      }
      final professional = snapshot.data!;
      return PagePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Avatar(
                  name: professional.name,
                  url: professional.avatarUrl,
                  radius: 42,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        professional.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(professional.title),
                      const SizedBox(height: 7),
                      StatusPill(professional.category),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    professional.bio.isEmpty
                        ? 'Profile details are provided by this professional.'
                        : professional.bio,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFE7A83E)),
                      Text(' ${professional.rating.toStringAsFixed(1)}'),
                      Text('  ${professional.reviewCount} reviews'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(professional.location)),
                  Text(
                    'From ₦${professional.startingPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => context.push(
                '/booking/new?professionalId=${professional.id}',
              ),
              child: const Text('Book this professional'),
            ),
          ],
        ),
      );
    },
  );
}

