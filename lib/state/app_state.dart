import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // THEME
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // CATEGORY FILTER
  String _filter = "All"; // All, Work, Personal, Urgent
  String get filter => _filter;

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  // SORTING
  String _sortBy = "dateAsc";
  // dateAsc → earliest first
  // dateDesc → latest first
  // category → A to Z

  String get sortBy => _sortBy;

  void setSort(String value) {
    _sortBy = value;
    notifyListeners();
  }
}
