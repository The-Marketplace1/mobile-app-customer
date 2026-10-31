import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({
    required this.apiClient,
    this.showHome = false,
    super.key,
  });

  final ApiClient apiClient;
  final bool showHome;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final search = TextEditingController();
  late Future<List<Professional>> request;
  List<String> categories = const [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    request = widget.apiClient.professionals().then((items) {
      categories =
          items
              .map((professional) => professional.category.trim())
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return items;
    });
  }

  void reload() {
    setState(() {
      request = widget.apiClient.professionals(
        search: search.text.trim().isEmpty ? null : search.text.trim(),
        category: selectedCategory,
      );
    });
  }

  void _selectCategory(String? value) {
    setState(() => selectedCategory = value);
    reload();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            widget.showHome
                ? 'Find good people\nto do good work.'
                : 'Find your person.',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 12),
          Text(
            widget.showHome
                ? 'Trusted local professionals, with the clarity to choose confidently.'
                : 'Search local professionals by service, skill, or name.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          TextField(
            controller: search,
            onSubmitted: (_) => reload(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search services or people',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: reload,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) => _selectCategory(null),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        onSelected: (_) => _selectCategory(
                          selectedCategory == category ? null : category,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.showHome) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _StatCard(value: 'Protected', label: 'payments'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(value: 'Local', label: 'professionals'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(value: 'Clear', label: 'next steps'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Text(
            widget.showHome ? 'A few good options' : 'Professionals nearby',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Professional>>(
            future: request,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: LoadingState(),
                );
              }
              if (snapshot.hasError) {
                return ErrorState(
                  message: 'We could not load professionals right now.',
                  onRetry: reload,
                );
              }
              final professionals = snapshot.data ?? [];
              if (professionals.isEmpty) {
                return const SectionCard(
                  child: Text(
                    'No professionals matched that search. Try a broader term or another category.',
                  ),
                );
              }
              return Column(
                children: professionals
                    .map(
                      (professional) => _ProfessionalTile(
                        professional: professional,
                        onTap: () =>
                            context.push('/professionals/${professional.id}'),
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
}

class _ProfessionalTile extends StatelessWidget {
  const _ProfessionalTile({required this.professional, required this.onTap});

  final Professional professional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Avatar(
              name: professional.name,
              url: professional.avatarUrl,
              radius: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    professional.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(professional.title),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFE7A83E),
                      ),
                      Text(' ${professional.rating.toStringAsFixed(1)}'),
                      const SizedBox(width: 10),
                      Text(
                        professional.location,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.ink,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

