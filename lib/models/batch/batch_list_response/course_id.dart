import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

@immutable
class CourseId {
  final String? id;
  final String? name;
  final String? departmentId;
  final int? v;

  const CourseId({this.id, this.name, this.departmentId, this.v});

  @override
  String toString() {
    return 'CourseId(id: $id, name: $name, departmentId: $departmentId, v: $v)';
  }

  factory CourseId.fromJson(Map<String, dynamic> json) => CourseId(
    id: json['_id'] as String?,
    name: json['name'] as String?,
    departmentId: json['department_id'] as String?,
    v: json['__v'] as int?,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'department_id': departmentId,
    '__v': v,
  };

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! CourseId) return false;
    final mapEquals = const DeepCollectionEquality().equals;
    return mapEquals(other.toJson(), toJson());
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ departmentId.hashCode ^ v.hashCode;
}
