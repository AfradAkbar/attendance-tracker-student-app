import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'batch.dart';

@immutable
class BatchListResponse {
  final String? message;
  final List<Batch>? data;

  const BatchListResponse({this.message, this.data});

  @override
  String toString() => 'BatchListResponse(message: $message, data: $data)';

  factory BatchListResponse.fromJson(Map<String, dynamic> json) {
    return BatchListResponse(
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Batch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'data': data?.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    if (other is! BatchListResponse) return false;
    final mapEquals = const DeepCollectionEquality().equals;
    return mapEquals(other.toJson(), toJson());
  }

  @override
  int get hashCode => message.hashCode ^ data.hashCode;
}
