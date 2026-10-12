import '../models/alarm_item.dart';

class AlarmService {
  // Singleton instance
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final List<AlarmItem> _alarms = [];

  List<AlarmItem> get alarms => List.unmodifiable(_alarms);

  void addAlarm(AlarmItem alarm) {
    _alarms.add(alarm);
  }

  void updateAlarm(AlarmItem updated) {
    final index = _alarms.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _alarms[index] = updated;
    }
  }

  void deleteAlarm(String id) {
    _alarms.removeWhere((a) => a.id == id);
  }

  void deleteMultipleAlarms(Set<String> ids) {
    _alarms.removeWhere((a) => ids.contains(a.id));
  }
}