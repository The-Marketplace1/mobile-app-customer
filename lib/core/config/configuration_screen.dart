import 'package:flutter/material.dart';

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Marketplace setup',
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect the app to your API Gateway',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Set API_BASE_URL to the HTTPS base URL for the customer API, then rebuild the app. The app will not send requests to a placeholder service.',
                  ),
                  const SizedBox(height: 16),
                  const SelectableText(
                    'flutter run --dart-define=API_BASE_URL=https://your-gateway.example/api',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Map tracking also requires MAPBOX_ACCESS_TOKEN. REALTIME_URL is optional; without it, tracking and messaging refresh through the API.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

