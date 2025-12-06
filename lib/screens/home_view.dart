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
              current = formattedTimetable[i];
              if (i + 1 < formattedTimetable.length) {
                next = formattedTimetable[i + 1];
              }
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Center(
          child: Text('Error: $error'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              ValueListenableBuilder(
                valueListenable: userNotifier,
                builder: (context, user, child) {
                  if (user?.name == null) {
                    return const Icon(Icons.circle);
                  }
                  return Text(
                    "Welcome, ${user?.name}",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your schedule for today",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Current Class Card
              if (currentClass != null)
                _buildClassCard(
                  title: "Currently In",
                  classInfo: currentClass!,
                  color: Colors.blueAccent,
                )
              else
                _buildNoClassCard("No class right now"),
              const SizedBox(height: 16),

              // Next Up Class Card
              if (nextClass != null)
                _buildClassCard(
                  title: "Next Up",
                  classInfo: nextClass!,
                  color: Colors.orangeAccent,
                )
              else
                _buildNoClassCard("No more classes today"),
              const SizedBox(height: 24),

              // Today's Timetable
              Text(
                "Today's Timetable",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (todaysTimetable.isEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No classes scheduled for today'),
                  ),
                )
              else
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todaysTimetable.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = todaysTimetable[index];
                      final isCurrentClass =
                          currentClass != null &&
                          item['subject'] == currentClass!['subject'] &&
                          item['time'] == currentClass!['time'];
                      return ListTile(
                        leading: Icon(
                          Icons.book,
                          color: isCurrentClass
                              ? Colors.green
                              : Colors.blueAccent,
                        ),
                        title: Text(
                          item['subject']!,
                          style: TextStyle(
                            fontWeight: isCurrentClass
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrentClass ? Colors.green : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '${item['time']} • ${item['staff']}',
                          style: TextStyle(
                            color: isCurrentClass
                                ? Colors.green
                                : Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard({
    required String title,
    required Map<String, dynamic> classInfo,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            classInfo['subject'] ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            classInfo['time'] ?? '',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 2),
          if (classInfo['staff'] != null &&
              (classInfo['staff'] as String).isNotEmpty)
            Text(
              "By ${classInfo['staff']}",
              style: const TextStyle(color: Colors.black54),
            ),
          if (classInfo['room'] != null &&
              (classInfo['room'] as String).isNotEmpty)
            Text(
              "Room: ${classInfo['room']}",
              style: const TextStyle(color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildNoClassCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
    );
  }
}
