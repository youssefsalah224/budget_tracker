import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../simulation/application/simulation_provider.dart';
import '../data/gam3a_repository.dart';
import '../data/gam3a_repository_impl.dart';
import '../domain/gam3a.dart';

part 'gam3as_provider.g.dart';

const _kCacheKey = 'gam3as_list_v1';

final StateProvider<bool> isGam3asStaleProvider =
    StateProvider<bool>((ref) => false);

final Provider<Gam3aRepository> gam3aRepositoryProvider =
    Provider<Gam3aRepository>((ref) => Gam3aRepositoryImpl());

@riverpod
class GamAasNotifier extends _$GamAasNotifier {
  late final Gam3aRepository _repo;

  @override
  Future<List<Gam3a>> build() async {
    _repo = ref.read(gam3aRepositoryProvider);
    ref.read(isGam3asStaleProvider.notifier).state = false;
    try {
      final list = await _repo.fetchAll();
      await _writeCache(list);
      return list;
    } catch (_) {
      final cached = await _readCache();
      if (cached != null) {
        ref.read(isGam3asStaleProvider.notifier).state = true;
        return cached;
      }
      rethrow;
    }
  }

  Future<void> add(Gam3a gam3a) async {
    state = const AsyncLoading();
    try {
      await _repo.create(gam3a);
      final fresh = await _repo.fetchAll();
      await _writeCache(fresh);
      state = AsyncData(fresh);
      ref.invalidate(simulationNotifierProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> edit(Gam3a gam3a) async {
    state = const AsyncLoading();
    try {
      await _repo.update(gam3a);
      final fresh = await _repo.fetchAll();
      await _writeCache(fresh);
      state = AsyncData(fresh);
      ref.invalidate(simulationNotifierProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      final fresh = await _repo.fetchAll();
      await _writeCache(fresh);
      state = AsyncData(fresh);
      ref.invalidate(simulationNotifierProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _writeCache(List<Gam3a> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCacheKey,
        jsonEncode(list.map((g) => _fullJson(g)).toList()),
      );
    } catch (_) {}
  }

  Future<List<Gam3a>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCacheKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Gam3a.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Full JSON including id, active, created_at — used only for cache read/write
  Map<String, dynamic> _fullJson(Gam3a g) => {
    'id': g.id,
    ...g.toJson(),
    'active': g.active,
    'created_at': g.createdAt.toIso8601String(),
  };
}
