import 'dart:convert';

import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/notifiers/user_notifier.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Map<String, dynamic>> todaysTimetable = [];
  Map<String, dynamic>? currentClass;
  Map<String, dynamic>? nextClass;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchTodaysTimetable();
  }

  // Convert 12-hour time format to minutes from midnight
  int _timeToMinutes(String time12hr) {
    try {
      time12hr = time12hr.trim();
      print('[_timeToMinutes] Input: "$time12hr"');

      // Remove spaces and AM/PM
      final isAM = time12hr.toUpperCase().contains('AM');
      final isPM = time12hr.toUpperCase().contains('PM');

      // Remove all non-numeric and non-colon characters
      String timeOnly = time12hr.replaceAll(RegExp(r'[^0-9:]'), '');
      print('[_timeToMinutes] After removing non-numeric: "$timeOnly"');

      // Split by colon to get hours and minutes
      final timeParts = timeOnly.split(':');
      if (timeParts.length < 2) {
        print('[_timeToMinutes] Invalid format - parts: $timeParts');
        return 0;
      }

      int hour = int.tryParse(timeParts[0]) ?? 0;
      int minute = int.tryParse(timeParts[1]) ?? 0;

      print(
        '[_timeToMinutes] Parsed - hour: $hour, minute: $minute, isAM: $isAM, isPM: $isPM',
      );

      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }

      final result = hour * 60 + minute;
      print('[_timeToMinutes] Final result: $result minutes');
      return result;
    } catch (e) {
      print('[_timeToMinutes] Exception caught: $e');
      return 0;
    }
  }

  // Get day of week (1-5 for Monday-Friday)
  int _getDayOfWeek() {
    final now = DateTime.now();
    // Monday = 1, Sunday = 7
    // We want Monday = 1, Friday = 5
    return now.weekday <= 5 ? now.weekday : 1;
  }

  // Check if today is a weekend
  bool _isWeekend() {
    final now = DateTime.now();
    // Saturday = 6, Sunday = 7
    return now.weekday == 6 || now.weekday == 7;
  }

  // Get today's date in YYYY-MM-DD format
  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Calculate class time slots
  // Schedule:
  // Period 1: 9:30 AM - 10:30 AM
  // Period 2: 10:30 AM - 11:30 AM
  // Break: 11:30 AM - 11:40 AM (10 min)
  // Period 3: 11:40 AM - 12:40 PM
  // Break: 12:40 PM - 1:30 PM (50 min - lunch)
  // Period 4: 1:30 PM - 2:30 PM
  // Period 5: 2:30 PM - 3:30 PM
  String _getClassTime(int slotNumber) {
    final schedules = [
      '9:30 AM - 10:30 AM', // Period 1
      '10:30 AM - 11:30 AM', // Period 2
      '11:40 AM - 12:40 PM', // Period 3
      '1:30 PM - 2:30 PM', // Period 4
      '2:30 PM - 3:30 PM', // Period 5
    ];

    if (slotNumber >= 1 && slotNumber <= schedules.length) {
      return schedules[slotNumber - 1];
    }
    return '00:00 - 00:00';
  }

  Future<void> _fetchTodaysTimetable() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final dayOfWeek = _getDayOfWeek();
      final today = _getTodayDate();

      final url = Uri.parse('${kTimetableOfDay}/$dayOfWeek');

      final res = await http.get(
        url,
        headers: {
          'content-type': 'application/json',
          if (token.isNotEmpty) 'authorization': 'Bearer $token',
        },
      );

      print('[_fetchTodaysTimetable] ${res.statusCode} => ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final timetableList = data['timetable'] as List<dynamic>?;

        if (timetableList == null || timetableList.isEmpty) {
          setState(() {
            todaysTimetable = [];
            currentClass = null;
            nextClass = null;
            isLoading = false;
          });
          return;
        }

        // Sort by slot/hour
        final sorted = List<Map<String, dynamic>>.from(
          timetableList.map((item) => item as Map<String, dynamic>),
        );
        sorted.sort((a, b) => (a['hour'] ?? 0).compareTo(b['hour'] ?? 0));

        // Format timetable with readable times
        final formattedTimetable = sorted.map((item) {
          final slot = item['hour'] ?? 0;
          String subject = "-";
          String staff = "";

          if (item['subject_id'] is Map) {
            subject =
                (item['subject_id']['subject_name'] ??
                        item['subject_id']['name'] ??
                        item['subject_id']['code'] ??
                        "-")
                    .toString();
          }

          if (item['staff_id'] is Map) {
            staff = (item['staff_id']['name'] ?? '').toString();
          }

          return {
            'slot': slot,
            'subject': subject,
            'time': _getClassTime(slot),
            'staff': staff,
            'room': item['room'] ?? 'Classroom',
          };
        }).toList();

        // Determine current and next class based on current time
        final now = DateTime.now();
        final currentHour = now.hour;
        final currentMinute = now.minute;
        final currentTimeMinutes = currentHour * 60 + currentMinute;

        Map<String, dynamic>? current;
        Map<String, dynamic>? next;

        for (var i = 0; i < formattedTimetable.length; i++) {
          final classTime = formattedTimetable[i]['time'] as String;
          final times = classTime.split(' - ');
          final startTime = times[0].trim();
          final endTime = times[1].trim();

          final startMinutes = _timeToMinutes(startTime);
          final endMinutes = _timeToMinutes(endTime);

          if (startMinutes <= currentTimeMinutes &&
              currentTimeMinutes < endMinutes) {
            // Current class is happening now
            current = formattedTimetable[i];
          }
        }

        // Find next class after current or first class if none is current
        if (current != null) {
          for (var i = 0; i < formattedTimetable.length; i++) {
            if (formattedTimetable[i] == current &&
                i + 1 < formattedTimetable.length) {
              next = formattedTimetable[i + 1];
              break;
            }
          }
        } else {
          // No class is currently happening, find next upcoming class
          for (var i = 0; i < formattedTimetable.length; i++) {
            final classTime = formattedTimetable[i]['time'] as String;
            final times = classTime.split(' - ');
            final startTime = times[0].trim();
            final startMinutes = _timeToMinutes(startTime);

            if (startMinutes > currentTimeMinutes) {
              // This is the next upcoming class (current stays null)
              next = formattedTimetable[i];
              break;
            }
          }
        }

        setState(() {
          todaysTimetable = formattedTimetable;
          currentClass = current;
          nextClass = next;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load timetable.';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Soft pastel color palette
  static const Color primaryColor = Color(0xFF5B8A72); // Sage green
  static const Color accentColor = Color(0xFFE8B4A0); // Soft peach
  static const Color surfaceColor = Color(0xFFF8F6F4); // Warm off-white
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textDark = Color(0xFF2D3436); // Charcoal
  static const Color textMuted = Color(0xFF636E72); // Gray

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: surfaceColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: surfaceColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: accentColor),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(color: textDark, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(error!, style: TextStyle(color: textMuted, fontSize: 14)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _fetchTodaysTimetable,
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: surfaceColor,
      body: CustomScrollView(
        slivers: [
          // Soft Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 24,
                24,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  ValueListenableBuilder(
                    valueListenable: userNotifier,
                    builder: (context, user, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Good ${_getGreeting()},",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name ?? "Student",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isWeekend()
                        ? "Enjoy your weekend!"
                        : "Here's your schedule for today",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Only show current/next class cards on weekdays
                if (!_isWeekend())
                  Row(
                    children: [
                      Expanded(
                        child: currentClass != null
                            ? _buildCompactClassCard(
                                label: "Now",
                                classInfo: currentClass!,
                                bgColor: const Color(0xFFE8F5E9),
                                accentColor: primaryColor,
                              )
                            : _buildEmptyCard(
                                "No class now",
                                Icons.pause_circle_outlined,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: nextClass != null
                            ? _buildCompactClassCard(
                                label: "Next",
                                classInfo: nextClass!,
                                bgColor: const Color(0xFFFFF3E0),
                                accentColor: const Color(0xFFE65100),
                              )
                            : _buildEmptyCard(
                                "Done for today",
                                Icons.check_circle_outlined,
                              ),
                      ),
                    ],
                  ),
                // Show weekend message
                if (_isWeekend())
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.weekend_rounded,
                            size: 48,
                            color: primaryColor.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'It\'s the Weekend!',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Relax and recharge for the week ahead',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_isWeekend()) const SizedBox(height: 20),
                ValueListenableBuilder(
                  valueListenable: userNotifier,
                  builder: (context, user, _) {
                    final batch = user?.batchId;
                    if (batch == null) return const SizedBox.shrink();

                    // Access fields based on backend population
                    final classIncharge =
                        batch['class_incharge_id'] ?? batch['class_incharge'];

                    // Course might be in 'course' (virtual) or 'course_id' (explicit populate)
                    final course = batch['course_id'] ?? batch['course'];

                    // Department might be in 'department_id'
                    final department =
                        course?['department_id'] ?? course?['department'];

                    // HOD might be in 'hod_id'
                    final hod = department?['hod_id'] ?? department?['hod'];

                    if (classIncharge == null && hod == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person,
                                color: primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Faculty",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (classIncharge != null)
                              Expanded(
                                child: _buildFacultyItem(
                                  "Class Incharge",
                                  classIncharge is Map
                                      ? classIncharge['name'] ?? ''
                                      : classIncharge.toString(),
                                  Icons.person_rounded,
                                  const Color(0xFFE8F5E9),
                                  const Color(0xFF2E7D32),
                                ),
                              ),
                            if (classIncharge != null && hod != null)
                              const SizedBox(width: 16),
                            if (hod != null)
                              Expanded(
                                child: _buildFacultyItem(
                                  "HOD",
                                  hod is Map
                                      ? hod['name'] ?? ''
                                      : hod.toString(),
                                  Icons.admin_panel_settings_rounded,
                                  const Color(0xFFE3F2FD),
                                  const Color(0xFF1565C0),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                if (!_isWeekend()) const SizedBox(height: 30),

                // Today's Timetable Header (only on weekdays)
                if (!_isWeekend())
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                if (!_isWeekend()) const SizedBox(height: 16),

                // Timetable List (only on weekdays)
                if (!_isWeekend())
                  if (todaysTimetable.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No classes today',
                              style: TextStyle(color: textMuted, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: todaysTimetable.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final item = todaysTimetable[index];
                          final isCurrentClass =
                              currentClass != null &&
                              item['subject'] == currentClass!['subject'] &&
                              item['time'] == currentClass!['time'];
                          return _buildScheduleItem(item, isCurrentClass);
                        },
                      ),
                    ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildCompactClassCard({
    required String label,
    required Map<String, dynamic> classInfo,
    required Color bgColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            classInfo['subject'] ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12, color: textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  classInfo['time'] ?? '',
                  style: TextStyle(fontSize: 11, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (classInfo['staff'] != null &&
              classInfo['staff'].toString().isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.person_rounded, size: 12, color: textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    classInfo['staff'],
                    style: TextStyle(fontSize: 11, color: textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 22),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> item, bool isCurrentClass) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Period number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrentClass ? primaryColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "${item['slot']}",
                style: TextStyle(
                  color: isCurrentClass ? Colors.white : textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['subject']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['time']}',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          // Now badge
          if (isCurrentClass)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "NOW",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFacultyItem(
    String label,
    String name,
    IconData icon,
    Color bgColor,
    Color accentColor,
  ) {
    return Container(
      // padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3436),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
