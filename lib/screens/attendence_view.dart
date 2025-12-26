import 'package:attendance_tracker_frontend/api_service.dart';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      // Format date as YYYY-MM-DD for API
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Make API call to get attendance for the selected date
      final body = await ApiService.get(kMyAttendanceByDate(dateStr));

      if (body == null) {
        setState(() {
          error = 'Failed to load attendance';
          isLoading = false;
        });
        return;
      }

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

  // Soft color palette
  static const Color primaryColor = Color(0xFF5B8A72); // Sage green
  static const Color surfaceColor = Color(0xFFF8F6F4); // Warm off-white
  static const Color textDark = Color(0xFF2D3436); // Charcoal
  static const Color textMuted = Color(0xFF636E72); // Gray

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Attendance",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Track your daily presence",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  // Date Navigator - Clean minimal style
                  const SizedBox(height: 20),
                  //
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _prevDay,
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            size: 24,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.black87,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                                _fetchAttendance();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: canGoNext ? _nextDay : null,
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            size: 24,
                            color: canGoNext
                                ? Colors.grey.shade600
                                : Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Body
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _fetchAttendance,
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

    if (isWeekend) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.weekend_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Weekend',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No classes scheduled',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Classes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'for ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: attendanceList.length,
      itemBuilder: (context, idx) => _buildAttendanceStrip(attendanceList[idx]),
    );
  }

  Widget _buildAttendanceStrip(PeriodAttendance period) {
    // Status styling
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (period.isFree) {
      statusColor = Colors.grey.shade500;
      statusBgColor = Colors.grey.shade300;
      statusIcon = Icons.coffee_rounded;
    } else {
      switch (period.status) {
        case 'present':
          statusColor = const Color(0xFF2E7D32);
          statusBgColor = const Color(0xFF4CAF50);
          statusIcon = Icons.check_rounded;
          break;
        case 'late':
          statusColor = const Color(0xFFE65100);
          statusBgColor = const Color(0xFFFF9800);
          statusIcon = Icons.access_time_rounded;
          break;
        case 'absent':
          statusColor = const Color(0xFFC62828);
          statusBgColor = const Color(0xFFEF5350);
          statusIcon = Icons.close_rounded;
          break;
        case 'leave':
          statusColor = const Color(0xFF1565C0);
          statusBgColor = const Color(0xFF42A5F5);
          statusIcon = Icons.event_busy_rounded;
          break;
        default:
          statusColor = Colors.grey.shade600;
          statusBgColor = Colors.grey.shade400;
          statusIcon = Icons.hourglass_empty_rounded;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Left status strip
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: statusBgColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${period.hour}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    statusIcon,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period.isFree ? "Free Period" : period.subjectName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: period.isFree
                                  ? Colors.grey.shade500
                                  : textDark,
                            ),
                          ),
                          if (!period.isFree &&
                              period.staffName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              period.staffName,
                              style: TextStyle(
                                fontSize: 13,
                                color: textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Status text
                    if (!period.isFree)
                      Text(
                        period.statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
