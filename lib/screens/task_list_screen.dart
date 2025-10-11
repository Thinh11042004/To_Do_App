import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_item.dart';
import 'add_task_sheet.dart';
import 'category_manager_screen.dart';

// DB & Repo
import '../services/db_service.dart';
import '../models/domain/entities/task_entity.dart';
import '../models/data/repositories/task_repository_drift.dart';

// tách tab
import 'tabs/menu_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/me_tab.dart';

// search
import 'search/task_search_delegate.dart';

// 👇 thêm: Pro demo
import '../services/pro_manager.dart';
import 'Pay/upgrade_pro_demo_screen.dart.dart';

enum SortOption {
  dueDate,
  createdNewestBottom,
  createdNewestTop,
  az,
  za,
  manual,
}

enum _MenuAction {
  manageCategories,
  search,
  sort,
  printTasks,
  toggleCompact,
  upgradePro,
}

class TaskListScreen extends StatefulWidget {
  final List<Task> tasks; // giữ tham số cũ để không phá route khác
  final void Function(Task) onAdd;
  final void Function(Task) onUpdate;

  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.onAdd,
    required this.onUpdate,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // ----- DB + memory -----
  final TaskRepositoryDrift _repo = DbService.tasks;
  List<Task> _items = [];

  // Map DB -> UI Task
  Task _fromEntity(TaskEntity e) {
    final due = e.dueAt?.toLocal();
    Duration? remindBefore;
    if (e.remindAt != null && due != null) {
      final diff =
          due.millisecondsSinceEpoch - e.remindAt!.millisecondsSinceEpoch;
      if (diff > 0) remindBefore = Duration(milliseconds: diff);
    }
    return Task(
      id: (e.id ?? 0).toString(),
      title: e.title,
      category: TaskCategory.none, // TODO: map từ e.categoryId nếu bạn dùng
      dueDate: due,
      timeOfDay: null, // TODO: nếu cần, tách giờ phút từ due
      reminderBefore: remindBefore,
      repeat: RepeatRule.none,
      subtasks: const [],
      done: e.status == 'done',
      favorite: false,
    );
  }

