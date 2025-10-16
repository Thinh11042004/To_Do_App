import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class CategoryConfig {
  CategoryConfig({
    required this.id,
    required this.label,
    required this.color,
    this.isSystem = false,
    this.visible = true,
  });

  final String id;
  String label;
  int color;
  bool isSystem;
  bool visible;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'color': color,
        'isSystem': isSystem,
        'visible': visible,
      };

  factory CategoryConfig.fromJson(Map<String, dynamic> json) {
    return CategoryConfig(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Danh mục',
      color: json['color'] as int? ?? Colors.indigo.value,
      isSystem: json['isSystem'] as bool? ?? false,
      visible: json['visible'] as bool? ?? true,
    );
  }
}

class CategoryStore {
  CategoryStore._();

  static final CategoryStore instance = CategoryStore._();

  static const _prefsKey = 'category-configs-v1';

  final ValueNotifier<List<CategoryConfig>> _categories = ValueNotifier<List<CategoryConfig>>([]);

  ValueListenable<List<CategoryConfig>> get listenable => _categories;
  List<CategoryConfig> get current => List.unmodifiable(_categories.value);

  Future<void> ensureLoaded() async {
    if (_categories.value.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    List<CategoryConfig> configs;
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (json.decode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        configs = list.map(CategoryConfig.fromJson).toList();
      } catch (_) {
        configs = _defaultConfigs();
      }
    } else {
      configs = _defaultConfigs();
    }
    configs = _mergeWithDefaults(configs);
    _categories.value = List.unmodifiable(configs);
  }

  List<CategoryConfig> _defaultConfigs() {
    return [
      CategoryConfig(
        id: _systemId(TaskCategory.work),
        label: 'Công việc',
        color: Colors.blue.value,
        isSystem: true,
      ),
      CategoryConfig(
        id: _systemId(TaskCategory.personal),
        label: 'Cá nhân',
        color: Colors.pinkAccent.value,
        isSystem: true,
      ),
      CategoryConfig(
        id: _systemId(TaskCategory.favorites),
        label: 'Yêu thích',
        color: Colors.amber.value,
        isSystem: true,
      ),
      CategoryConfig(
        id: _systemId(TaskCategory.birthday),
        label: 'Sinh nhật',
        color: Colors.purple.value,
        isSystem: true,
      ),
    ];
  }

  List<CategoryConfig> _mergeWithDefaults(List<CategoryConfig> stored) {
    final defaults = _defaultConfigs();
    final all = <CategoryConfig>[];
    for (final def in defaults) {
      final existing = stored.firstWhere(
        (item) => item.id == def.id,
        orElse: () => def,
      );
      existing.isSystem = true;
      all.add(existing);
    }
    all.addAll(stored.where((item) => !defaults.any((def) => def.id == item.id)));
    return all;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _categories.value.map((e) => e.toJson()).toList();
    await prefs.setString(_prefsKey, json.encode(list));
  }

  Future<void> createCustom({required String name, Color? color}) async {
    await ensureLoaded();
    final cfg = CategoryConfig(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      label: name,
      color: (color ?? Colors.teal).value,
      isSystem: false,
    );
    final next = [..._categories.value, cfg];
    _categories.value = List.unmodifiable(next);
    await _persist();
  }

  Future<void> rename(String id, String newName) async {
    await ensureLoaded();
    final list = _categories.value.map((cfg) {
      if (cfg.id == id) {
        cfg = CategoryConfig(
          id: cfg.id,
          label: newName,
          color: cfg.color,
          isSystem: cfg.isSystem,
          visible: cfg.visible,
        );
      }
      return cfg;
    }).toList();
    _categories.value = List.unmodifiable(list);
    await _persist();
  }

  Future<void> setVisibility(String id, bool visible) async {
    await ensureLoaded();
    final list = _categories.value.map((cfg) {
      if (cfg.id == id) {
        cfg = CategoryConfig(
          id: cfg.id,
          label: cfg.label,
          color: cfg.color,
          isSystem: cfg.isSystem,
          visible: visible,
        );
      }
      return cfg;
    }).toList();
    _categories.value = List.unmodifiable(list);
    await _persist();
  }

  Future<void> delete(String id) async {
    await ensureLoaded();
    final list = _categories.value.where((cfg) => cfg.id != id).toList();
    _categories.value = List.unmodifiable(list);
    await _persist();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    await ensureLoaded();
    final list = [..._categories.value];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _categories.value = List.unmodifiable(list);
    await _persist();
  }

  CategoryConfig? findById(String? id) {
    if (id == null) return null;
    return _categories.value.firstWhere(
      (cfg) => cfg.id == id,
      orElse: () => CategoryConfig(id: id, label: 'Danh mục', color: Colors.grey.value),
    );
  }

  static String _systemId(TaskCategory category) {
    switch (category) {
      case TaskCategory.none:
        return 'none';
      case TaskCategory.work:
        return 'work';
      case TaskCategory.personal:
        return 'personal';
      case TaskCategory.favorites:
        return 'favorite';
      case TaskCategory.birthday:
        return 'birthday';
    }
  }

  String? systemCategoryId(TaskCategory category) =>
      _systemId(category) == 'none' ? null : _systemId(category);

  TaskCategory? resolveSystem(String? id) {
    switch (id) {
      case 'work':
        return TaskCategory.work;
      case 'personal':
        return TaskCategory.personal;
      case 'favorite':
        return TaskCategory.favorites;
      case 'birthday':
        return TaskCategory.birthday;
      case 'none':
        return TaskCategory.none;
    }
    return null;
  }
}

String resolveCategoryLabel(Task task, List<CategoryConfig> configs) {
  if (task.customCategoryId != null) {
    final match = configs.firstWhere(
      (cfg) => cfg.id == task.customCategoryId,
      orElse: () => CategoryConfig(
        id: task.customCategoryId!,
        label: 'Danh mục riêng',
        color: Colors.teal.value,
      ),
    );
    return match.label;
  }
  return categoryLabel(task.category);
}