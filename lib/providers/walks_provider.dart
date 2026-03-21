import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/walk.dart';
import '../models/coordinate.dart';

class WalksProvider extends ChangeNotifier {
  List<Walk> _walks = [];
  bool _loading = false;
  RealtimeChannel? _channel;

  List<Walk> get walks => _walks;
  bool get loading => _loading;

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> fetchWalks() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _db
          .from('walks')
          .select()
          .order('created_at', ascending: false)
          .limit(500);
      _walks = (data as List).map((e) => Walk.fromJson(e)).toList();
    } catch (e) {
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
  }) async {
    await _db.from('walks').insert({
      'user_id': userId,
      'path': path.map((c) => c.toJson()).toList(),
      'distance': distance,
      'duration': duration,
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
