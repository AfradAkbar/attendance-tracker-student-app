import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:attendance_tracker_frontend/screens/attendence_view.dart';
import 'package:attendance_tracker_frontend/screens/login_screen.dart';
import 'package:attendance_tracker_frontend/screens/profile_view.dart';
import 'package:attendance_tracker_frontend/screens/timetable_view.dart';
import 'package:flutter/material.dart';
import 'package:attendance_tracker_frontend/screens/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _bottomNavIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_bottomNavIndex],
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => showLogoutModal(context),

          icon: Icon(Icons.logout),
        ),
        elevation: 0,
        centerTitle: true,
      ),

      // ❌ Removed FloatingActionButton and gap
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.none, // No gap since no button
        notchSmoothness: NotchSmoothness.defaultEdge,
        leftCornerRadius: 0,
        rightCornerRadius: 0,
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
