import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _id;
  String? _name;
  String? _email;
  String? _phone;
  String? _role;

  String? get id => _id;
  String? get name => _name;
  String? get email => _email;
  String? get phone => _phone;
  String? get role => _role;

  void setUser(Map<String, dynamic> userData) {
    _id = userData['id'];
    _name = userData['name'];
    _email = userData['email'];
    _phone = userData['phone'];
    _role = userData['role'];
    notifyListeners();
  }

  void clearUser() {
    _id = null;
    _name = null;
    _email = null;
    _phone = null;
    _role = null;
    notifyListeners();
  }
}
