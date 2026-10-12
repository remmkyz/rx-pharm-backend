import 'package:flutter/material.dart';

/// Represents one medication reminder/alarm.
class AlarmItem {
  final String id;
  String label;
  TimeOfDay time;
  Set<String> days;
  bool enabled;
  String soundName;
  bool vibration;

  AlarmItem({
    required this.id,
    required this.label,
    required this.time,
    required this.days,
    this.enabled = true,
    this.soundName = 'Nature',
    this.vibration = true,
  });

  /// True for AM times — used to decide between the sun/moon icon.
  bool get isMorning => time.period == DayPeriod.am;

  /// e.g. "Mon, Wed, Fri" or "Monday" if only one day is picked.
  String get daysLabel {
    if (days.isEmpty) return 'One time';
    const order = ['Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat', 'Sun'];
    final sorted = order.where((d) => days.contains(d)).toList();
    if (sorted.length == 7) return 'Every day';
    return sorted.join(', ');
  }

  String get timeLabel {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get periodLabel => isMorning ? 'A.M' : 'P.M';
}
