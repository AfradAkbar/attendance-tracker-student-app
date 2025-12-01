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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F8FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Center(child: Text(error!)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      // TOP AREA WITH NEXT / PREV
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ValueListenableBuilder<int>(
            valueListenable: dayIndexNotifier,
            builder: (context, dayIndex, _) {
              return Row(
                children: [
                  IconButton(
                    onPressed: prevDay,
                    icon: const Icon(Icons.chevron_left, size: 30),
                  ),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        TimetableView.days[dayIndex],
                        key: ValueKey(TimetableView.days[dayIndex]),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: nextDay,
                    icon: const Icon(Icons.chevron_right, size: 30),
                  ),
                ],
              );
            },
          ),
        ),
      ),

      // BODY WITH PREMIUM ANIMATIONS
      body: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          final day = TimetableView.days[tabController.index];

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final isForward = tabController.index > dayIndexNotifier.value;

              final slideTween = Tween<Offset>(
                begin: Offset(isForward ? 0.15 : -0.15, 0),
                end: Offset.zero,
              );

              final scaleTween = Tween<double>(
                begin: 0.97,
                end: 1.0,
              );

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slideTween.animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutExpo,
                    ),
                  ),
                  child: ScaleTransition(
                    scale: scaleTween.animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              key: ValueKey(day),
              child: _buildDayView(day),
            ),
          );
        },
      ),
    );
  }

  // BUILD A DAY'S PERIOD LIST
  Widget _buildDayView(String day) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: maxHours,
      itemBuilder: (context, idx) {
        final hour = idx + 1;
        return _buildPeriodCard(hour, timetable[day]![hour]);
      },
    );
  }

  // CARD UI
  Widget _buildPeriodCard(int hour, TimetableCell? cell) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Row
          Row(
            children: [
              Text(
                "Period $hour",
                style: TextStyle(
                  color: Colors.indigo.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.indigo.shade400,
                  decorationThickness: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (cell == null || cell.isFree)
            Row(
              children: [
                const Icon(Icons.hourglass_empty, color: Colors.grey, size: 24),
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
            Row(
              children: [
                const Icon(Icons.book, color: Colors.indigo, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cell.subjectName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Colors.black54,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  cell.staffName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
