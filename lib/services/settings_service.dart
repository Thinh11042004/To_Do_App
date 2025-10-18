import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool notificationsEnabled;
  final TimeOfDay reminderTime;
  final bool focusMode;
  final bool calendarSync;
  final bool autoArchiveCompleted;

  const SettingsState({
    this.notificationsEnabled = false,
    this.reminderTime = const TimeOfDay(hour: 8, minute: 0),
    this.focusMode = false,
    this.calendarSync = false,
    this.autoArchiveCompleted = false,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    TimeOfDay? reminderTime,
    bool? focusMode,
    bool? calendarSync,
    bool? autoArchiveCompleted,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      focusMode: focusMode ?? this.focusMode,
      calendarSync: calendarSync ?? this.calendarSync,
      autoArchiveCompleted: autoArchiveCompleted ?? this.autoArchiveCompleted,
    );
  }
}

class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  SettingsState _state = const SettingsState();
  SharedPreferences? _prefs;

  SettingsState get state => _state;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final enabled = _prefs?.getBool(_notificationsKey) ?? _state.notificationsEnabled;
    final focus = _prefs?.getBool(_focusModeKey) ?? _state.focusMode;
    final calendar = _prefs?.getBool(_calendarSyncKey) ?? _state.calendarSync;
    final autoArchive = _prefs?.getBool(_autoArchiveKey) ?? _state.autoArchiveCompleted;
    final hour = _prefs?.getInt(_reminderHourKey);
    final minute = _prefs?.getInt(_reminderMinuteKey);

    _state = _state.copyWith(
      notificationsEnabled: enabled,
      reminderTime: hour != null && minute != null
          ? TimeOfDay(hour: hour, minute: minute)
          : _state.reminderTime,
      focusMode: focus,
      calendarSync: calendar,
      autoArchiveCompleted: autoArchive,
    );
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (value == _state.notificationsEnabled) return;
    _state = _state.copyWith(notificationsEnabled: value);
    await _prefs?.setBool(_notificationsKey, value);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    if (time == _state.reminderTime) return;
    _state = _state.copyWith(reminderTime: time);
    await _prefs?.setInt(_reminderHourKey, time.hour);
    await _prefs?.setInt(_reminderMinuteKey, time.minute);
    notifyListeners();
  }

  Future<void> setFocusMode(bool value) async {
    if (value == _state.focusMode) return;
    _state = _state.copyWith(focusMode: value);
    await _prefs?.setBool(_focusModeKey, value);
    notifyListeners();
  }

  Future<void> setCalendarSync(bool value) async {
    if (value == _state.calendarSync) return;
    _state = _state.copyWith(calendarSync: value);
    await _prefs?.setBool(_calendarSyncKey, value);
    notifyListeners();
  }

  Future<void> setAutoArchiveCompleted(bool value) async {
    if (value == _state.autoArchiveCompleted) return;
    _state = _state.copyWith(autoArchiveCompleted: value);
    await _prefs?.setBool(_autoArchiveKey, value);
    notifyListeners();
  }

  Future<void> restoreProductivityDefaults() async {
    _state = const SettingsState();
    await _prefs?.remove(_notificationsKey);
    await _prefs?.remove(_reminderHourKey);
    await _prefs?.remove(_reminderMinuteKey);
    await _prefs?.remove(_focusModeKey);
    await _prefs?.remove(_calendarSyncKey);
    await _prefs?.remove(_autoArchiveKey);
    notifyListeners();
  }

  static const String _notificationsKey = 'settings_notifications_enabled';
  static const String _reminderHourKey = 'settings_reminder_hour';
  static const String _reminderMinuteKey = 'settings_reminder_minute';
  static const String _focusModeKey = 'settings_focus_mode';
  static const String _calendarSyncKey = 'settings_calendar_sync';
  static const String _autoArchiveKey = 'settings_auto_archive';
}