import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AttendanceStatus { bannin, bannitla, bernathre }

class PeriodAttendanceData {
  final String subjectName;
  final String time;
  final AttendanceStatus status;

  PeriodAttendanceData({
    required this.subjectName,
    required this.time,
    required this.status,
  });
}

final todaysTimetable = [
  PeriodAttendanceData(
    subjectName: 'python',
    time: '9:30 AM-10:30 AM',
    status: AttendanceStatus.bannin,
  ),
  PeriodAttendanceData(
    subjectName: 'web',
    time: '10:30 AM-11:30 AM',
    status: AttendanceStatus.bannin,
  ),
  PeriodAttendanceData(
    subjectName: 'maths',
    time: '11:45 AM-12:45 PM',
    status: AttendanceStatus.bannitla,
  ),
  PeriodAttendanceData(
    subjectName: 'english',
    time: '1:30 PM-2:30 PM',
    status: AttendanceStatus.bernathre,
  ),
  PeriodAttendanceData(
    subjectName: 'hindi',
    time: '2:30 PM-3:30 PM',
    status: AttendanceStatus.bannin,
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
                    tileColor: _getStatusColor(todaysTimetable[index].status),
                    leading: _getStatusIcon(todaysTimetable[index].status),
                    title: Text(todaysTimetable[index].subjectName),
                    subtitle: Text(todaysTimetable[index].time),
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

  Widget _getStatusIcon(AttendanceStatus status) {
    if (status == AttendanceStatus.bannin) {
      return Icon(Icons.check);
    } else if (status == AttendanceStatus.bannitla) {
      return Icon(Icons.cancel);
    } else {
      return Icon(Icons.calendar_month);
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    if (status == AttendanceStatus.bannin) {
      return Colors.red.shade200;
    } else if (status == AttendanceStatus.bannitla) {
      return Colors.lightGreen.shade300;
    } else {
      return Colors.blue.shade300;
    }
  }
}