  // Map UI -> DB entity
  TaskEntity _toEntity(Task t) {
    DateTime? due;
    if (t.dueDate != null && t.timeOfDay != null) {
      due = DateTime(
        t.dueDate!.year,
        t.dueDate!.month,
        t.dueDate!.day,
        t.timeOfDay!.hour,
        t.timeOfDay!.minute,
      );
    } else {
      due = t.dueDate;
    }

    final int? remindAtMs = (due != null && t.reminderBefore != null)
        ? due.millisecondsSinceEpoch - t.reminderBefore!.inMilliseconds
        : null;

    final now = DateTime.now();
    return TaskEntity(
      id: int.tryParse(t.id),
      title: t.title,
      notes: null,
      dueAt: due,
      remindAt: remindAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(remindAtMs)
          : null,
      status: t.done ? 'done' : 'todo',
      priority: 'normal',
      categoryId: null, // TODO: map từ t.category nếu bạn dùng
      tags: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // CRUD helpers
  Future<void> _addTask(Task newTask) async {
    final e = _toEntity(newTask);
    await _repo.add(e);
  }

  Future<void> _updateTask(Task t) async {
    final e = _toEntity(t);
    if (e.id == null) return;
    await _repo.update(e.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> _deleteTaskById(String? id) async {
    final intId = int.tryParse(id ?? '');
    if (intId != null) await _repo.delete(intId);
  }

  int _tabIndex = 1; // 0=Menu, 1=Nhiệm vụ, 2=Lịch, 3=Của tôi
  TaskCategory? filter; // null = tất cả
  SortOption _sort = SortOption.dueDate;
  bool _compact = false;

  List<Task> get _filtered {
    List<Task> list = List.of(_items);
    if (filter != null) {
      list = list
          .where(
            (t) =>
                (filter == TaskCategory.work &&
                    t.category == TaskCategory.work) ||
                (filter == TaskCategory.personal &&
                    t.category == TaskCategory.personal),
          )
          .toList();
    }
    switch (_sort) {
      case SortOption.dueDate:
        list.sort((a, b) {
          final ad = a.dueDate, bd = b.dueDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          final at = a.timeOfDay, bt = b.timeOfDay;
          final adt = DateTime(
            ad.year,
            ad.month,
            ad.day,
            at?.hour ?? 23,
            at?.minute ?? 59,
          );
          final bdt = DateTime(
            bd.year,
            bd.month,
            bd.day,
            bt?.hour ?? 23,
            bt?.minute ?? 59,
          );
          return adt.compareTo(bdt);
        });
        break;
      case SortOption.createdNewestBottom:
        break;
      case SortOption.createdNewestTop:
        list = list.reversed.toList();
        break;
      case SortOption.az:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOption.za:
        list.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case SortOption.manual:
        break;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    // Lắng nghe DB → cập nhật UI
    _repo.watchAll().listen((rows) {
      setState(() {
        _items = rows.map(_fromEntity).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Menu', 'Nhiệm vụ', 'Lịch', 'Của tôi'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
        actions: _tabIndex == 1 ? [_buildMoreMenu()] : null,
      ),
      body: _buildBody(context),
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton(
              onPressed: () async {
                final newTask = await showModalBottomSheet<Task>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (_) => const AddTaskSheet(),
                );
                if (newTask != null) await _addTask(newTask);
                setState(() {});
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Nhiệm vụ'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Của tôi',
          ),
        ],
      ),
    );
  }

  PopupMenuButton<_MenuAction> _buildMoreMenu() {
    return PopupMenuButton<_MenuAction>(
      icon: const Icon(Icons.more_vert),
      onSelected: _onMenuAction,
      itemBuilder: (ctx) {
        final isPro = ProManager.instance.isPro.value;
        return [
          const PopupMenuItem(
            value: _MenuAction.manageCategories,
            child: Text('Quản lý Danh mục'),
          ),
          const PopupMenuItem(
            value: _MenuAction.search,
            child: Text('Tìm kiếm'),
          ),
          const PopupMenuItem(
            value: _MenuAction.sort,
            child: Text('Sắp xếp công việc'),
          ),
          const PopupMenuItem(value: _MenuAction.printTasks, child: Text('In')),
          PopupMenuItem(
            value: _MenuAction.toggleCompact,
            child: Row(
              children: const [
                Expanded(child: Text('Hiện Tại Công Việc Nhỏ')),
                Icon(Icons.workspace_premium, color: Colors.amber),
              ],
            ),
          ),
          if (!isPro)
            const PopupMenuItem(
              value: _MenuAction.upgradePro,
              child: Text('Nâng cấp lên Pro'),
            ),
        ];
      },
    );
  }

  void _onMenuAction(_MenuAction a) async {
    switch (a) {
      case _MenuAction.manageCategories:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryManagerScreen(tasks: _items),
          ),
        );
        break;
      case _MenuAction.search:
        showSearch(
          context: context,
          delegate: TaskSearchDelegate(
            _items,
            onTapTask: (_) => Navigator.pop(context),
          ),
        );
        break;
      case _MenuAction.sort:
        final picked = await _showSortDialog();
        if (picked != null) setState(() => _sort = picked);
        break;
      case _MenuAction.printTasks:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo: In danh sách nhiệm vụ')),
        );
        break;
      case _MenuAction.toggleCompact:
        setState(() => _compact = !_compact);
        break;
      case _MenuAction.upgradePro:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradeProDemoScreen()),
        );
        setState(() {});
        break;
    }
  }

