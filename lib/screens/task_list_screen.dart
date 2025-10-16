import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task.dart';
import '../widgets/task_item.dart';
import 'add_task_sheet.dart';
import 'category_manager_screen.dart';
import 'task_detail_screen.dart';

// DB & Repo
import '../services/db_service.dart';
import '../models/domain/entities/task_entity.dart';
import '../models/data/repositories/task_repository.dart';
import '../services/notification_service.dart';

// tách tab
import 'tabs/menu_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/me_tab.dart';

// search
import 'search/task_search_delegate.dart';

// 👇 thêm: Pro demo
import '../services/pro_manager.dart';
import 'Pay/upgrade_pro_demo_screen.dart';
import '../services/category_store.dart';

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
  final TaskRepository _repo = DbService.tasks;
  final List<Task> _items = [];
  StreamSubscription<List<TaskEntity>>? _subscription;
  final CategoryStore _categoryStore = CategoryStore.instance;

  // Map DB -> UI Task
  Task _fromEntity(TaskEntity e) {
    final due = e.dueAt?.toLocal();

    Duration? remindBefore;
    if (e.remindAt != null && due != null) {
      final diff =
          due.millisecondsSinceEpoch - e.remindAt!.millisecondsSinceEpoch;
      if (diff > 0) remindBefore = Duration(milliseconds: diff);
    }

    TimeOfDay? timeOfDay;
    if (due != null && (due.hour != 0 || due.minute != 0)) {
      timeOfDay = TimeOfDay(hour: due.hour, minute: due.minute);
    }

    final categoryId = e.categoryId;
    final TaskCategory? category = _categoryFromId(categoryId);
    final String? customCategoryId = category == null ? categoryId : null;

    return Task(
      id: (e.id ?? 0).toString(),
      title: e.title,
      category: category ?? TaskCategory.none,
      customCategoryId: customCategoryId,
      dueDate: due,
      timeOfDay: timeOfDay,
      reminderBefore: remindBefore,
      repeat: RepeatRule.none,
      subtasks: const [],
      done: e.status == 'done',
      favorite: e.favorite,
      notes: e.notes,
      createdAt: e.createdAt.toLocal(),
      updatedAt: e.updatedAt.toLocal(),
    );
  }

  TaskCategory? _categoryFromId(String? id) {
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
      default:
        return null;
    }
  }

  String? _categoryToId(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return 'work';
      case TaskCategory.personal:
        return 'personal';
      case TaskCategory.favorites:
        return 'favorite';
      case TaskCategory.birthday:
        return 'birthday';
      case TaskCategory.none:
        return null;
    }
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

    return TaskEntity(
      id: int.tryParse(t.id),
      title: t.title,
      notes: t.notes,
      dueAt: due,
      remindAt:
          remindAtMs != null ? DateTime.fromMillisecondsSinceEpoch(remindAtMs) : null,
      status: t.done ? 'done' : 'todo',
      priority: 'normal',
      categoryId: t.customCategoryId ?? _categoryToId(t.category),
      tags: const [],
      favorite: t.favorite,
      createdAt: t.createdAt.toUtc(),
      updatedAt: t.updatedAt.toUtc(),
    );
  }

  // -------------------- CRUD helpers (đÃ GỘP, KHÔNG TRÙNG) --------------------

  Future<int> _addTask(Task newTask) async {
    final now = DateTime.now();
    newTask
      ..createdAt = now
      ..updatedAt = now;

    final entity = _toEntity(newTask);
    final id = await _repo.add(entity);

    // gán id lại cho Task UI
    newTask.id = id.toString();

    // chỉ đặt reminder nếu chưa hoàn thành
    if (!newTask.done) {
      await NotificationService.instance
          .scheduleForTask(entity.copyWith(id: id));
    }
    return id;
  }

  Future<void> _updateTask(Task t) async {
    // cập nhật thời gian sửa
    t.updatedAt = DateTime.now();

    final id = int.tryParse(t.id);
    if (id == null) return;

    final entity = _toEntity(t).copyWith(id: id);

    // lưu DB (updatedAt đã được set mới)
    await _repo.update(entity);

    // quản lý nhắc nhở theo trạng thái
    if (t.done) {
      await NotificationService.instance.cancelReminder(id);
    } else {
      await NotificationService.instance.scheduleForTask(entity);
    }
  }

  Future<void> _deleteTaskById(String? id) async {
    final intId = int.tryParse(id ?? '');
    if (intId != null) {
      await _repo.delete(intId);
      await NotificationService.instance.cancelReminder(intId);
    }
  }

  void _showStatusSnackBar(String message, {IconData? icon, Color? iconColor}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final scheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: scheme.surface.withOpacity(.95),
        elevation: 3,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? scheme.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  void _toggleTaskDone(Task task) {
    final next = !task.done;
    setState(() => task.done = next);
    HapticFeedback.selectionClick();
    unawaited(_updateTask(task));
    _showStatusSnackBar(
      next ? 'Đã hoàn thành “${task.title}”' : 'Đã mở lại “${task.title}”',
      icon: next ? Icons.check_circle : Icons.restart_alt,
      iconColor: next ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
    );
  }

  Future<void> _launchUri(Uri uri) async {
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && mounted) {
        _showStatusSnackBar('Không thể mở liên hệ, vui lòng thử lại sau.', icon: Icons.error_outline);
      }
    } catch (e) {
      if (mounted) {
        _showStatusSnackBar('Không thể mở liên hệ, vui lòng thử lại sau.', icon: Icons.error_outline);
      }
    }
  }

  void _showContactSheet() {
    if (!mounted) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: .4,
          minChildSize: .32,
          maxChildSize: .6,
          expand: false,
          builder: (context, controller) {
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    scheme.primaryContainer.withOpacity(.92),
                    scheme.secondaryContainer.withOpacity(.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(.18),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary.withOpacity(.18),
                            ),
                            child: Icon(Icons.support_agent, color: scheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cần trợ giúp?',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Liên hệ với chúng tôi để được hỗ trợ nhanh chóng.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onPrimaryContainer.withOpacity(.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ContactAction(
                        icon: Icons.chat_bubble_outline,
                        label: 'Nhắn tin Zalo',
                        subtitle: 'Nhận phản hồi trong vài phút',
                        color: scheme.primary,
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchUri(Uri.parse('https://zalo.me/0372513965'));
                        },
                      ),
                      const SizedBox(height: 12),
                      _ContactAction(
                        icon: Icons.email_outlined,
                        label: 'Gửi email',
                        subtitle: 'support@todoapp.vn',
                        color: scheme.secondary,
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchUri(Uri(scheme: 'mailto', path: 'support@todoapp.vn'));
                        },
                      ),
                      const SizedBox(height: 12),
                      _ContactAction(
                        icon: Icons.phone_outlined,
                        label: 'Gọi đường dây nóng',
                        subtitle: '0372 513 965',
                        color: scheme.tertiary,
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchUri(Uri(scheme: 'tel', path: '0372513965'));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleFavorite(Task task) {
    final next = !task.favorite;
    setState(() => task.favorite = next);
    HapticFeedback.lightImpact();
    unawaited(_updateTask(task));
    _showStatusSnackBar(
      next
          ? 'Đã thêm “${task.title}” vào yêu thích'
          : 'Đã xoá “${task.title}” khỏi yêu thích',
      icon: next ? Icons.star : Icons.star_border,
      iconColor: next ? Colors.amber : Theme.of(context).colorScheme.outline,
    );
  }

  Future<void> _createTask() async {
    HapticFeedback.mediumImpact();
    final newTask = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const AddTaskSheet(),
    );
    if (newTask == null) return;
    await _addTask(newTask);
    if (!mounted) return;
    setState(() {});
    _showStatusSnackBar(
      'Đã tạo nhiệm vụ “${newTask.title}”',
      icon: Icons.add_task,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }

  Future<void> _createTaskForDate(DateTime date) async {
    HapticFeedback.mediumImpact();
    final initial = Task(
      id: UniqueKey().toString(),
      title: '',
      category: TaskCategory.work,
      dueDate: date,
    );
    final newTask = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AddTaskSheet(initial: initial),
    );
    if (newTask == null) return;
    await _addTask(newTask);
    if (!mounted) return;
    setState(() {});
    _showStatusSnackBar(
      'Đã tạo nhiệm vụ “${newTask.title}”',
      icon: Icons.add_task,
      iconColor: Theme.of(context).colorScheme.primary,
    );
  }

  PageRoute<T> _buildPageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final offset = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  Future<T?> _pushPage<T>(Widget page) {
    return Navigator.of(context).push<T>(_buildPageRoute(page));
  }

  // -------------------- UI state --------------------
  int _tabIndex = 1; // 0=Menu, 1=Nhiệm vụ, 2=Lịch, 3=Của tôi
  TaskCategory? _filterCategory; // null = tất cả
  String? _filterCustomId;
  SortOption _sort = SortOption.dueDate;
  bool _compact = false;

  List<Task> get _filtered {
    List<Task> list = List.of(_items);
    if (_filterCustomId != null) {
      list = list.where((t) => t.customCategoryId == _filterCustomId).toList();
    } else if (_filterCategory != null) {
      list = list.where((t) {
        switch (_filterCategory!) {
          case TaskCategory.work:
            return t.category == TaskCategory.work;
          case TaskCategory.personal:
            return t.category == TaskCategory.personal;
          case TaskCategory.favorites:
            return t.favorite || t.category == TaskCategory.favorites;
          case TaskCategory.birthday:
            return t.category == TaskCategory.birthday;
          case TaskCategory.none:
            return t.category == TaskCategory.none;
        }
      }).toList();
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
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.createdNewestTop:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
        // thứ tự giữ nguyên theo _items
        break;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    if (widget.tasks.isNotEmpty) {
      _items.addAll(widget.tasks.map((task) => task.clone()));
    }
    unawaited(_categoryStore.ensureLoaded());
    // Lắng nghe DB → cập nhật UI + đồng bộ notifications
    _subscription = _repo.watchAll().listen(
      (rows) {
        setState(() {
          _items
            ..clear()
            ..addAll(rows.map(_fromEntity));
        });

        for (final entity in rows) {
          if (entity.id == null) continue;
          if (entity.status == 'done') {
            unawaited(NotificationService.instance.cancelReminder(entity.id));
          } else {
            unawaited(NotificationService.instance.scheduleForTask(entity));
          }
        }
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Lỗi khi đồng bộ nhiệm vụ: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Menu', 'Nhiệm vụ', 'Lịch', 'Của tôi'];
    final view = _buildTabView(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradients = [
      [scheme.secondaryContainer.withOpacity(.55), scheme.surface],
      [scheme.primaryContainer.withOpacity(.55), scheme.surface],
      [scheme.tertiaryContainer.withOpacity(.55), scheme.surface],
      [scheme.surfaceTint.withOpacity(.35), scheme.surface],
    ];
    final gradient = gradients[_tabIndex.clamp(0, gradients.length - 1)];
    final useGradient = _tabIndex == 1;

    final scaffold = Scaffold(
      backgroundColor: useGradient ? Colors.transparent : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            titles[_tabIndex],
            key: ValueKey(_tabIndex),
          ),
        ),
        actions: _tabIndex == 1
            ? [
                IconButton(
                  tooltip: 'Liên hệ hỗ trợ',
                  icon: const Icon(Icons.support_agent),
                  onPressed: _showContactSheet,
                ),
                _buildMoreMenu(),
              ]
            : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(.02, .04),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('tab-$_tabIndex'),
            child: view,
          ),
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        ),
        child: _tabIndex == 1
            ? FloatingActionButton(
                key: const ValueKey('fab'),
                onPressed: _createTask,
                child: const Icon(Icons.add),
              )
            : const SizedBox.shrink(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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

    if (!useGradient) {
      return scaffold;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: scaffold,
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
                Expanded(child: Text('Hiển thị chế độ gọn')),
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
        final selected = await showSearch<Task?>(
          context: context,
          delegate: TaskSearchDelegate(_items),
        );
        if (selected != null) {
          final task = _items.firstWhere(
            (t) => t.id == selected.id,
            orElse: () => selected,
          );
          await _openTaskDetail(task);
        }
        break;
      case _MenuAction.sort:
        final picked = await _showSortDialog();
        if (picked != null) setState(() => _sort = picked);
        break;
      case _MenuAction.printTasks:
        await _showExportDialog();
        break;
      case _MenuAction.toggleCompact:
        setState(() => _compact = !_compact);
        break;
      case _MenuAction.upgradePro:
        await _pushPage(const UpgradeProDemoScreen());
        if (mounted) setState(() {});
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
  Widget _buildTabView(BuildContext context) {
    switch (_tabIndex) {
      case 0:
        return MenuTab(
          onOpenCategories: () => _pushPage(
            CategoryManagerScreen(tasks: _items),
          ),
          onUpgradePro: () {
            _pushPage(const UpgradeProDemoScreen()).then((_) {
              if (mounted) setState(() {});
            });
          },
        );
      case 2:
        return CalendarTab(
          tasks: _items,
          onOpenTask: _openTaskDetail,
          onCreateForDate: _createTaskForDate,
        );
      case 3:
        return MeTab(
          tasks: _items,
          onUpgrade: () {
            _pushPage(const UpgradeProDemoScreen()).then((_) {
              if (mounted) setState(() {});
            });
          },
        );
      default:
        return _buildTasksView(context);
    }
  }

  Future<void> _openTaskDetail(Task task) async {
    final detailCopy = task.clone();
    final result = await Navigator.of(context).push<Task>(
      TaskDetailScreen.route(detailCopy),
    );
    if (result != null) {
      result
        ..id = task.id
        ..createdAt = task.createdAt;
      final index = _items.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        setState(() {
          _items[index] = result;
        });
      }
      await _updateTask(result);
    }
  }

  Future<void> _showExportDialog() async {
    final tasks = _filtered;
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có nhiệm vụ nào để xuất')),
      );
      return;
    }

    final buffer = StringBuffer();
    for (final task in tasks) {
      final status = task.done ? '✓' : '•';
      final due = _formatDueLabel(task);
      buffer.writeln('$status ${task.title} (${due ?? 'Không hạn'})');
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xuất danh sách nhiệm vụ'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: SingleChildScrollView(
            child: SelectableText(buffer.toString()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG')),
        ],
      ),
    );
  }


  Widget _buildTasksView(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final physics = const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

    return ValueListenableBuilder<List<CategoryConfig>>(
      valueListenable: _categoryStore.listenable,
      builder: (context, categories, _) {
        final list = _filtered;
        final hasData = list.isNotEmpty;

        Widget chip({
          required IconData icon,
          required String label,
          required bool selected,
          required VoidCallback onTap,
        }) {
          final fg = selected ? scheme.onPrimary : scheme.onSurface;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RawChip(
              avatar: Icon(icon, size: 18, color: fg),
              label: Text(label),
              labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              showCheckmark: false,
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              pressElevation: 0,
              shadowColor: Colors.transparent,
              selected: selected,
              selectedColor: scheme.primary,
              backgroundColor: scheme.surfaceVariant.withOpacity(.55),
              onSelected: (_) => onTap(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: selected ? Colors.transparent : scheme.outline.withOpacity(.2),
                ),
              ),
            ),
          );
        }

        IconData iconForConfig(CategoryConfig cfg) {
          if (cfg.isSystem) {
            switch (_categoryStore.resolveSystem(cfg.id)) {
              case TaskCategory.work:
                return Icons.work_outline;
              case TaskCategory.personal:
                return Icons.self_improvement;
              case TaskCategory.favorites:
                return Icons.star_rounded;
              case TaskCategory.birthday:
                return Icons.cake_outlined;
              case TaskCategory.none:
              case null:
                return Icons.inbox_outlined;
            }
          }
          return Icons.folder_outlined;
        }

        final visibleConfigs = categories.where((cfg) => cfg.visible).toList();

        final chipBar = AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: hasData ? 1 : .35,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer.withOpacity(.85),
                  scheme.secondaryContainer.withOpacity(.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  chip(
                    icon: Icons.all_inclusive,
                    label: 'Tất cả',
                    selected: _filterCategory == null && _filterCustomId == null,
                    onTap: () => setState(() {
                      _filterCategory = null;
                      _filterCustomId = null;
                    }),
                  ),
                  for (final cfg in visibleConfigs)
                    chip(
                      icon: iconForConfig(cfg),
                      label: cfg.label,
                      selected: cfg.isSystem
                          ? (_filterCategory != null &&
                              _categoryStore.resolveSystem(cfg.id) == _filterCategory)
                          : _filterCustomId == cfg.id,
                      onTap: () => setState(() {
                        if (cfg.isSystem) {
                          _filterCustomId = null;
                          _filterCategory = _categoryStore.resolveSystem(cfg.id);
                        } else {
                          _filterCategory = null;
                          _filterCustomId = cfg.id;
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
        );

        Future<void> handleDismiss(Task task) async {
          setState(() {
            _items.removeWhere((it) => it.id == task.id);
          });
          await _deleteTaskById(task.id);
          if (!mounted) return;
          _showStatusSnackBar(
            'Đã xoá “${task.title}”',
            icon: Icons.delete_outline,
            iconColor: theme.colorScheme.error,
          );
        }

        CategoryConfig? configForTask(Task task) {
          if (task.customCategoryId != null) {
            return categories.firstWhere(
              (cfg) => cfg.id == task.customCategoryId,
              orElse: () => CategoryConfig(
                id: task.customCategoryId!,
                label: 'Danh mục riêng',
                color: Colors.teal.value,
              ),
            );
          }
          final sysId = _categoryStore.systemCategoryId(task.category);
          if (sysId == null) return null;
          return categories.firstWhere(
            (cfg) => cfg.id == sysId,
            orElse: () => CategoryConfig(
              id: sysId,
              label: categoryLabel(task.category),
              color: scheme.secondary.value,
              isSystem: true,
            ),
          );
        }

        Widget buildCard(Task t, Key key) {
          final cfg = configForTask(t);
          final catName = cfg?.label;
          final catColor = cfg != null ? Color(cfg.color) : null;
          return Dismissible(
            key: key,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.error.withOpacity(.14),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Icon(Icons.delete_outline, color: scheme.error.withOpacity(.8)),
            ),
            secondaryBackground: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.error.withOpacity(.14),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Icon(Icons.delete_outline, color: scheme.error.withOpacity(.8)),
            ),
            onDismissed: (_) => handleDismiss(t),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: TaskItem(
                compact: _compact,
                task: t,
                categoryName: catName,
                categoryColor: catColor,
                onToggleDone: () => _toggleTaskDone(t),
                onOpenDetail: () => _openTaskDetail(t),
                onToggleFavorite: () => _toggleFavorite(t),
              ),
            ),
          );
        }

        final manualList = ReorderableListView.builder(
          key: const PageStorageKey('manual-list'),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          onReorder: (oldIndex, newIndex) {
            if (_filterCategory != null || _filterCustomId != null) return;
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
            });
          },
          itemBuilder: (ctx, i) {
            final t = list[i];
            return buildCard(t, ValueKey('manual-${t.id}'));
          },
        );

        final filterKey = _filterCustomId ?? _filterCategory?.name ?? 'all';
        final defaultList = ListView.builder(
          key: ValueKey('list-$filterKey-${_sort.name}-${_compact ? 'compact' : 'cozy'}'),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final t = list[i];
            return buildCard(t, ValueKey('default-${t.id}'));
          },
        );

        return CustomScrollView(
          key: ValueKey('tasks-$filterKey-${_sort.name}-${_items.length}-${hasData ? 'data' : 'empty'}'),
          physics: physics,
          slivers: [
            SliverToBoxAdapter(child: _buildOverviewCard(context)),
            SliverToBoxAdapter(child: chipBar),
            if (hasData)
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: _SliverAnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0, .04),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offsetAnimation, child: child),
                    );
                  },
                  child: _sort == SortOption.manual ? manualList : defaultList,
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(context),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _items.length;
    final completed = _items.where((t) => t.done).length;
    final pending = total - completed;
    final today = DateTime.now();
    final dueToday = _items.where((t) {
      if (t.dueDate == null || t.done) return false;
      return DateUtils.isSameDay(t.dueDate, today);
    }).length;
    final nextTask = _nextDueTask();
    final nextLabel = nextTask == null
        ? 'Tạo nhiệm vụ mới để bắt đầu ngày làm việc.'
        : 'Tiếp theo: ${nextTask.title}\n${_formatDueLabel(nextTask) ?? 'Không có hạn cụ thể'}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withOpacity(.75),
              scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(.18),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng quan hôm nay',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 520;
                  final tileWidth = isCompact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 24) / 3;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metricStat(
                        context,
                        label: 'Đang mở',
                        value: pending,
                        icon: Icons.circle_outlined,
                        color: scheme.primary,
                        width: tileWidth,
                      ),
                      _metricStat(
                        context,
                        label: 'Hoàn thành',
                        value: completed,
                        icon: Icons.check_circle,
                        color: scheme.secondary,
                        width: tileWidth,
                      ),
                      _metricStat(
                        context,
                        label: 'Đến hạn hôm nay',
                        value: dueToday,
                        icon: Icons.today,
                        color: scheme.tertiary,
                        width: tileWidth,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Text(
                  nextLabel,
                  key: ValueKey(nextLabel),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricStat(
    BuildContext context, {
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    double? width,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final gradient = LinearGradient(
      colors: [
        color.withOpacity(.28),
        color.withOpacity(.12),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.68),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Text(
              '$value',
              key: ValueKey('$label-$value'),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(color: color.withOpacity(.9)),
          ),
        ],
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }

  Task? _nextDueTask() {
    final now = DateTime.now();
    final upcoming = _items.where((t) {
      if (t.done) return false;
      final due = _dueDateTime(t);
      return due != null && !due.isBefore(now);
    }).toList()
      ..sort((a, b) {
        final ad = _dueDateTime(a)!;
        final bd = _dueDateTime(b)!;
        return ad.compareTo(bd);
      });
    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }

    final overdue = _items.where((t) {
      if (t.done) return false;
      final due = _dueDateTime(t);
      return due != null && due.isBefore(now);
    }).toList()
      ..sort((a, b) => _dueDateTime(a)!.compareTo(_dueDateTime(b)!));
    if (overdue.isNotEmpty) return overdue.first;

    final pending = _items.where((t) => !t.done).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pending.isNotEmpty ? pending.first : null;
  }

  DateTime? _dueDateTime(Task task) {
    final due = task.dueDate;
    if (due == null) return null;
    if (task.timeOfDay != null) {
      return DateTime(
        due.year,
        due.month,
        due.day,
        task.timeOfDay!.hour,
        task.timeOfDay!.minute,
      );
    }
    return DateTime(due.year, due.month, due.day, 23, 59);
  }

  String? _formatDueLabel(Task task) {
    final due = task.dueDate;
    if (due == null) return null;
    final dd = due.day.toString().padLeft(2, '0');
    final mm = due.month.toString().padLeft(2, '0');
    final yyyy = due.year.toString();
    final dateLabel = '$dd/$mm/$yyyy';
    if (task.timeOfDay != null) {
      final hh = task.timeOfDay!.hour.toString().padLeft(2, '0');
      final minutes = task.timeOfDay!.minute.toString().padLeft(2, '0');
      return '$hh:$minutes · $dateLabel';
    }
    return dateLabel;
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

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(.12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(.18),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAnimatedSwitcher extends StatelessWidget {
  const _SliverAnimatedSwitcher({
    super.key,
    required this.duration,
    required this.switchInCurve,
    required this.switchOutCurve,
    required this.transitionBuilder,
    required this.child,
  });

  final Duration duration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: switchInCurve,
        switchOutCurve: switchOutCurve,
        transitionBuilder: transitionBuilder,
        child: child,
      ),
    );
  }
}