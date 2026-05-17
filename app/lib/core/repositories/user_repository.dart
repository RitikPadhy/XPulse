import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/user_snapshot.dart';

class UserRepository {
  static const _samplePath = 'assets/data/sample_user.json';

  Future<UserSnapshot> loadCurrent() async {
    final raw = await rootBundle.loadString(_samplePath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return UserSnapshot.fromJson(json);
  }
}
