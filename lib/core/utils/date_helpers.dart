import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHelpers {
  static bool isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  static String formatDueDate(BuildContext context, DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (due.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else if (due.isBefore(today)) {
      return 'Overdue';
    } else {
      final differenceInDays = due.difference(today).inDays;
      if (differenceInDays == 1) {
        return '1 day';
      }
      if (differenceInDays < 7) {
        return '$differenceInDays days';
      } else {
        return DateFormat('MMM d').format(dueDate);
      }
    }
  }
} 