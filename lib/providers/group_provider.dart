import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/profile.dart';

class GroupProvider extends ChangeNotifier {
  Group? _group;
  List<Profile> _members = [];
  bool _loading = false;
  String? _error;

  Group? get group => _group;
  List<Profile> get members => _members;
  bool get loading => _loading;
  String? get error => _error;

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> fetchGroup(String groupId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data =
          await _db.from('groups').select().eq('id', groupId).single();
      _group = Group.fromJson(data);
      await fetchMembers(groupId);
    } catch (e) {
      _error = 'Could not load group.';
      debugPrint('GroupProvider.fetchGroup: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMembers(String groupId) async {
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('group_id', groupId);
      _members = (data as List).map((e) => Profile.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('GroupProvider.fetchMembers: $e');
    }
  }

  /// Finds and joins a group by its invite code. Returns the group on success.
  Future<Group?> joinByInviteCode(String code) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _db
          .from('groups')
          .select()
          .eq('invite_code', code.trim().toUpperCase())
          .maybeSingle();
      if (data == null) {
        _error = 'Invalid invite code. Check the code and try again.';
        notifyListeners();
        return null;
      }
      _group = Group.fromJson(data);
      await fetchMembers(_group!.id);
      notifyListeners();
      return _group;
    } catch (e) {
      _error = 'Could not join group. Please try again.';
      debugPrint('joinByInviteCode: $e');
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Group?> createGroup({
    required String name,
    required String description,
    required String createdBy,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final code = _generateInviteCode();
      final data = await _db.from('groups').insert({
        'name': name.trim(),
        'description': description.trim(),
        'invite_code': code,
        'created_by': createdBy,
      }).select().single();
      _group = Group.fromJson(data);
      _members = [];
      notifyListeners();
      return _group;
    } catch (e) {
      _error = 'Could not create group. Please try again.';
      debugPrint('createGroup: $e');
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _group = null;
    _members = [];
    _error = null;
    notifyListeners();
  }

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
