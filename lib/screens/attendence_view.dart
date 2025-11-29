import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodAttendanceData {
  final String subjectName;
  final String time;
  final bool markedAsPresent;
  final bool hasStarted;

  PeriodAttendanceData({
    required this.markedAsPresent,
    required this.hasStarted,
    required this.subjectName,
    required this.time,
  });
}

final todaysTimetable = [
  PeriodAttendanceData(
    subjectName: 'python',
    time: '9:30 AM-10:30 AM',
    hasStarted: true,
    markedAsPresent: true,
  ),
  PeriodAttendanceData(
    subjectName: 'web',
    time: '10:30 AM-11:30 AM',
    hasStarted: true,
    markedAsPresent: true,
  ),
  PeriodAttendanceData(
    subjectName: 'maths',
    time: '11:45 AM-12:45 PM',
    hasStarted: true,
    markedAsPresent: true,
  ),
  PeriodAttendanceData(
    subjectName: 'english',
    time: '1:30 PM-2:30 PM',
    hasStarted: false,
    markedAsPresent: true,
  ),
  PeriodAttendanceData(
    subjectName: 'hindi',
    time: '2:30 PM-3:30 PM',
    hasStarted: false,
    markedAsPresent: true,
  ),
];

class AttendenceView extends StatefulWidget {
  const AttendenceView({super.key});

  @override
  State<AttendenceView> createState() => _AttendenceViewState();
}

class _AttendenceViewState extends State<AttendenceView> {
  DateTime selectDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    var color = Color.from(
      alpha: 1.0000,
      red: 0.9725,
      green: 0.9451,
      blue: 0.9804,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  final sel = await showDatePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (sel == null) {
                    return;
                  }
                  setState(() {
                    selectDate = sel;
                  });
                },
                icon: Icon(Icons.calendar_month),
              ),
              Text(DateFormat('MMM dd, yyyy').format(selectDate)),
            ],
          ),
          ListView.separated(
            shrinkWrap: true,

            itemBuilder: (context, index) {
              final periodData = todaysTimetable[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    tileColor: _getStatusColor(
                      isPresent: periodData.markedAsPresent,
                      isStarted: periodData.hasStarted,
                    ),
                    leading: _getStatusIcon(
                      isPresent: periodData.markedAsPresent,
                      isStarted: periodData.hasStarted,
                    ),
                    title: Text(periodData.subjectName),
                    subtitle: Text(periodData.time),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) {
              return Divider();
            },
            itemCount: todaysTimetable.length,
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon({required bool isPresent, required bool isStarted}) {
    if (isStarted) {
      if (isPresent) {
        return Icon(Icons.check_box);
      } else {
        return Icon(Icons.close);
      }
    } else {
      return Icon(Icons.timer);
    }
  }

  Color _getStatusColor({required bool isPresent, required bool isStarted}) {
    if (isStarted) {
      if (isPresent) {
        return Colors.lightGreen.shade100;
      } else {
        return Colors.red.shade200;
      }
    } else {
      return Colors.grey.shade300;
    }
  }
}
