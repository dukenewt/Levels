// MVP: Calendar feature shelved. File commented out.
/*
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../../providers/calendar_provider.dart';  // ✅
import '../../models/task.dart';                   // ✅
import '../widgets/task_tile.dart';
import 'secure_task_provider.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _events = {};
  String? _selectedCategory;
  String _currentView = 'day';
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  String? _error;
  bool _hasAutoScrolledWeek = false;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  final StorageService storage;
  SecureTaskProvider? taskProvider; //store reference instead of using context

  final List<String> categories = ['All', 'Work', 'Personal', 'Health', 'Learning', 'Other'];

  // Getters
  CalendarFormat get calendarFormat => _calendarFormat;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  Map<DateTime, List<Task>> get events => _events;
  String? get selectedCategory => _selectedCategory;
  String get currentView => _currentView;
  TimeOfDay get selectedTime => _selectedTime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasAutoScrolledWeek => _hasAutoScrolledWeek;

  CalendarProvider({required this.storage}) {
    _selectedDay = _focusedDay;
    // _initializeData(); // Initialization requiring context must be triggered from a widget
  }

  Future<void> initialize(SecureTaskProvider taskProvider) async {
    if (_isInitialized) return;
    this.taskProvider = taskProvider;
    _isLoading = true;
    notifyListeners();

    try {
      await loadEvents();
      await loadCategories();
      _isInitialized = true;
    } catch (e) {
      _error = 'Error loading data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEvents() async {
    if (taskProvider == null) return;
    Map<DateTime, List<Task>> newEvents = {};
    // ... rest of your logic using taskProvider instead of _taskProvider
    // (Assume startDate and endDate are defined as before)
    // Example:
    // for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
    //   final tasks = await taskProvider!.getTasksForDate(date);
    //   newEvents[DateTime(date.year, date.month, date.day)] = tasks;
    // }
    // _events = newEvents;
    // notifyListeners();
  }
  

  Future<void> loadCategories() async {
    _selectedCategory = 'All';
    notifyListeners();
  }

  void setCurrentView(String view) {
    _currentView = view;
    if (view == 'month') {
      _calendarFormat = CalendarFormat.month;
    } else if (view == 'week') {
      _calendarFormat = CalendarFormat.week;
    }
    loadEvents();
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    loadEvents();
    notifyListeners();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    if (_currentView == 'day') {
      _selectedTime = TimeOfDay.now();
    }
    loadEvents();
    notifyListeners();
  }

  List<Task> getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    final tasks = _events[normalizedDate] ?? [];
    
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return tasks;
    }
    return tasks.where((task) => task.category == _selectedCategory).toList();
  }

  void showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter by Category', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(category),
                    onSelected: (selected) {
                      _selectedCategory = selected ? category : null;
                      notifyListeners();
                      Navigator.pop(context);
                    },
                    backgroundColor: theme.cardColor,
                    selectedColor: getCategoryColor(category),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return const Color(0xFF78A1E8);
      case 'personal':
        return const Color(0xFFF5AC3D);
      case 'health':
        return const Color(0xFF4CAF50);
      case 'learning':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }
}
*/