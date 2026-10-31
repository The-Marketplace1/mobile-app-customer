import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({
    required this.apiClient,
    this.professionalId,
    super.key,
  });

  final ApiClient apiClient;
  final String? professionalId;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int step = 0;
  final service = TextEditingController(text: 'Service consultation');
  final location = TextEditingController();
  late Future<List<Professional>> professionals;
  String? professionalId;
  DateTime? date;
  TimeOfDay? time;
  String? error;
  bool busy = false;

  String get stepTitle => const [
    'Choose a service and professional',
    'Choose date and time',
    'Add your location',
    'Review and confirm',
  ][step];

  @override
  void initState() {
    super.initState();
    professionalId = widget.professionalId;
    professionals = widget.apiClient.professionals();
  }

  Future<void> next() async {
    setState(() => error = null);
    if (step == 3) {
      if (professionalId == null ||
          service.text.trim().isEmpty ||
          date == null ||
          time == null ||
          location.text.trim().isEmpty) {
        setState(
          () => error = 'Complete each booking detail before continuing.',
        );
        return;
      }
      setState(() => busy = true);
      try {
        final scheduledAt = DateTime(
          date!.year,
          date!.month,
          date!.day,
          time!.hour,
          time!.minute,
        );
        final booking = await widget.apiClient.createBooking(
          professionalId: professionalId!,
          service: service.text.trim(),
          scheduledAt: scheduledAt,
          location: location.text.trim(),
        );
        if (booking.id.isEmpty) {
          throw const FormatException(
            'The gateway did not return a booking reference.',
          );
        }
        if (mounted) context.go('/checkout/${booking.id}');
      } on DioException catch (exception) {
        if (mounted) {
          setState(
            () => error = exception.message ?? 'Booking could not be created.',
          );
        }
      } on FormatException catch (exception) {
        if (mounted) setState(() => error = exception.message);
      } finally {
        if (mounted) setState(() => busy = false);
      }
      return;
    }
    setState(() => step += 1);
  }

  @override
  void dispose() {
    service.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New booking', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Step ${step + 1} of 4 · $stepTitle'),
          const SizedBox(height: 18),
          LinearProgressIndicator(value: (step + 1) / 4),
          const SizedBox(height: 24),
          SectionCard(child: _stepBody(context)),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: busy ? null : next,
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(step == 3 ? 'Create booking' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    switch (step) {
      case 0:
        return Column(
          children: [
            TextField(
              controller: service,
              decoration: const InputDecoration(
                labelText: 'Service',
                hintText: 'What do you need help with?',
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Professional>>(
              future: professionals,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final items = snapshot.data ?? const <Professional>[];
                if (snapshot.hasError || items.isEmpty) {
                  return const Text(
                    'Professionals are unavailable. Return to Discover and try again.',
                  );
                }
                return DropdownButtonFormField<String>(
                  initialValue: items.any((item) => item.id == professionalId)
                      ? professionalId
                      : null,
                  decoration: const InputDecoration(labelText: 'Professional'),
                  items: items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => professionalId = value),
                );
              },
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(
                date == null
                    ? 'Choose a date'
                    : '${date!.day}/${date!.month}/${date!.year}',
              ),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (selected != null) setState(() => date = selected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(
                time == null ? 'Choose a time' : time!.format(context),
              ),
              onTap: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (selected != null) setState(() => time = selected);
              },
            ),
          ],
        );
      case 2:
        return TextField(
          controller: location,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Service location',
            hintText: 'Address or meeting location',
          ),
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.text, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              date == null
                  ? 'Date to be confirmed'
                  : '${date!.day}/${date!.month}/${date!.year}',
            ),
            Text(time == null ? 'Time to be confirmed' : time!.format(context)),
            Text(
              location.text.isEmpty
                  ? 'Location to be confirmed'
                  : location.text,
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Payment details are entered only on the payment service’s secure checkout.',
            ),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.credit_card_outlined),
              title: Text('Secure hosted checkout'),
              subtitle: Text('No card data is stored in this app.'),
            ),
          ],
        );
    }
  }
}

