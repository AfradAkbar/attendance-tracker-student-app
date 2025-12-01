import 'dart:convert';

import 'package:attendance_tracker_frontend/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data model for a single period's attendance
class PeriodAttendance {
  final int hour;
  final String subjectName;
  final String staffName;
  final String?
  status; // 'present', 'absent', 'late', 'leave', or null (not marked)

  PeriodAttendance({
    required this.hour,
    required this.subjectName,
    required this.staffName,
    this.status,
  });

  /// Check if this is a free period
  bool get isFree => subjectName == '-' || subjectName.toLowerCase() == 'free';

  /// Get color based on status
  /// Green = present/late, Red = absent, Grey = not marked, Blue = leave
  Color get statusColor {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get status text
  String get statusText {
    if (status == null) return 'Not Marked';
    switch (status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      case 'leave':
        return 'On Leave';
      default:
        return 'Not Marked';
    }
  }

  /// Get status icon
  IconData get statusIcon {
    if (status == null) return Icons.hourglass_empty;
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      case 'leave':
        return Icons.event_busy;
      default:
        return Icons.hourglass_empty;
    }
  }
}

class AttendenceView extends StatefulWidget {
  const AttendenceView({super.key});

  @override
  State<AttendenceView> createState() => _AttendenceViewState();
}

class _AttendenceViewState extends State<AttendenceView> {
  // Selected date for viewing attendance
  DateTime selectedDate = DateTime.now();

  // List of attendance records for the selected date
  List<PeriodAttendance> attendanceList = [];

  // Loading state
  bool isLoading = true;

  // Error message if any
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  /// Fetch attendance data from the API for the selected date
  Future<void> _fetchAttendance() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        setState(() {
          error = 'Please login again.';
          isLoading = false;
        });
        return;
      }

      // Format date as YYYY-MM-DD for API
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Make API call to get attendance for the selected date
      final res = await http.get(
        Uri.parse(kMyAttendanceByDate(dateStr)),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];

        // Parse attendance records
        final List<PeriodAttendance> records = [];
        for (final item in data) {
          try {
            final hour = (item['hour'] as num?)?.toInt() ?? 0;

            // Get subject name
            String subjectName = 'Unknown Subject';
            if (item['subject'] is Map) {
              subjectName =
                  item['subject']['name']?.toString() ?? 'Unknown Subject';
            }

            // Get staff name
            String staffName = '';
            if (item['staff'] is Map) {
              staffName = item['staff']['name']?.toString() ?? '';
            }

            // Get attendance status (null if not marked)
            final status = item['attendance_status']?.toString();

            records.add(
              PeriodAttendance(
                hour: hour,
                subjectName: subjectName,
                staffName: staffName,
                status: status,
              ),
            );
          } catch (_) {
            // Skip malformed entries
          }
        }

        // Sort by hour
        records.sort((a, b) => a.hour.compareTo(b.hour));

        setState(() {
          attendanceList = records;
          isLoading = false;
        });
      } else if (res.statusCode == 401) {
        setState(() {
          error = 'Session expired. Please login again.';
          isLoading = false;
        });
      } else {
        // Try to parse error message from response
        String errorMsg = 'Failed to load attendance';
        try {
          final body = jsonDecode(res.body);
          errorMsg = body['message'] ?? errorMsg;
        } catch (_) {}
        setState(() {
          error = errorMsg;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error loading attendance: $e';
        isLoading = false;
      });
    }
  }

  /// Navigate to previous day
  void _prevDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
    _fetchAttendance();
  }

  /// Navigate to next day
  void _nextDay() {
    // Don't allow going to future dates
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (selectedDate.isBefore(tomorrow)) {
      setState(() {
        selectedDate = selectedDate.add(const Duration(days: 1));
      });
      _fetchAttendance();
    }
  }

  /// Check if can go to next day
  bool get canGoNext {
    final today = DateTime.now();
    return selectedDate.year < today.year ||
        (selectedDate.year == today.year && selectedDate.month < today.month) ||
        (selectedDate.year == today.year &&
            selectedDate.month == today.month &&
            selectedDate.day < today.day);
  }

  /// Format date for display
  String get formattedDate {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day) {
      return 'Today, ${DateFormat('MMM d').format(selectedDate)}';
    } else if (selectedDate.year == yesterday.year &&
        selectedDate.month == yesterday.month &&
        selectedDate.day == yesterday.day) {
      return 'Yesterday, ${DateFormat('MMM d').format(selectedDate)}';
    }
    return DateFormat('EEEE, MMM d, yyyy').format(selectedDate);
  }

  /// Check if selected date is a weekend
  bool get isWeekend {
    return selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      // TOP AREA WITH DATE NAVIGATION
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: _prevDay,
                icon: const Icon(Icons.chevron_left, size: 30),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    // Show date picker
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                      _fetchAttendance();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: canGoNext ? _nextDay : null,
                icon: Icon(
                  Icons.chevron_right,
                  size: 30,
                  color: canGoNext ? null : Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      ),

      // BODY
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchAttendance,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (isWeekend) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.weekend, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Weekend - No Classes',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (attendanceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'for ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: attendanceList.length,
      itemBuilder: (context, idx) {
        return _buildPeriodCard(attendanceList[idx]);
      },
    );
  }

  /// Build period card UI - similar to timetable but with attendance status
  Widget _buildPeriodCard(PeriodAttendance period) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        // Left border color based on attendance status
        border: Border(
          left: BorderSide(
            color: period.statusColor,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Period ${period.hour}",
                  style: TextStyle(
                    color: Colors.indigo.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.indigo.shade400,
                    decorationThickness: 1.5,
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: period.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: period.statusColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        period.statusIcon,
                        color: period.statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        period.statusText,
                        style: TextStyle(
                          color: period.statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (period.isFree)
              Row(
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    color: Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Free Period",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else ...[
              // Subject Row
              Row(
                children: [
                  const Icon(Icons.book, color: Colors.indigo, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      period.subjectName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              if (period.staffName.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Staff Row
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.black54,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      period.staffName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
