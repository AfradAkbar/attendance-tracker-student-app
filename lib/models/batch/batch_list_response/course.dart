import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

@immutable
class Course {
  final String? id;
  final String? name;
  final String? departmentId;
  final int? v;

  const Course({this.id, this.name, this.departmentId, this.v});

  @override
  String toString() {
    return 'Course(id: $id, name: $name, departmentId: $departmentId, v: $v)';
  }

  factory Course.fromJson(Map<String, dynamic> json) => Course(
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
    if (other is! Course) return false;
    final mapEquals = const DeepCollectionEquality().equals;
    return mapEquals(other.toJson(), toJson());
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ departmentId.hashCode ^ v.hashCode;
}
