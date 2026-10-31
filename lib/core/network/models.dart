class Professional {
  const Professional({
    required this.id,
    required this.name,
    required this.title,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.avatarUrl,
    required this.latitude,
    required this.longitude,
    this.bio = '',
    this.startingPrice = 0,
  });

  factory Professional.fromJson(Map<String, dynamic> json) => Professional(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Professional',
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    location: json['location'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    bio: json['bio'] as String? ?? '',
    startingPrice: (json['startingPrice'] as num?)?.toDouble() ?? 0,
  );

  final String id;
  final String name;
  final String title;
  final String category;
  final double rating;
  final int reviewCount;
  final String location;
  final String avatarUrl;
  final double latitude;
  final double longitude;
  final String bio;
  final double startingPrice;
}

class Booking {
  const Booking({
    required this.id,
    required this.service,
    required this.professionalName,
    required this.professionalAvatarUrl,
    required this.status,
    required this.date,
    required this.time,
    required this.location,
    required this.amount,
    this.canCancel = false,
    this.canReschedule = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as String? ?? '',
    service: json['service'] as String? ?? '',
    professionalName: json['professionalName'] as String? ?? '',
    professionalAvatarUrl: json['professionalAvatarUrl'] as String? ?? '',
    status: json['status'] as String? ?? 'upcoming',
    date: json['date'] as String? ?? '',
    time: json['time'] as String? ?? '',
    location: json['location'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    canCancel: json['canCancel'] as bool? ?? false,
    canReschedule: json['canReschedule'] as bool? ?? false,
  );

  final String id;
  final String service;
  final String professionalName;
  final String professionalAvatarUrl;
  final String status;
  final String date;
  final String time;
  final String location;
  final double amount;
  final bool canCancel;
  final bool canReschedule;
}

class BookingTracking {
  const BookingTracking({
    required this.bookingId,
    required this.status,
    required this.jobStage,
    required this.professionalName,
    required this.professionalAvatarUrl,
    required this.professionalLatitude,
    required this.professionalLongitude,
    required this.customerLatitude,
    required this.customerLongitude,
    this.etaMinutes,
    this.distanceMeters,
    this.routeCoordinates = const [],
  });

  factory BookingTracking.fromJson(Map<String, dynamic> json) =>
      BookingTracking(
        bookingId: json['bookingId'] as String? ?? '',
        status: json['status'] as String? ?? '',
        jobStage: json['jobStage'] as String? ?? 'confirmed',
        professionalName: json['professionalName'] as String? ?? '',
        professionalAvatarUrl: json['professionalAvatarUrl'] as String? ?? '',
        professionalLatitude:
            (json['professionalLatitude'] as num?)?.toDouble() ?? 0,
        professionalLongitude:
            (json['professionalLongitude'] as num?)?.toDouble() ?? 0,
        customerLatitude: (json['customerLatitude'] as num?)?.toDouble() ?? 0,
        customerLongitude: (json['customerLongitude'] as num?)?.toDouble() ?? 0,
        etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
        distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
        routeCoordinates:
            (json['routeCoordinates'] as List<dynamic>?)
                ?.whereType<List<dynamic>>()
                .where((pair) => pair.length >= 2)
                .map(
                  (pair) => [
                    (pair[0] as num).toDouble(),
                    (pair[1] as num).toDouble(),
                  ],
                )
                .toList() ??
            const [],
      );

  final String bookingId;
  final String status;
  final String jobStage;
  final String professionalName;
  final String professionalAvatarUrl;
  final double professionalLatitude;
  final double professionalLongitude;
  final double customerLatitude;
  final double customerLongitude;
  final int? etaMinutes;
  final double? distanceMeters;
  final List<List<double>> routeCoordinates;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.professionalName,
    required this.professionalAvatarUrl,
    required this.service,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.online,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String? ?? '',
    professionalName: json['professionalName'] as String? ?? '',
    professionalAvatarUrl: json['professionalAvatarUrl'] as String? ?? '',
    service: json['service'] as String? ?? '',
    lastMessage: json['lastMessage'] as String? ?? '',
    lastMessageAt: json['lastMessageAt'] as String? ?? '',
    unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    online: json['online'] as bool? ?? false,
  );

  final String id;
  final String professionalName;
  final String professionalAvatarUrl;
  final String service;
  final String lastMessage;
  final String lastMessageAt;
  final int unreadCount;
  final bool online;
}

class Message {
  const Message({
    required this.id,
    required this.body,
    required this.sentAt,
    required this.sender,
    required this.read,
    this.delivered = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String? ?? '',
    body: json['body'] as String? ?? '',
    sentAt: json['sentAt'] as String? ?? '',
    sender: json['sender'] as String? ?? 'professional',
    read: json['read'] as bool? ?? false,
    delivered: json['delivered'] as bool? ?? false,
  );

  final String id;
  final String body;
  final String sentAt;
  final String sender;
  final bool read;
  final bool delivered;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        read: json['read'] as bool? ?? false,
      );

  final String id;
  final String title;
  final String body;
  final String createdAt;
  final bool read;
}

class CallRecord {
  const CallRecord({required this.id, required this.status});

  factory CallRecord.fromJson(Map<String, dynamic> json) => CallRecord(
    id: json['id'] as String? ?? '',
    status: json['status'] as String? ?? '',
  );

  final String id;
  final String status;
}