  Future<SortOption?> _showSortDialog() async {
    SortOption temp = _sort;
    return showDialog<SortOption>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Các nhiệm vụ được sắp xếp theo'),
        content: StatefulBuilder(
          builder: (_, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final opt in SortOption.values)
                RadioListTile<SortOption>(
                  value: opt,
                  groupValue: temp,
                  onChanged: (v) => setS(() => temp = v!),
                  title: Text(
                    {
                      SortOption.dueDate: 'Ngày và giờ đến hạn',
                      SortOption.createdNewestBottom:
                          'Thời gian tạo (Mới nhất dưới cùng)',
                      SortOption.createdNewestTop:
                          'Thời gian tạo (Mới nhất trên cùng)',
                      SortOption.az: 'Bảng chữ cái A-Z',
                      SortOption.za: 'Bảng chữ cái Z-A',
                      SortOption.manual: 'Thủ công (nhấn & giữ để sắp xếp)',
                    }[opt]!,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('HUỶ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, temp),
            child: const Text('CHỌN'),
          ),
        ],
      ),
    );
  }

  // -------------------- BODY --------------------
  Widget _buildBody(BuildContext context) {
    if (_tabIndex == 0) {
      return MenuTab(
        onOpenCategories: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryManagerScreen(tasks: _items),
          ),
        ),
        onUpgradePro: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradeProDemoScreen()),
        ),
      );
    }
    if (_tabIndex == 2) return CalendarTab(tasks: _items);
    if (_tabIndex == 3) {
      return MeTab(
        tasks: _items,
        onUpgrade: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradeProDemoScreen()),
        ),
      );
    }

    // Tab NHIỆM VỤ
    final list = _filtered;
    final hasData = list.isNotEmpty;

    ChoiceChip _chip(String text, bool selected, VoidCallback onTap) {
      final s = Theme.of(context).colorScheme;
      final bg = selected ? s.primary : s.primaryContainer;
      final fg = selected ? s.onPrimary : s.onPrimaryContainer;
      return ChoiceChip(
        label: Text(
          text,
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
        ),
        selected: selected,
        selectedColor: bg,
        backgroundColor: bg.withOpacity(selected ? 1 : .7),
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: selected,
      );
    }

    final chipBar = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _chip('Tất cả', filter == null, () => setState(() => filter = null)),
          const SizedBox(width: 8),
          _chip(
            'Công việc',
            filter == TaskCategory.work,
            () => setState(() => filter = TaskCategory.work),
          ),
          const SizedBox(width: 8),
          _chip(
            'Cá nhân',
            filter == TaskCategory.personal,
            () => setState(() => filter = TaskCategory.personal),
          ),
        ],
      ),
    );

    final listView = (_sort == SortOption.manual)
        ? ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: list.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
              });
            },
            itemBuilder: (ctx, i) {
              final t = list[i];
              return Dismissible(
                key: ValueKey(t.id),
                background: Container(color: Colors.redAccent.withOpacity(.2)),
                onDismissed: (_) async => await _deleteTaskById(t.id),
                child: TaskItem(
                  compact: _compact,
                  task: t,
                  onToggleDone: () async {
                    t.done = !t.done;
                    await _updateTask(t);
                    setState(() {});
                  },
                  onTap: () async {
                    t.favorite = !t.favorite;
                    await _updateTask(t);
                    setState(() {});
                  },
                ),
              );
            },
          )
        : ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final t = list[i];
              return TaskItem(
                compact: _compact,
                task: t,
                onToggleDone: () async {
                  t.done = !t.done;
                  await _updateTask(t);
                  setState(() {});
                },
                onTap: () async {
                  t.favorite = !t.favorite;
                  await _updateTask(t);
                  setState(() {});
                },
              );
            },
          );

    return Column(
      children: [
        chipBar,
        Expanded(child: hasData ? listView : _emptyState(context)),
      ],
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.laptop_chromebook, size: 120),
          const SizedBox(height: 16),
          Text(
            'Không có nhiệm vụ nào trong danh mục này.\nNhấp vào + để tạo nhiệm vụ của bạn.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
