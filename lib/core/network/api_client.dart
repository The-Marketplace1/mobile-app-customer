import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../storage/session_store.dart';
import 'models.dart';

class ApiClient {
  ApiClient(this.sessionStore)
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final baseUri = Uri.tryParse(options.baseUrl);
          final prefix = baseUri?.path.replaceFirst(RegExp(r'/+$'), '');
          if (baseUri != null &&
              prefix != null &&
              prefix.isNotEmpty &&
              options.path.startsWith('/')) {
            options
              ..path = '$prefix${options.path}'
              ..baseUrl = baseUri.origin;
          }
          final token = await sessionStore.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final options = error.requestOptions;
          final shouldRefresh =
              error.response?.statusCode == 401 &&
              !options.path.contains('/auth/') &&
              options.extra['sessionRetry'] != true;
          if (!shouldRefresh) {
            handler.next(error);
            return;
          }
          try {
            final token = await _refreshAccessToken();
            if (token == null) {
              await sessionStore.clear();
              onSessionExpired?.call();
              handler.next(error);
              return;
            }
            options
              ..headers['Authorization'] = 'Bearer $token'
              ..extra['sessionRetry'] = true;
            final response = await dio.fetch<dynamic>(options);
            handler.resolve(response);
          } on Object {
            await sessionStore.clear();
            onSessionExpired?.call();
            handler.next(error);
          }
        },
      ),
    );
  }

  final SessionStore sessionStore;
  final Dio dio;
  Future<String?>? _refreshInFlight;
  void Function()? onSessionExpired;

  String _pathSegment(String value) => Uri.encodeComponent(value);

  Future<String?> _refreshAccessToken() {
    final current = _refreshInFlight;
    if (current != null) return current;
    final refresh = _refreshFromGateway();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _refreshFromGateway() async {
    final refreshToken = await sessionStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final accessToken = response.data?['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException('The gateway returned no refreshed session.');
    }
    await sessionStore.save(
      accessToken: accessToken,
      refreshToken: response.data?['refreshToken'] as String? ?? refreshToken,
    );
    return accessToken;
  }

  Future<List<Professional>> professionals({
    String? search,
    String? category,
  }) async {
    final response = await dio.get<List<dynamic>>(
      '/professionals',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Professional.fromJson)
        .toList();
  }

  Future<Professional> professional(String id) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/professionals/${_pathSegment(id)}',
    );
    return Professional.fromJson(response.data ?? const {});
  }

  Future<List<Booking>> bookings() async {
    final response = await dio.get<List<dynamic>>('/bookings');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Booking.fromJson)
        .toList();
  }

  Future<BookingTracking> tracking(String id) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/bookings/${_pathSegment(id)}/tracking',
    );
    return BookingTracking.fromJson(response.data ?? const {});
  }

  Future<List<Conversation>> conversations() async {
    final response = await dio.get<List<dynamic>>('/conversations');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList();
  }

  Future<List<Message>> messages(String conversationId) async {
    final response = await dio.get<List<dynamic>>(
      '/conversations/${_pathSegment(conversationId)}/messages',
    );
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Message.fromJson)
        .toList();
  }

  Future<Message> sendMessage(String conversationId, String body) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/conversations/${_pathSegment(conversationId)}/messages',
      data: {'body': body},
    );
    return Message.fromJson(response.data ?? const {});
  }

  Future<List<NotificationItem>> notifications() async {
    final response = await dio.get<List<dynamic>>('/notifications');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await dio.patch<void>(
      '/notifications/${_pathSegment(notificationId)}/read',
    );
  }

  Future<Map<String, bool>> notificationPreferences() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/notifications/preferences',
    );
    final values = response.data ?? const <String, dynamic>{};
    return values.map((key, value) => MapEntry(key, value as bool));
  }

  Future<Map<String, dynamic>> profile() async {
    final response = await dio.get<Map<String, dynamic>>('/profile');
    return response.data ?? const {};
  }

  Future<void> updateProfile(Map<String, dynamic> values) async {
    await dio.patch<void>('/profile', data: values);
  }

  Future<void> submitReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    await dio.post<void>(
      '/bookings/${_pathSegment(bookingId)}/review',
      data: {'rating': rating, 'comment': comment},
    );
  }

  Future<void> submitDispute({
    required String bookingId,
    required String reason,
    required String details,
  }) async {
    await dio.post<void>(
      '/bookings/${_pathSegment(bookingId)}/dispute',
      data: {'reason': reason, 'details': details},
    );
  }

  Future<CallRecord> requestCall(String bookingId) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/calls',
      data: {'bookingId': bookingId},
    );
    return CallRecord.fromJson(response.data ?? const {});
  }

  Future<CallRecord> endCall(String callId) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/calls/${_pathSegment(callId)}/end',
    );
    return CallRecord.fromJson(response.data ?? const {});
  }

  Future<void> login(String email, String password) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    await _saveSession(response.data);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await dio.post<void>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await dio.post<void>(
      '/auth/email-verification',
      data: {'email': email, 'code': code},
    );
  }

  Future<void> resendVerification(String email) async {
    await dio.post<void>(
      '/auth/email-verification/resend',
      data: {'email': email},
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await dio.post<void>('/auth/password-recovery', data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await dio.post<void>(
      '/auth/password-reset',
      data: {'token': token, 'password': password},
    );
  }

  Future<void> _saveSession(Map<String, dynamic>? data) async {
    final accessToken = data?['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException(
        'The gateway did not return an access token for this session.',
      );
    }
    await sessionStore.save(
      accessToken: accessToken,
      refreshToken: data?['refreshToken'] as String?,
    );
  }

  Future<void> logout() async {
    try {
      await dio.post<void>('/auth/logout');
    } finally {
      await sessionStore.clear();
    }
  }

  Future<Booking> createBooking({
    required String professionalId,
    required String service,
    required DateTime scheduledAt,
    required String location,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/bookings',
      data: {
        'professionalId': professionalId,
        'service': service,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'location': location,
      },
    );
    return Booking.fromJson(response.data ?? const {});
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await dio.post<void>(
      '/bookings/${_pathSegment(bookingId)}/cancel',
      data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
  }

  Future<void> rescheduleBooking(
    String bookingId, {
    required DateTime scheduledAt,
  }) async {
    await dio.post<void>(
      '/bookings/${_pathSegment(bookingId)}/reschedule',
      data: {'scheduledAt': scheduledAt.toUtc().toIso8601String()},
    );
  }

  Future<Map<String, dynamic>> startCheckout(String bookingId) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/bookings/${_pathSegment(bookingId)}/checkout',
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> paymentStatus(String bookingId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/bookings/${_pathSegment(bookingId)}/payment',
    );
    return response.data ?? const {};
  }

  Future<void> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    await dio.patch<void>('/notifications/preferences', data: preferences);
  }

  Future<void> uploadAttachment({
    required String conversationId,
    required XFile file,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    await dio.post<void>(
      '/conversations/${_pathSegment(conversationId)}/attachments',
      data: form,
    );
  }
}

