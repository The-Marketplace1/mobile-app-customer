import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import '../../core/realtime/realtime_client.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({
    required this.apiClient,
    required this.realtimeClient,
    required this.bookingId,
    super.key,
  });

  final ApiClient apiClient;
  final RealtimeClient realtimeClient;
  final String bookingId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late Future<BookingTracking> request;
  StreamSubscription<Map<String, dynamic>>? events;

  @override
  void initState() {
    super.initState();
    request = widget.apiClient.tracking(widget.bookingId);
    unawaited(_connectRealtime());
    events = widget.realtimeClient.events.listen((event) {
      if (event['bookingId'] == widget.bookingId && mounted) {
        setState(() => request = widget.apiClient.tracking(widget.bookingId));
      }
    });
  }

  @override
  void dispose() {
    events?.cancel();
    super.dispose();
  }

  Future<void> _connectRealtime() async {
    try {
      await widget.realtimeClient.connect();
    } on Object {
      // The tracking API remains available when realtime is offline.
    }
  }

  @override
  Widget build(BuildContext context) => PagePadding(
    child: FutureBuilder<BookingTracking>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorState(
            message: 'Live tracking is unavailable right now.',
            onRetry: () => setState(
              () => request = widget.apiClient.tracking(widget.bookingId),
            ),
          );
        }
        final tracking = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live tracking',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text('Updated through the realtime service.'),
            const SizedBox(height: 16),
            if (AppConfig.mapboxAccessToken.isNotEmpty)
              SectionCard(
                padding: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: 310,
                    child: MapWidget(
                      key: ValueKey(
                        'booking-map-${tracking.professionalLatitude}-${tracking.professionalLongitude}',
                      ),
                      viewport: CameraViewportState(
                        center: Point(
                          coordinates: Position(
                            (tracking.professionalLongitude +
                                    tracking.customerLongitude) /
                                2,
                            (tracking.professionalLatitude +
                                    tracking.customerLatitude) /
                                2,
                          ),
                        ),
                        zoom: _zoomFor(tracking),
                      ),
                      onMapCreated: (map) =>
                          _addTrackingAnnotations(map, tracking),
                      styleUri: MapboxStyles.STANDARD,
                    ),
                  ),
                ),
              ),
            if (AppConfig.mapboxAccessToken.isEmpty)
              const SectionCard(
                child: Text(
                  'Map tracking is not configured on this build. Set MAPBOX_ACCESS_TOKEN to display the backend-provided locations.',
                ),
              ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Avatar(
                        name: tracking.professionalName,
                        url: tracking.professionalAvatarUrl,
                        radius: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tracking.professionalName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      StatusPill(_stageLabel(tracking.jobStage)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tracking.etaMinutes != null)
                    Text(
                      '${tracking.etaMinutes} minutes away',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  if (tracking.distanceMeters != null)
                    Text(
                      tracking.distanceMeters! >= 1000
                          ? '${(tracking.distanceMeters! / 1000).toStringAsFixed(1)} km away'
                          : '${tracking.distanceMeters!.round()} m away',
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Your service location is shown with the professional route and current position supplied by the backend.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  double _zoomFor(BookingTracking tracking) {
    final delta = math.max(
      (tracking.professionalLatitude - tracking.customerLatitude).abs(),
      (tracking.professionalLongitude - tracking.customerLongitude).abs(),
    );
    if (delta > 5) return 5.5;
    if (delta > 1) return 8;
    if (delta > 0.25) return 10;
    if (delta > 0.05) return 12;
    return 14;
  }

  Future<void> _addTrackingAnnotations(
    MapboxMap map,
    BookingTracking tracking,
  ) async {
    final pointManager = await map.annotations.createCircleAnnotationManager();
    await pointManager.createMulti([
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            tracking.professionalLongitude,
            tracking.professionalLatitude,
          ),
        ),
        circleColor: const Color(0xFF246B4A).toARGB32(),
        circleRadius: 9,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3,
      ),
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            tracking.customerLongitude,
            tracking.customerLatitude,
          ),
        ),
        circleColor: const Color(0xFFDF8D3A).toARGB32(),
        circleRadius: 8,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3,
      ),
    ]);

    if (tracking.routeCoordinates.length >= 2) {
      final routeManager = await map.annotations
          .createPolylineAnnotationManager();
      await routeManager.create(
        PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: tracking.routeCoordinates
                .map((coordinate) => Position(coordinate[0], coordinate[1]))
                .toList(),
          ),
          lineColor: const Color(0xFF246B4A).toARGB32(),
          lineWidth: 4,
        ),
      );
    }
  }

  String _stageLabel(String value) => switch (value) {
    'on_the_way' => 'On the way',
    'in_progress' => 'In progress',
    'awaiting_review' => 'Awaiting review',
    'completed' => 'Completed',
    _ => 'Confirmed',
  };
}

