import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:attendance_tracker_frontend/api_service.dart';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/notifiers/user_notifier.dart';
import 'package:attendance_tracker_frontend/screens/attendence_view.dart';
import 'package:attendance_tracker_frontend/screens/profile_view.dart';
import 'package:attendance_tracker_frontend/screens/timetable_view.dart';
import 'package:flutter/material.dart';
import 'package:attendance_tracker_frontend/screens/home_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _bottomNavIndex = 0;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Icons for navigation items
  final iconList = <IconData>[
    Icons.home,
    Icons.schedule, // Timetable
    Icons.calendar_month, // Attendance
    Icons.person, // Profile
  ];

  // Titles for each tab
  final titles = [
    'Home',
    'Timetable',
    'Attendance',
    'Profile',
  ];

  // Different page widgets
  final List<Widget> pages = [
    const HomeView(),
    const TimetableView(),
    const AttendenceView(),
    const ProfileView(),
  ];

  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _getProfileData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.none, // No gap since no button
        notchSmoothness: NotchSmoothness.defaultEdge,
        // leftCornerRadius: 50,
        // rightCornerRadius: 50,
        activeColor: Colors.blueAccent,
        inactiveColor: Colors.grey,
        onTap: (index) => setState(() => _bottomNavIndex = index),
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
