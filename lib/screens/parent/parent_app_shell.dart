import 'dart:async';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:attendance_tracker_frontend/api_service.dart';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/notifiers/user_notifier.dart';
import 'package:attendance_tracker_frontend/notifiers/notifications_notifier.dart';
import 'package:attendance_tracker_frontend/screens/attendence_view.dart';
import 'package:attendance_tracker_frontend/screens/notifications_view.dart';
import 'package:attendance_tracker_frontend/screens/parent/parent_profile_view.dart';
import 'package:flutter/material.dart';

class ParentAppShell extends StatefulWidget {
  const ParentAppShell({super.key});

  @override
  State<ParentAppShell> createState() => _ParentAppShellState();
}

class _ParentAppShellState extends State<ParentAppShell> {
  int _bottomNavIndex = 0;
  Timer? _notificationPollingTimer;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Polling interval in seconds
  static const int _pollingIntervalSeconds = 5;

  // Titles for each tab
  final titles = [
    'Attendance',
    'Notifications',
    'Profile',
  ];

  // Different page widgets
  final List<Widget> pages = [
    const AttendenceView(),
    const NotificationsView(),
    const ParentProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    print("ParentAppShell initState");
    _loadProfile();
    _loadNotifications();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationPollingTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    _notificationPollingTimer = Timer.periodic(
      const Duration(seconds: _pollingIntervalSeconds),
      (timer) => _loadNotifications(),
    );
  }

  Future<void> _loadProfile() async {
    final data = await _getProfileData();
    print("_loadProfile: $data");
    setState(() {
      userData = data?['user'];
      isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _getProfileData() async {
    try {
      final data = await ApiService.get(kMyDetails);

      if (data != null && data['user'] != null) {
        final user = data['user'] as Map<String, dynamic>;
        userNotifier.value = UserModel.fromJson(user);
        return data;
      }
    } catch (e) {
      print("ERROR: $e");
    }
    return null;
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.get(kNotifications);
      if (data != null && data['data'] != null) {
        final notifications = (data['data'] as List)
            .map(
              (json) =>
                  NotificationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        notificationsNotifier.setNotifications(notifications);
      }
    } catch (e) {
      print('[ParentAppShell] Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      bottomNavigationBar: Stack(
        children: [
          AnimatedBottomNavigationBar(
            icons: const [
              Icons.calendar_month,
              Icons.notifications_outlined,
              Icons.person,
            ],
            activeIndex: _bottomNavIndex,
            gapLocation: GapLocation.none,
            notchSmoothness: NotchSmoothness.defaultEdge,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey,
            onTap: (index) => setState(() => _bottomNavIndex = index),
          ),
          // Notification badge overlay
          ValueListenableBuilder<List<NotificationModel>>(
            valueListenable: notificationsNotifier,
            builder: (context, notifications, child) {
              final unreadCount = notifications.where((n) => !n.isRead).length;
              if (unreadCount == 0) return const SizedBox.shrink();

              // Calculate position for middle icon (index 1 of 3)
              // Center is at width * 0.5
              // Shift slightly right (+8) and up (top: 8)
              final notificationIconPosition =
                  MediaQuery.of(context).size.width * 0.5 + 6;

              return Positioned(
                left: notificationIconPosition,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[_bottomNavIndex]),
          ],
        ),
      ),
    );
  }
}
