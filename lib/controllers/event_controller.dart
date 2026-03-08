import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class EventController extends ChangeNotifier {
  final ApiService _api = ApiService();

  // My events (host's events or diner's booked events)
  List<Event> myEvents = [];

  // Other available events
  List<Event> otherEvents = [];

  Event? selectedEvent;
  bool isLoading = false;

  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalEvents = 0;

  // Filters
  String? selectedCuisine;
  String? selectedCity;

  // Available filter options (you can populate these from backend or hardcode)
  final List<String> cuisineTypes = [
    'Italian',
    'Mexican',
    'Japanese',
    'Chinese',
    'Indian',
    'Thai',
    'French',
    'Mediterranean',
    'American',
    'Korean',
    'Other'
  ];

  Future<void> loadEvents({
    String? cuisineFilter,
    String? cityFilter,
    int page = 1,
    bool append = false,
  }) async {
    if (!append) {
      isLoading = true;
    }
    notifyListeners();

    try {
      final data = await _api.getEvents(
        cuisineType: cuisineFilter ?? selectedCuisine,
        city: cityFilter ?? selectedCity,
        page: page,
        limit: 20,
      );

      currentPage = data['page'] ?? 1;
      totalPages = data['pages'] ?? 1;
      totalEvents = data['total'] ?? 0;

      // Handle myEvents (for hosts) or myBookedEvents (for diners)
      final myEventsData = data['myEvents'] ?? data['myBookedEvents'] ?? [];
      if (append) {
        // For "my events", we typically don't paginate, so replace
        myEvents = myEventsData.map<Event>((e) => Event.fromJson(e)).toList();
      } else {
        myEvents = myEventsData.map<Event>((e) => Event.fromJson(e)).toList();
      }

      // Handle otherEvents
      final otherEventsData = data['otherEvents'] ?? [];
      if (append) {
        otherEvents.addAll(
          otherEventsData.map<Event>((e) => Event.fromJson(e)).toList(),
        );
      } else {
        otherEvents = otherEventsData.map<Event>((e) => Event.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error loading events: $e');
      if (!append) {
        myEvents = [];
        otherEvents = [];
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreEvents() async {
    if (currentPage < totalPages && !isLoading) {
      await loadEvents(page: currentPage + 1, append: true);
    }
  }

  void applyFilters({String? cuisine, String? city}) {
    selectedCuisine = cuisine;
    selectedCity = city;
    loadEvents(cuisineFilter: cuisine, cityFilter: city);
  }

  void clearFilters() {
    selectedCuisine = null;
    selectedCity = null;
    loadEvents();
  }

  Future<void> loadEventDetail(int id) async {
    isLoading = true;
    notifyListeners();

    final data = await _api.getEvent(id);
    if (data != null) {
      selectedEvent = Event.fromJson(data);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    isLoading = true;
    notifyListeners();

    final success = await _api.createEvent(eventData);

    isLoading = false;
    notifyListeners();

    if (success) {
      await loadEvents();
    }
    return success;
  }

  // Helper methods
  List<Event> get upcomingMyEvents =>
      myEvents.where((e) => !e.isPastEvent).toList();

  List<Event> get pastMyEvents =>
      myEvents.where((e) => e.isPastEvent).toList();

  List<Event> get upcomingOtherEvents =>
      otherEvents.where((e) => !e.isPastEvent).toList();

  List<Event> get pastOtherEvents =>
      otherEvents.where((e) => e.isPastEvent).toList();
}