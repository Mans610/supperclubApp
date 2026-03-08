class Event {
  final int id;
  final String title;
  final String description;
  final String cuisineType;
  final String menuDescription;
  final double pricePerSeat;
  final int totalSeats;
  final int availableSeats;
  final String eventDate;
  final String eventTime;
  final String location;
  final String? exactAddress;
  final String? houseRules;
  final String status;
  final bool isActive;

  // Host information
  final int? hostId;
  final String? hostName;
  final String? hostPhoto;
  final String? hostCity;
  final HostProfile? hostProfile;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.cuisineType,
    required this.menuDescription,
    required this.pricePerSeat,
    required this.totalSeats,
    required this.availableSeats,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    this.exactAddress,
    this.houseRules,
    required this.status,
    required this.isActive,
    this.hostId,
    this.hostName,
    this.hostPhoto,
    this.hostCity,
    this.hostProfile,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Handle host information
    final host = json['host'];

    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      cuisineType: json['cuisine_type'] ?? '',
      menuDescription: json['menu_description'] ?? '',
      pricePerSeat: _parseDouble(json['price_per_seat']),
      totalSeats: json['total_seats'] ?? 0,
      availableSeats: json['seats_available'] ?? 0,
      eventDate: json['event_date'] ?? '',
      eventTime: json['event_time'] ?? '',
      location: json['approximate_location'] ?? '',
      exactAddress: json['exact_address'],
      houseRules: json['house_rules'],
      status: json['status'] ?? 'open',
      isActive: json['is_active'] ?? true,
      hostId: host != null ? host['id'] : json['host_id'],
      hostName: host != null ? host['full_name'] : null,
      hostPhoto: host != null ? host['profile_photo'] : null,
      hostCity: host != null ? host['city'] : null,
      hostProfile: host != null && host['hostProfile'] != null
          ? HostProfile.fromJson(host['hostProfile'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get isAvailable => availableSeats > 0 && status == 'open';

  bool get isPastEvent {
    try {
      final eventDateTime = DateTime.parse(eventDate);
      return eventDateTime.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  bool get isToday {
    try {
      final eventDateTime = DateTime.parse(eventDate);
      final now = DateTime.now();
      return eventDateTime.year == now.year &&
          eventDateTime.month == now.month &&
          eventDateTime.day == now.day;
    } catch (e) {
      return false;
    }
  }
}

class HostProfile {
  final String? bio;
  final String? specialties;
  final double? rating;
  final int? totalEvents;

  HostProfile({
    this.bio,
    this.specialties,
    this.rating,
    this.totalEvents,
  });

  factory HostProfile.fromJson(Map<String, dynamic> json) {
    return HostProfile(
      bio: json['bio'],
      specialties: json['specialties'],
      rating: json['rating']?.toDouble(),
      totalEvents: json['total_events'],
    );
  }
}