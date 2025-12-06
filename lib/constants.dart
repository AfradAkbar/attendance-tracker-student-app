const kBaseUrl = 'http://192.168.1.20:3000/api';

const kStudentLoginRoute = '$kBaseUrl/student/login';

const kBatchListUrl = '$kBaseUrl/student/batch';

const kMyDetails = '$kBaseUrl/student/me';

const kUpdateProfile = '$kBaseUrl/student/update';

// Timetable endpoint
const kTimetable = '$kBaseUrl/timetable';
const kTimetableOfDay = '$kBaseUrl/timetable/day';

// Attendance endpoints (authenticated - uses JWT token, no student_id needed)
// Get my attendance for a specific date
String kMyAttendanceByDate(String date) =>
    '$kBaseUrl/attendance/my-attendance/date/$date';

// Get my attendance summary
String kMyAttendanceSummary({String? startDate, String? endDate}) =>
    '$kBaseUrl/attendance/my-attendance/summary${startDate != null && endDate != null ? '?start_date=$startDate&end_date=$endDate' : ''}';

// Legacy endpoints (for admin/staff use - requires student_id)
// Get attendance for a specific date: /student/{student_id}/date/{date}
String kStudentAttendanceByDate(String studentId, String date) =>
    '$kBaseUrl/attendance/student/$studentId/date/$date';

// Get attendance summary: /student/{student_id}/summary?start_date=&end_date=
String kStudentAttendanceSummary(
  String studentId, {
  String? startDate,
  String? endDate,
}) =>
    '$kBaseUrl/attendance/student/$studentId/summary${startDate != null && endDate != null ? '?start_date=$startDate&end_date=$endDate' : ''}';
