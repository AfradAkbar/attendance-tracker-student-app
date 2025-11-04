import 'package:flutter/material.dart';

class TimetableView extends StatelessWidget {
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
                ...timeSlots.map(
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
            ...days.map((day) {
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
                  ...timeSlots.map((time) {
                    final index = timeSlots.indexOf(time);
                    final subject = timetable[day]?[index] ?? '-';
                    final isFree = subject.toLowerCase() == 'free';
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
            }).toList(),
          ],
        ),
      ),
    );
  }
}
