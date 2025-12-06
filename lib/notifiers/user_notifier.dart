import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? dob;
  final String? imageUrl;
  final String? status;
  final String? address;
  final String? gender;
  final Map<String, dynamic>? batchId;
  final List<dynamic>? faceDescriptors;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.dob,
    this.imageUrl,
    this.status,
    this.address,
    this.gender,
    this.batchId,
    this.faceDescriptors,
  });

  // Factory constructor to create UserModel from API response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      dob: json['dob'],
      imageUrl: json['image_url'],
      status: json['status'],
      address: json['address'],
      gender: json['gender'],
      batchId: json['batch_id'],
      faceDescriptors: json['faceDescriptors'],
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'dob': dob,
      'image_url': imageUrl,
      'status': status,
      'address': address,
      'gender': gender,
      'batch_id': batchId,
      'faceDescriptors': faceDescriptors,
    };
  }
}

ValueNotifier<UserModel?> userNotifier = ValueNotifier(null);
