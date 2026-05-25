import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileProvider extends ChangeNotifier {
  Profile? _profile;
  bool _loading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;
  String get displayName => _profile?.nameOrFallback ?? 'Prayer Walker';
  String? get groupId => _profile?.groupId;
  bool get hasGroup => _profile?.groupId != null;

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> fetchProfile(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        _profile = Profile.fromJson(data);
      } else {
        // Bootstrap empty profile row for new users
        await _db.from('profiles').upsert({'id': userId});
        _profile = Profile(id: userId, createdAt: DateTime.now());
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('ProfileProvider.fetchProfile: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDisplayName(String userId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    try {
      await _db.from('profiles').upsert({
        'id': userId,
        'display_name': trimmed,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _profile =
          (_profile ?? Profile(id: userId, createdAt: DateTime.now()))
              .copyWith(displayName: trimmed);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateDisplayName: $e');
      return false;
    }
  }

  Future<bool> updateGroupId(String userId, String? newGroupId) async {
    try {
      await _db.from('profiles').upsert({
        'id': userId,
        'group_id': newGroupId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _profile =
          (_profile ?? Profile(id: userId, createdAt: DateTime.now()))
              .copyWith(groupId: newGroupId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateGroupId: $e');
      return false;
    }
  }

  void clear() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
