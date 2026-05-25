import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coordinate.dart';
import '../models/walk.dart';

enum WalkPeriod { today, thisWeek, allTime }

class WalksProvider extends ChangeNotifier {
  List<Walk> _walks = [];
  bool _loading = false;
  RealtimeChannel? _channel;
  String? _fetchError;

  List<Walk> get walks => _walks;
  bool get loading => _loading;
  String? get fetchError => _fetchError;

  SupabaseClient get _db => Supabase.instance.client;

  List<Walk> walksForPeriod(WalkPeriod period) {
    if (period == WalkPeriod.allTime) return List.from(_walks);
    final now = DateTime.now().toLocal();
    final DateTime cutoff;
    if (period == WalkPeriod.today) {
      cutoff = DateTime(now.year, now.month, now.day);
    } else {
      // thisWeek: Monday of current week
      final daysFromMonday = now.weekday - 1;
      final monday = now.subtract(Duration(days: daysFromMonday));
      cutoff = DateTime(monday.year, monday.month, monday.day);
    }
    return _walks
        .where((w) => w.endTime.toLocal().isAfter(cutoff))
        .toList();
  }

  List<Walk> walksForUser(String userId) =>
      _walks.where((w) => w.userId == userId).toList();

  Future<void> fetchWalks() async {
    _loading = true;
    _fetchError = null;
    notifyListeners();

    try {
      final connectivity = await Connectivity().checkConnectivity();
      final offline = connectivity.isNotEmpty &&
          connectivity.every((r) => r == ConnectivityResult.none);
      if (offline) {
        _fetchError = 'No internet connection. Check Wi-Fi or mobile data.';
        _loading = false;
        notifyListeners();
        return;
      }

      final data = await _db
          .from('walks')
          .select('*, profiles(display_name)')
          .order('end_time', ascending: false)
          .limit(500);
      _walks = (data as List).map((e) => Walk.fromJson(e)).toList();
    } catch (e) {
      _fetchError = 'Could not load walks. Pull down to refresh.';
      debugPrint('fetchWalks error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = _db
        .channel('public:walks')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'walks',
          callback: (payload) {
            try {
              final walk = Walk.fromJson(payload.newRecord);
              if (!_walks.any((w) => w.id == walk.id)) {
                _walks = [walk, ..._walks];
                notifyListeners();
              }
            } catch (_) {}
          },
        )
        .subscribe();
  }

  Future<void> saveWalk({
    required String userId,
    required List<Coordinate> path,
    required double distance,
    required int duration,
    required DateTime startTime,
    required DateTime endTime,
    String? title,
    String? prayerNotes,
    String? groupId,
  }) async {
    await _db.from('walks').insert({
      'user_id': userId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'polyline_data': path.map((c) => [c.latitude, c.longitude]).toList(),
      'distance': distance,
      'duration': duration,
      if (title != null && title.isNotEmpty) 'title': title,
      if (prayerNotes != null && prayerNotes.isNotEmpty)
        'prayer_notes': prayerNotes,
      if (groupId != null) 'group_id': groupId,
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
