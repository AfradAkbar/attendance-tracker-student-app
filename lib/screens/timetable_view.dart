import 'dart:convert';

import 'package:attendance_tracker_frontend/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TimetableView extends StatefulWidget {
  const TimetableView({super.key});

  static const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  static const timeSlots = [
    '9:00 - 10:00',
    '10:15 - 11:15',
    '11:30 - 12:30',
    '1:30 - 2:30',
    '2:30 - 3:30',
  ];

  static const timetable = {
    'Monday': ['Math', 'Physics', 'English', 'Lab', 'PE'],
    'Tuesday': ['Computer', 'Math', 'Economics', 'Python', 'Free'],
    'Wednesday': ['English', 'Math', 'Physics', 'Python Lab', 'Free'],
    'Thursday': ['Data Structures', 'Computer', 'Math', 'AI', 'Free'],
    'Friday': ['AI', 'Math', 'English', 'Lab', 'Project'],
  };

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView> {
  // 5 days x 5 slots grid (default '-')
  List<List<String>> grid = List.generate(
    TimetableView.days.length,
    (_) => List.generate(TimetableView.timeSlots.length, (_) => '-'),
  );

  bool isLoading = true;
  String? error;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getTimeTable();
  }

  Future<void> _getTimeTable() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final res = await http.get(
        Uri.parse(kTimetable),
        headers: {
          'content-type': 'application/json',
          if (token.isNotEmpty) 'authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final timetable = body['timetable'] as List<dynamic>?;

        if (timetable == null || timetable.isEmpty) {
          setState(() {
            error = 'No timetable available for your batch.';
            isLoading = false;
          });
          return;
        }

        // Reset grid
        grid = List.generate(
          TimetableView.days.length,
          (_) => List.generate(TimetableView.timeSlots.length, (_) => '-'),
        );

        for (final item in timetable) {
          try {
            final day =
                (item['dayOfWeek'] as num?)?.toInt() ??
                (item['day'] as num?)?.toInt();
            final hour = (item['hour'] as num?)?.toInt();

            if (day == null || hour == null) continue;

            final dayIndex = day - 1; // API uses 1-5
            final hourIndex = hour - 1; // assume hour 1-5

            if (dayIndex < 0 || dayIndex >= grid.length) continue;
            if (hourIndex < 0 || hourIndex >= grid[0].length) continue;

            String subject = '-';
            if (item['subject_id'] is Map) {
              subject =
                  (item['subject_id']['name'] ??
                          item['subject_id']['code'] ??
                          '-')
                      .toString();
            } else if (item['subject_id'] != null) {
              subject = item['subject_id'].toString();
            }

            final staffName = item['staff_id'] is Map
                ? item['staff_id']['name']
                : null;
            if (staffName != null) {
              subject = '$subject (${staffName.toString()})';
            }

            grid[dayIndex][hourIndex] = subject;
          } catch (_) {
            // ignore malformed entries
          }
        }

        setState(() {
          isLoading = false;
        });
      } else if (res.statusCode == 401) {
        setState(() {
          error = 'Unauthorized. Please login again.';
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load timetable (${res.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading timetable: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const timeColumnWidth = 100.0;
    const dayColumnWidth = 150.0; // fixed width per day

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // horizontal scroll for days
        child: Row(
          children: [
            // Time Column + Subjects Table
            Column(
              children: [
                // Top-left empty corner
                Container(
                  width: timeColumnWidth,
                  height: 50,
                  color: Colors.blueAccent,
                  child: const Center(
                    child: Text(
                      'Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Time slots vertically
                ...TimetableView.timeSlots.map(
                  (time) => Container(
                    width: timeColumnWidth,
                    height: 50,
                    color: Colors.blueGrey.shade50,
                    alignment: Alignment.center,
                    child: Text(
                      time,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // Days Columns
            if (isLoading)
              Container(
                width: dayColumnWidth * TimetableView.days.length,
                height: TimetableView.timeSlots.length * 52.0,
                alignment: Alignment.center,
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Container(
                width: dayColumnWidth * TimetableView.days.length,
                padding: const EdgeInsets.all(24),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              )
            else
              ...List.generate(TimetableView.days.length, (dayIdx) {
                final day = TimetableView.days[dayIdx];
                return Column(
                  children: [
                    // Day header
                    Container(
                      width: dayColumnWidth,
                      height: 50,
                      color: Colors.blueAccent,
                      alignment: Alignment.center,
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Subjects for each time slot
                    ...List.generate(TimetableView.timeSlots.length, (slotIdx) {
                      final subject = grid[dayIdx][slotIdx] ?? '-';
                      final isFree =
                          subject.toLowerCase().contains('free') ||
                          subject == '-';
                      return Container(
                        width: dayColumnWidth,
                        height: 50,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isFree
                              ? Colors.greenAccent.withOpacity(0.3)
                              : Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          subject,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isFree
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isFree ? Colors.green[800] : Colors.black87,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}
