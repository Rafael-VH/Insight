import 'package:shared_preferences/shared_preferences.dart';

const _keyIndex = 'heroes_index_cache';
const _keyDetails = 'heroes_details_cache';
const _keyList = 'heroes_list_cache';
const _keyBuilds = 'heroes_builds_cache';
const _keyEquipment = 'heroes_equipment_cache';
const _keyTimestamp = 'heroes_cache_timestamp';
const _keyBuildsTimestamp = 'heroes_builds_timestamp';
const _keyEquipmentTimestamp = 'heroes_equipment_timestamp';
const _ttlHours = 24;

abstract class HeroCacheDataSource {
  Future<String?> getCachedIndex();
  Future<String?> getCachedDetails();
  Future<String?> getCachedList();
  Future<String?> getCachedBuilds();
  Future<String?> getCachedEquipment();
  Future<void> saveEagerCache({
    required String indexJson,
    required String detailsJson,
    required String listJson,
  });
  Future<void> saveBuildsCache(String buildsJson);
  Future<void> saveEquipmentCache(String equipmentJson);
  bool isCacheValid();
  bool isBuildsValid();
  bool isEquipmentValid();
  Future<void> clearCache();
}

class HeroCacheDataSourceImpl implements HeroCacheDataSource {
  final SharedPreferences prefs;

  HeroCacheDataSourceImpl({required this.prefs});

  bool _isValid(String tsKey) {
    final ts = prefs.getInt(tsKey);
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts <
        const Duration(hours: _ttlHours).inMilliseconds;
  }

  @override
  bool isCacheValid() => _isValid(_keyTimestamp);

  @override
  bool isBuildsValid() => _isValid(_keyBuildsTimestamp);

  @override
  bool isEquipmentValid() => _isValid(_keyEquipmentTimestamp);

  @override
  Future<String?> getCachedIndex() async => prefs.getString(_keyIndex);

  @override
  Future<String?> getCachedDetails() async => prefs.getString(_keyDetails);

  @override
  Future<String?> getCachedList() async => prefs.getString(_keyList);

  @override
  Future<String?> getCachedBuilds() async => prefs.getString(_keyBuilds);

  @override
  Future<String?> getCachedEquipment() async => prefs.getString(_keyEquipment);

  @override
  Future<void> saveEagerCache({
    required String indexJson,
    required String detailsJson,
    required String listJson,
  }) async {
    await prefs.setString(_keyIndex, indexJson);
    await prefs.setString(_keyDetails, detailsJson);
    await prefs.setString(_keyList, listJson);
    await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> saveBuildsCache(String buildsJson) async {
    await prefs.setString(_keyBuilds, buildsJson);
    await prefs.setInt(_keyBuildsTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> saveEquipmentCache(String equipmentJson) async {
    await prefs.setString(_keyEquipment, equipmentJson);
    await prefs.setInt(_keyEquipmentTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> clearCache() async {
    for (final key in [
      _keyIndex,
      _keyDetails,
      _keyList,
      _keyBuilds,
      _keyEquipment,
      _keyTimestamp,
      _keyBuildsTimestamp,
      _keyEquipmentTimestamp,
    ]) {
      await prefs.remove(key);
    }
  }
}
