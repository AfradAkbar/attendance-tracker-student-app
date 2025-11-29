import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'course.dart';
import 'course_id.dart';

@immutable
class Batch {
  final String? id;
  final CourseId? courseId;
  final int? startYear;
  final int? endYear;
  final int? strength;
  final int? v;
  final String? name;
  final Course? course;

  const Batch({
    this.courseId,
    this.startYear,
    this.endYear,
    this.strength,
    this.v,
    this.name,
    this.course,
    this.id,
  });

  @override
  String toString() {
    return 'Datum(courseId: $courseId, startYear: $startYear, endYear: $endYear, strength: $strength, v: $v, name: $name, course: $course, id: $id)';
  }

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
    id: json['_id'] as String?,
    courseId: json['course_id'] == null
        ? null
        : CourseId.fromJson(json['course_id'] as Map<String, dynamic>),
    startYear: json['start_year'] as int?,
    endYear: json['end_year'] as int?,
    strength: json['strength'] as int?,
    v: json['__v'] as int?,
    name: json['name'] as String?,
    course: json['course'] == null
        ? null
        : Course.fromJson(json['course'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'course_id': courseId?.toJson(),
    'start_year': startYear,
    'end_year': endYear,
    'strength': strength,
    '__v': v,
    'name': name,
    'course': course?.toJson(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! Batch) return false;
    final mapEquals = const DeepCollectionEquality().equals;
    return mapEquals(other.toJson(), toJson());
  }

  @override
  int get hashCode =>
      id.hashCode ^
      courseId.hashCode ^
      startYear.hashCode ^
      endYear.hashCode ^
      strength.hashCode ^
      v.hashCode ^
      name.hashCode ^
      course.hashCode;
}
