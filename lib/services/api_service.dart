import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://localhost:3000/api';
  static const String baseUrl = 'https://supperclubbe-production.up.railway.app/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      await _saveToken(data['data']['token']);
      return {'success': true, 'user': data['data']['user']};
    }
    return {'success': false, 'message': data['message'] ?? 'Login failed'};
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String fullName, String phone, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone_number': phone,
        'role': role,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      await _saveToken(data['data']['token']);
      return {'success': true, 'user': data['data']['user']};
    }
    return {'success': false, 'message': data['message'] ?? 'Registration failed'};
  }

  // Enhanced GET EVENTS with filters
  Future<Map<String, dynamic>> getEvents({
    String? cuisineType,
    String? city,
    int page = 1,
    int limit = 20,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (cuisineType != null && cuisineType.isNotEmpty) {
      queryParams['cuisine_type'] = cuisineType;
    }

    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }

    final uri = Uri.parse('$baseUrl/events').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    }
    return {
      'myEvents': [],
      'myBookedEvents': [],
      'otherEvents': [],
      'total': 0,
      'page': 1,
      'pages': 1,
    };
  }

  Future<Map<String, dynamic>?> getEvent(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    }
    return null;
  }

  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: await _headers(),
      body: json.encode(eventData),
    );

    return response.statusCode == 201;
  }

  Future<bool> createBooking(int eventId, int seats) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: await _headers(),
      body: json.encode({
        'event_id': eventId,
        'number_of_seats': seats,
      }),
    );

    return response.statusCode == 201;
  }

  Future<List<dynamic>> getMyBookings(String role) async {
    final String endpoint = role.toLowerCase() == 'host'
        ? '/bookings/host/bookings'
        : '/bookings/my-bookings';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> approveBooking(int bookingId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/approve'),
      headers: await _headers(),
    );

    return response.statusCode == 200;
  }

  Future<bool> cancelBooking(int bookingId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: await _headers(),
    );

    return response.statusCode == 200;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}