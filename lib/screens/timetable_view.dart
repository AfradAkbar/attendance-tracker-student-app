import 'dart:convert';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TimetableCell {
  final String subjectName;
  final String staffName;

  TimetableCell({required this.subjectName, required this.staffName});
  bool get isFree => subjectName == '-' || subjectName.toLowerCase() == 'free';
}

class TimetableView extends StatefulWidget {
  const TimetableView({super.key});

  static const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  State<TimetableView> createState() => _TimetableViewState();
}

class _TimetableViewState extends State<TimetableView>
    with SingleTickerProviderStateMixin {
  Map<String, Map<int, TimetableCell>> timetable = {};
  int maxHours = 0;

  bool isLoading = true;
  String? error;

  late TabController tabController;
  late ValueNotifier<int> dayIndexNotifier;

  @override
  void initState() {
    super.initState();

    // Determine today's weekday
    final today = DateTime.now().weekday; // 1 = Mon ... 7 = Sun

    int initialIndex;
    if (today >= 1 && today <= 5) {
      initialIndex = today - 1;
    } else {
      initialIndex = 0; // Sat/Sun → Monday
    }

    dayIndexNotifier = ValueNotifier(initialIndex);

    tabController = TabController(
      length: TimetableView.days.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    // LISTEN to tab changes
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        dayIndexNotifier.value = tabController.index;
      }
    });

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
        final data = jsonDecode(res.body)['timetable'] as List<dynamic>?;

        if (data == null || data.isEmpty) {
          error = 'No timetable available.';
          isLoading = false;
          setState(() {});
          return;
        }

        timetable.clear();
        maxHours = 0;

        for (final day in TimetableView.days) {
          timetable[day] = {};
        }

        for (final item in data) {
          final dow = (item['dayOfWeek'] ?? item['day'])?.toInt();
          final hour = item['hour']?.toInt();

          if (dow == null || hour == null) continue;

          maxHours = hour > maxHours ? hour : maxHours;

          final dayName = TimetableView.days[dow - 1];
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

          timetable[dayName]![hour] = TimetableCell(
            subjectName: subject,
            staffName: staff,
          );
        }

        isLoading = false;
        setState(() {});
      } else {
        error = 'Failed to load timetable.';
        isLoading = false;
        setState(() {});
      }
    } catch (e) {
      error = 'Error: $e';
      isLoading = false;
      setState(() {});
    }
  }

  void nextDay() {
    if (tabController.index < TimetableView.days.length - 1) {
      tabController.animateTo(tabController.index + 1);
    }
  }

  void prevDay() {
    if (tabController.index > 0) {
      tabController.animateTo(tabController.index - 1);
    }
  }

  // Soft color palette
  static const Color primaryColor = Color(0xFF5B8A72); // Sage green
  static const Color surfaceColor = Color(0xFFF8F6F4); // Warm off-white
  static const Color textDark = Color(0xFF2D3436); // Charcoal
  static const Color textMuted = Color(0xFF636E72); // Gray

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: surfaceColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: surfaceColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(error!, style: TextStyle(color: textMuted)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _getTimeTable,
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Timetable",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your weekly schedule",
                    style: TextStyle(
                      fontSize: 15,
                      color: textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Sleek Day Selector
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 10),
              child: ValueListenableBuilder<int>(
                valueListenable: dayIndexNotifier,
                builder: (context, dayIndex, _) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: TimetableView.days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final isSelected = index == dayIndex;
                      final dayName = TimetableView.days[index];
                      final dayAbbrev = dayName.substring(0, 3);

                      return GestureDetector(
                        onTap: () {
                          tabController.animateTo(index);
                          dayIndexNotifier.value = index;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            dayAbbrev,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Timeline View
            Expanded(
              child: AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  final day = TimetableView.days[tabController.index];
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(day),
                      child: _buildTimelineView(day),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView(String day) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      itemCount: maxHours,
      itemBuilder: (context, idx) {
        final hour = idx + 1;
        final isLast = idx == maxHours - 1;
        return _buildTimelineItem(hour, timetable[day]![hour], isLast);
      },
    );
  }

  Widget _buildTimelineItem(int hour, TimetableCell? cell, bool isLast) {
    final isFree = cell == null || cell.isFree;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Minimal Timeline
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Text(
                  "$hour",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isFree ? Colors.grey.shade400 : textDark,
                  ),
                ),
                const SizedBox(height: 4),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFree ? Colors.transparent : Colors.grey.shade100,
                ),
                boxShadow: isFree
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: isFree
                  ? Row(
                      children: [
                        Icon(
                          Icons.coffee_rounded,
                          size: 16,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Free Period",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cell.subjectName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (cell.staffName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cell.staffName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
