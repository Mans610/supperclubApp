import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthController extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? currentUser;
  bool isLoading = false;

  // Load user data from storage on app start
  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      currentUser = User.fromJson(json.decode(userData));
      notifyListeners();
    }
  }

  // Save user data to storage
  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode({
      'id': user.id,
      'email': user.email,
      'full_name': user.fullName,
      'phone_number': user.phoneNumber,
      'role': user.role,
    }));
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    final result = await _api.login(email, password);

    isLoading = false;
    if (result['success']) {
      currentUser = User.fromJson(result['user']);
      await _saveUserToStorage(currentUser!);  // Save user data
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> register(String email, String password, String fullName, String phone, String role) async {
    isLoading = true;
    notifyListeners();

    final result = await _api.register(email, password, fullName, phone, role);

    isLoading = false;
    if (result['success']) {
      currentUser = User.fromJson(result['user']);
      await _saveUserToStorage(currentUser!);  // Save user data
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _api.logout();

    // Clear user data from storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');

    currentUser = null;
    notifyListeners();
  }
}