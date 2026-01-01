class AdminClassRoom {
  final int id;
  final String name;
  final String teacherName;

  AdminClassRoom({required this.id, required this.name, required this.teacherName});

  factory AdminClassRoom.fromJson(Map<String, dynamic> j) => AdminClassRoom(
        id: (j["id"] ?? 0) as int,
        name: (j["name"] ?? "") as String,
        teacherName: (j["teacher_name"] ?? "") as String,
      );
}

class AdminTeacher {
  final int teacherId;
  final int? userId;
  final String username;
  final bool active;
  final String fullName;
  final int? classId;
  final String className;

  AdminTeacher({
    required this.teacherId,
    required this.userId,
    required this.username,
    required this.active,
    required this.fullName,
    required this.classId,
    required this.className,
  });

  factory AdminTeacher.fromJson(Map<String, dynamic> j) => AdminTeacher(
        teacherId: (j["teacher_id"] ?? 0) as int,
        userId: j["user_id"] as int?,
        username: (j["username"] ?? "") as String,
        active: (j["active"] ?? true) as bool,
        fullName: (j["full_name"] ?? "") as String,
        classId: j["class_id"] as int?,
        className: (j["class_name"] ?? "") as String,
      );
}

class AdminStudent {
  final int studentId;
  final String code;
  final String fullName;
  final int? classId;
  final String className;
  final int? userId;
  final String username;
  final bool active;

  AdminStudent({
    required this.studentId,
    required this.code,
    required this.fullName,
    required this.classId,
    required this.className,
    required this.userId,
    required this.username,
    required this.active,
  });

  factory AdminStudent.fromJson(Map<String, dynamic> j) => AdminStudent(
        studentId: (j["student_id"] ?? 0) as int,
        code: (j["student_code"] ?? "") as String,
        fullName: (j["full_name"] ?? "") as String,
        classId: j["class_id"] as int?,
        className: (j["class_name"] ?? "") as String,
        userId: j["user_id"] as int?,
        username: (j["username"] ?? "") as String,
        active: (j["active"] ?? true) as bool,
      );
}

class TermItem {
  final int id;
  final String name;
  TermItem({required this.id, required this.name});
  factory TermItem.fromJson(Map<String, dynamic> j) => TermItem(
        id: (j["id"] ?? 0) as int,
        name: (j["name"] ?? "") as String,
      );
}

class SubjectItem {
  final int id;
  final String name;
  final double weight;
  SubjectItem({required this.id, required this.name, required this.weight});
  factory SubjectItem.fromJson(Map<String, dynamic> j) => SubjectItem(
        id: (j["id"] ?? 0) as int,
        name: (j["name"] ?? "") as String,
        weight: (j["weight"] ?? 1.0).toDouble(),
      );
}

class StudentItem {
  final int id;
  final String code;
  final String fullName;
  final int? classId;
  StudentItem({required this.id, required this.code, required this.fullName, required this.classId});
  factory StudentItem.fromJson(Map<String, dynamic> j) => StudentItem(
        id: (j["id"] ?? 0) as int,
        code: (j["student_code"] ?? "") as String,
        fullName: (j["full_name"] ?? "") as String,
        classId: j["class_id"] as int?,
      );
}

class RankingRow {
  final int studentId;
  final String code;
  final String fullName;
  final double average;
  final int? rank;
  RankingRow({required this.studentId, required this.code, required this.fullName, required this.average, required this.rank});
  factory RankingRow.fromJson(Map<String, dynamic> j) => RankingRow(
        studentId: (j["student_id"] ?? 0) as int,
        code: (j["student_code"] ?? "") as String,
        fullName: (j["full_name"] ?? "") as String,
        average: (j["average"] ?? 0).toDouble(),
        rank: j["rank"] as int?,
      );
}

class AttendanceItem {
  final int absent;
  final int permission;
  final String note;
  AttendanceItem({required this.absent, required this.permission, required this.note});
  factory AttendanceItem.fromJson(Map<String, dynamic> j) => AttendanceItem(
        absent: (j["absent"] ?? 0) as int,
        permission: (j["permission"] ?? 0) as int,
        note: (j["note"] ?? "") as String,
      );
}
