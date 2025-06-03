import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/calendar/calendar_view_selector.dart';
import '../widgets/calendar/daily_calendar_view.dart';
import '../widgets/calendar/week_calendar_view.dart';
import '../widgets/calendar/month_calendar_view.dart';
import '../widgets/calendar/calendar_header.dart';
import '../widgets/task_creation_dialog.dart';
import '../providers/calendar_provider.dart';
import '../screens/task_dashboard_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/profile_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final calendarProvider = Provider.of<CalendarProvider>(context);
    
    return Scaffold(
      drawer: _buildDrawer(context, userProvider),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Calendar'),
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            forceElevated: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => calendarProvider.showFilterDialog(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: CalendarViewSelector(
              currentView: calendarProvider.currentView,
              onViewChanged: (context, view) => calendarProvider.setCurrentView(view),
            ),
          ),
          if (calendarProvider.currentView == 'week' || calendarProvider.currentView == 'month')
            SliverToBoxAdapter(child: CalendarHeader(
              focusedDay: calendarProvider.focusedDay,
              selectedDay: calendarProvider.selectedDay,
              onDaySelected: (context, selectedDay, focusedDay) => calendarProvider.onDaySelected(selectedDay, focusedDay),
            )),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ...(
            calendarProvider.currentView == 'day'
              ? [
                  DailyCalendarView(
                    focusedDay: calendarProvider.focusedDay,
                    onDayChanged: (context, day) => calendarProvider.setFocusedDay(day),
                  )
                ]
              : calendarProvider.currentView == 'week'
                  ? [SliverToBoxAdapter(child: WeekCalendarView(
                      focusedDay: calendarProvider.focusedDay,
                    ))]
                  : [SliverToBoxAdapter(child: MonthCalendarView(
                      focusedDay: calendarProvider.focusedDay,
                    ))]
          ),
          if (calendarProvider.currentView == 'week')
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => TaskCreationDialog(
              initialDate: calendarProvider.selectedDay,
              initialTime: calendarProvider.selectedTime,
            ),
          ).then((_) {
            calendarProvider.loadEvents();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserProvider userProvider) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.onPrimary,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userProvider.user?.displayName ?? 'User',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  userProvider.user?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.check_circle_outline,
            title: 'Tasks',
            selected: false,
            onTap: () => _navigateToScreen(context, const TaskDashboardScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Calendar',
            selected: true,
            onTap: () => _navigateToScreen(context, const CalendarScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart_outlined,
            title: 'Stats',
            selected: false,
            onTap: () => _navigateToScreen(context, const StatsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            selected: false,
            onTap: () => _navigateToScreen(context, const AchievementsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Profile',
            selected: false,
            onTap: () => _navigateToScreen(context, const ProfileScreen()),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Sign Out',
            selected: false,
            onTap: () {
              Navigator.pop(context);
              userProvider.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: onTap,
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) async {
    Navigator.pop(context);
    
    await Future.microtask(() {
      if (!context.mounted) return;
      if (ModalRoute.of(context)?.settings.name != screen.runtimeType.toString()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => screen,
            settings: RouteSettings(name: screen.runtimeType.toString()),
          ),
        );
      }
    });
  }
}