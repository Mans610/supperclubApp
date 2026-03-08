import 'package:intl/intl.dart';

class Booking {
  final int id;
  final int eventId;
  final int numberOfSeats;
  final double seatPrice;
  final double platformFee;
  final double totalAmount;
  final String status;
  final String? specialNotes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Event details
  final String? eventTitle;
  final String? eventDescription;
  final String? cuisineType;
  final String? menuDescription;
  final String? eventDate;
  final String? eventTime;
  final String? location;
  final String? exactAddress;
  final String? houseRules;

  // Host details
  final String? hostName;
  final String? hostPhone;

  Booking({
    required this.id,
    required this.eventId,
    required this.numberOfSeats,
    required this.seatPrice,
    required this.platformFee,
    required this.totalAmount,
    required this.status,
    this.specialNotes,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.eventTitle,
    this.eventDescription,
    this.cuisineType,
    this.menuDescription,
    this.eventDate,
    this.eventTime,
    this.location,
    this.exactAddress,
    this.houseRules,
    this.hostName,
    this.hostPhone,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as Map<String, dynamic>?;
    final host = event?['host'] as Map<String, dynamic>?;
    return Booking(
      id: json['id'] ?? 0,
      eventId: json['event_id'] ?? 0,
      numberOfSeats: json['number_of_seats'] ?? 0,
      seatPrice: _parseDouble(json['seat_price']),
      platformFee: _parseDouble(json['platform_fee']),
      totalAmount: _parseDouble(json['total_amount']),
      status: json['status'] ?? 'pending',
      specialNotes: json['special_notes'],
      rejectionReason: json['rejection_reason'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      eventTitle: event?['title'],
      eventDescription: event?['description'],
      cuisineType: event?['cuisine_type'],
      menuDescription: event?['menu_description'],
      eventDate: event?['event_date'],
      eventTime: event?['event_time'],
      location: event?['approximate_location'],
      exactAddress: event?['exact_address'],
      houseRules: event?['house_rules'],
      hostName: host?['full_name'],
      hostPhone: host?['phone_number'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get isPending => status == 'pending';

  bool get isApproved => status == 'approved';

  bool get isCancelled => status == 'cancelled' || status == 'rejected';
  
  String get formattedDate {
    if (eventDate == null) return 'Date TBD';
    try {
      final date = DateTime.parse(eventDate!);
      return DateFormat('EEEE, MMM dd, yyyy').format(date);
    } catch (_) {
      return eventDate!;
    }
  }

  String get formattedTime {
    if (eventTime == null) return '';
    try {
      final parts = eventTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final time = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(time);
    } catch (_) {
      return eventTime!;
    }
  }
}
