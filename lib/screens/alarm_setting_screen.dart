import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/alarm_item.dart';
import 'placeholder_screen.dart';

enum RepeatOption { once, repeat, custom }

class AlarmSettingScreen extends StatefulWidget {
  final AlarmItem? existingAlarm;

  const AlarmSettingScreen({super.key, this.existingAlarm});

  @override
  State<AlarmSettingScreen> createState() => _AlarmSettingScreenState();
}

class _AlarmSettingScreenState extends State<AlarmSettingScreen> {
  late bool _isAM;
  late int _hour; // 1-12
  late int _minute; // 0-59
  late RepeatOption _selectedRepeatOption;
  late Set<String> _selectedDays;
  final String _soundName = 'Nature';
  late bool _vibration;

  late TextEditingController _noteController;

  static const List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlarm;
    if (existing != null) {
      _isAM = existing.time.period == DayPeriod.am;
      _hour = existing.time.hourOfPeriod == 0 ? 12 : existing.time.hourOfPeriod;
      _minute = existing.time.minute;
      _selectedDays = Set.from(existing.days);

      if (_selectedDays.isEmpty) {
        _selectedRepeatOption = RepeatOption.once;
      } else if (_selectedDays.length == 7) {
        _selectedRepeatOption = RepeatOption.repeat;
      } else {
        _selectedRepeatOption = RepeatOption.custom;
      }

      _vibration = existing.vibration;
      _noteController = TextEditingController(text: existing.label);
    } else {
      _isAM = true;
      _hour = 12;
      _minute = 0;
      _selectedRepeatOption = RepeatOption.once;
      _selectedDays = {};
      _vibration = true;
      _noteController = TextEditingController(text: '');
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  TimeOfDay get _selectedTime {
    final hour24 = _isAM
        ? (_hour == 12 ? 0 : _hour)
        : (_hour == 12 ? 12 : _hour + 12);
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  void _saveAlarm() {
    Set<String> finalDays;
    switch (_selectedRepeatOption) {
      case RepeatOption.once:
        finalDays = {};
        break;
      case RepeatOption.repeat:
        finalDays = Set.from(_allDays);
        break;
      case RepeatOption.custom:
        finalDays = Set.from(_selectedDays);
        break;
    }

    final alarm = AlarmItem(
      id: widget.existingAlarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: _noteController.text.trim().isEmpty ? 'Alarm' : _noteController.text.trim(),
      time: _selectedTime,
      days: finalDays,
      soundName: _soundName,
      vibration: _vibration,
      enabled: widget.existingAlarm?.enabled ?? true,
    );
    Navigator.pop(context, alarm);
  }

  void _incrementHour() {
    setState(() {
      _hour = (_hour % 12) + 1;
    });
  }

  void _decrementHour() {
    setState(() {
      _hour = _hour == 1 ? 12 : _hour - 1;
    });
  }

  void _incrementMinute() {
    setState(() {
      _minute = (_minute + 1) % 60;
    });
  }

  void _decrementMinute() {
    setState(() {
      _minute = (_minute - 1 + 60) % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _SettingHeader(
              child: _ArrowTimePickerCard(
                isAM: _isAM,
                hour: _hour,
                minute: _minute,
                onPeriodChanged: (isAM) => setState(() => _isAM = isAM),
                onIncrementHour: _incrementHour,
                onDecrementHour: _decrementHour,
                onIncrementMinute: _incrementMinute,
                onDecrementMinute: _decrementMinute,
                onHourSubmitted: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= 1 && parsed <= 12) {
                    setState(() => _hour = parsed);
                  }
                },
                onMinuteSubmitted: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= 0 && parsed <= 59) {
                    setState(() => _minute = parsed);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.edit_note, color: Color(0xFFE8231F)),
                        border: InputBorder.none,
                        hintText: 'Enter alarm label or note...',
                        labelText: 'Alarm Label / Note',
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _RepeatTypeChip(
                        label: 'Once',
                        selected: _selectedRepeatOption == RepeatOption.once,
                        onTap: () {
                          setState(() {
                            _selectedRepeatOption = RepeatOption.once;
                            _selectedDays.clear();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _RepeatTypeChip(
                        label: 'Repeat',
                        selected: _selectedRepeatOption == RepeatOption.repeat,
                        onTap: () {
                          setState(() {
                            _selectedRepeatOption = RepeatOption.repeat;
                            _selectedDays = Set.from(_allDays);
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _RepeatTypeChip(
                        label: 'Custom',
                        selected: _selectedRepeatOption == RepeatOption.custom,
                        onTap: () {
                          setState(() {
                            _selectedRepeatOption = RepeatOption.custom;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_selectedRepeatOption == RepeatOption.custom) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDays.map((day) {
                        final selected = _selectedDays.contains(day);
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedDays.remove(day);
                              } else {
                                _selectedDays.add(day);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFE8231F)
                                  : Colors.white,
                              border: Border.all(color: const Color(0xFFE8231F)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              day,
                              style: TextStyle(
                                color: selected ? Colors.white : const Color(0xFFE8231F),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SettingsRow(
                    icon: Icons.notifications_none,
                    title: 'Alarm Sound',
                    subtitle: _soundName,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PlaceholderScreen(title: 'Alarm Sound'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _SettingsRow(
                    icon: Icons.vibration,
                    title: 'Vibration',
                    subtitle: _vibration ? 'On' : 'Off',
                    subtitleColor: _vibration ? const Color(0xFF4CAF50) : Colors.grey,
                    trailing: Switch(
                      value: _vibration,
                      activeThumbColor: const Color(0xFF4CAF50),
                      onChanged: (v) => setState(() => _vibration = v),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Center(
                    child: Column(
                      children: [
                        InkWell(
                          onTap: _saveAlarm,
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8231F),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.existingAlarm == null ? Icons.add : Icons.check,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.existingAlarm == null ? 'Save Alarm' : 'Update Alarm',
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingHeader extends StatelessWidget {
  final Widget child;

  const _SettingHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipPath(
          clipper: _SettingWaveClipper(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            color: const Color(0xFFF4711E),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _SettingWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 20,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _ArrowTimePickerCard extends StatelessWidget {
  final bool isAM;
  final int hour;
  final int minute;
  final ValueChanged<bool> onPeriodChanged;
  final VoidCallback onIncrementHour;
  final VoidCallback onDecrementHour;
  final VoidCallback onIncrementMinute;
  final VoidCallback onDecrementMinute;
  final ValueChanged<String> onHourSubmitted;
  final ValueChanged<String> onMinuteSubmitted;

  const _ArrowTimePickerCard({
    required this.isAM,
    required this.hour,
    required this.minute,
    required this.onPeriodChanged,
    required this.onIncrementHour,
    required this.onDecrementHour,
    required this.onIncrementMinute,
    required this.onDecrementMinute,
    required this.onHourSubmitted,
    required this.onMinuteSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PeriodPill(label: 'A.M.', selected: isAM, onTap: () => onPeriodChanged(true)),
              const SizedBox(width: 8),
              _PeriodPill(label: 'P.M.', selected: !isAM, onTap: () => onPeriodChanged(false)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ArrowButton(
                    icon: Icons.keyboard_arrow_up,
                    onTap: onIncrementHour,
                  ),
                  const SizedBox(height: 4),
                  _EditableNumberDisplay(
                    value: hour.toString().padLeft(2, '0'),
                    maxValue: 12,
                    onSubmitted: onHourSubmitted,
                  ),
                  const SizedBox(height: 4),
                  _ArrowButton(
                    icon: Icons.keyboard_arrow_down,
                    onTap: onDecrementHour,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ArrowButton(
                    icon: Icons.keyboard_arrow_up,
                    onTap: onIncrementMinute,
                  ),
                  const SizedBox(height: 4),
                  _EditableNumberDisplay(
                    value: minute.toString().padLeft(2, '0'),
                    maxValue: 59,
                    onSubmitted: onMinuteSubmitted,
                  ),
                  const SizedBox(height: 4),
                  _ArrowButton(
                    icon: Icons.keyboard_arrow_down,
                    onTap: onDecrementMinute,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableNumberDisplay extends StatefulWidget {
  final String value;
  final int maxValue;
  final ValueChanged<String> onSubmitted;

  const _EditableNumberDisplay({
    required this.value,
    required this.maxValue,
    required this.onSubmitted,
  });

  @override
  State<_EditableNumberDisplay> createState() => _EditableNumberDisplayState();
}

class _EditableNumberDisplayState extends State<_EditableNumberDisplay> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _submit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _EditableNumberDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _isEditing = false);
    widget.onSubmitted(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 60,
        height: 45,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8231F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8231F), width: 2),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _isEditing = true;
          _controller.text = widget.value;
        });
        _focusNode.requestFocus();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: Text(
          widget.value,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 32,
            color: const Color(0xFFE8231F),
          ),
        ),
      ),
    );
  }
}

class _RepeatTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RepeatTypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8231F) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFE8231F) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8231F) : const Color(0xFFFFDCCF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFE8231F),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD9CC),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFE8231F), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor ?? const Color(0xFFE8231F),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8231F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}