import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Example data (you can replace these with real data later)
    final todayClass = {
      'subject': 'Computer Networks',
      'time': '9:00 AM - 10:00 AM',
      'teacher': 'Mr. Rajesh Kumar',
      'room': 'Lab 204',
    };

    final nextClass = {
      'subject': 'Data Structures',
      'time': '10:15 AM - 11:15 AM',
      'teacher': 'Mrs. Priya Sharma',
      'room': 'Room 102',
    };

    final todaysTimetable = [
      {'subject': 'Computer Networks', 'time': '9:00 - 10:00'},
      {'subject': 'Data Structures', 'time': '10:15 - 11:15'},
      {'subject': 'Mathematics', 'time': '11:30 - 12:30'},
      {'subject': 'Python Lab', 'time': '1:30 - 3:30'},
    ];

    final attendance = {
      'overall': 92,
      'present': 46,
      'total': 50,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                "Hi, Muhammed 👋",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your schedule for today",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Today's Class Card
              _buildClassCard(
                title: "Today's Class",
                classInfo: todayClass,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),

              // Next Up Class Card
              _buildClassCard(
                title: "Next Up",
                classInfo: nextClass,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 24),

              // Today's Timetable
              Text(
                "Today's Timetable",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
                    return ListTile(
                      leading: const Icon(Icons.book, color: Colors.blueAccent),
                      title: Text(item['subject']!),
                      subtitle: Text(item['time']!),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Attendance Overview
              Text(
                "Attendance Overview",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStat(
                      "Overall",
                      "${attendance['overall']}%",
                    ),
                    _buildAttendanceStat(
                      "Present",
                      "${attendance['present']} days",
                    ),
                    _buildAttendanceStat(
                      "Total",
                      "${attendance['total']} days",
                    ),
                  ],
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
    required Map<String, String> classInfo,
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
          Text(
            "By ${classInfo['teacher']}",
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            "Room: ${classInfo['room']}",
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}
