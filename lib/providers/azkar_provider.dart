import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/zikr_model.dart';

class AzkarProvider with ChangeNotifier {
  List<AzkarCategory> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  Set<String> _favoriteCategoryIds = {};
  
  int _totalAzkarRead = 0;
  User? _currentUser;

  List<AzkarCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get totalAzkarRead => _totalAzkarRead;
  Set<String> get favoriteCategoryIds => _favoriteCategoryIds;

  AzkarProvider() {
    _loadAzkarData();
    _loadLocalGuestStatistics();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final bool wasGuest = _currentUser == null && user != null;
      final bool wasUser = _currentUser != null && user == null;
      _currentUser = user;

      if (user != null) {
        _syncWithFirestore(wasGuest);
      } else if (wasUser) {
        // Logged out: Restore local guest statistics
        _loadLocalGuestStatistics();
      }
    });
  }

  Future<void> _loadLocalGuestStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    // Start with guest total if available, otherwise fallback to old totalAzkarRead, or 0
    _totalAzkarRead = prefs.getInt('guestTotalAzkarRead') ?? prefs.getInt('totalAzkarRead') ?? 0;
    
    final favList = prefs.getStringList('favoriteCategoryIds') ?? [];
    _favoriteCategoryIds = favList.toSet();
    
    notifyListeners();
  }

  Future<void> _syncWithFirestore(bool wasGuest) async {
    if (_currentUser == null) return;
    
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final snapshot = await docRef.get();
      
      int cloudTotal = 0;
      if (snapshot.exists) {
        cloudTotal = snapshot.data()?['totalAzkarRead'] ?? 0;
      }

      final prefs = await SharedPreferences.getInstance();
      int guestTotal = prefs.getInt('guestTotalAzkarRead') ?? prefs.getInt('totalAzkarRead') ?? 0;
      
      // Merge guest progress into cloud progress if they just logged in
      if (wasGuest && guestTotal > 0) {
        _totalAzkarRead = cloudTotal + guestTotal;
        await docRef.set({'totalAzkarRead': _totalAzkarRead}, SetOptions(merge: true));
        // Reset guest total so it's not merged again next time
        await prefs.setInt('guestTotalAzkarRead', 0);
        await prefs.setInt('totalAzkarRead', 0);
      } else {
        _totalAzkarRead = cloudTotal;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error syncing with Firestore: $e");
    }
  }

  Future<void> incrementTotalAzkarRead() async {
    _totalAzkarRead++;
    notifyListeners();
    
    if (_currentUser != null) {
      // Save to Firestore
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
        await docRef.set({'totalAzkarRead': FieldValue.increment(1)}, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating Firestore: $e");
      }
    } else {
      // Save locally as guest
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('guestTotalAzkarRead', _totalAzkarRead);
      await prefs.setInt('totalAzkarRead', _totalAzkarRead); // Keep old key updated for fallback
    }
  }

  Future<void> _loadAzkarData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/azkar.json');
      final List<dynamic> data = json.decode(response);
      _categories = data.map((json) => AzkarCategory.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error loading Azkar data: $e");
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteCategory(String id) async {
    if (_favoriteCategoryIds.contains(id)) {
      _favoriteCategoryIds.remove(id);
    } else {
      _favoriteCategoryIds.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteCategoryIds', _favoriteCategoryIds.toList());
  }

  bool isFavoriteCategory(String id) => _favoriteCategoryIds.contains(id);

  List<AzkarCategory> getFavoriteCategories() {
    return _categories.where((cat) => _favoriteCategoryIds.contains(cat.id)).toList();
  }
}
