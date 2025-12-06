import 'dart:convert';

import 'package:attendance_tracker_frontend/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // <-- incoming data

  const ProfileDetailsScreen({super.key, required this.userData});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  // controllers
  final TextEditingController fullName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController batch = TextEditingController();
  final TextEditingController dob = TextEditingController();
  final TextEditingController address = TextEditingController();
  String? image_url;

  String? gender;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() {
    final data = widget.userData;

    fullName.text = data["name"] ?? "";
    phone.text = "${data["phone_number"] ?? ""}";
    email.text = data["email"] ?? "";
    batch.text = data["batch_id"]?["name"] ?? "";
    image_url = data["image_url"] ?? "";

    final rawDob = data['dob'];
    if (rawDob != null) {
      if (rawDob is String) {
        dob.text = rawDob;
      } else if (rawDob is Map) {
        String? parsed;
        if (rawDob.containsKey(r'\$date'))
          parsed = rawDob[r'\$date']?.toString();
        if (parsed == null && rawDob.containsKey('date'))
          parsed = rawDob['date']?.toString();
        if (parsed != null) {
          try {
            dob.text = DateTime.parse(
              parsed,
            ).toIso8601String().split('T').first;
          } catch (_) {
            dob.text = parsed;
          }
        }
      } else {
        dob.text = rawDob.toString();
      }
    }
    address.text = data["address"] ?? "";
    // normalize gender to lowercase so it matches dropdown values
    final g = data["gender"];
    gender = g == null
        ? null
        : g.toString().toLowerCase(); // male / female / null

    setState(() {});
  }

  Widget buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            isDense: true,
            border: UnderlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 80),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: double.infinity,

              padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInput("Full Name", fullName),
                    buildInput("Phone Number", phone),
                    buildInput("Email", email),
                    buildInput("Batch", batch),
                    // Date of Birth picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Date of Birth",
                          style: TextStyle(fontSize: 16),
                        ),
                        TextField(
                          controller: dob,
                          readOnly: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: UnderlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            DateTime initialDate = DateTime(2000);
                            if (dob.text.isNotEmpty) {
                              try {
                                initialDate = DateTime.parse(dob.text);
                              } catch (_) {
                                // ignore parse error and keep fallback
                              }
                            }

                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate.isAfter(DateTime.now())
                                  ? DateTime.now()
                                  : initialDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );

                            if (picked != null) {
                              // format as YYYY-MM-DD
                              final formatted =
                                  '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              setState(() => dob.text = formatted);
                            }
                          },
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                    buildInput("Address", address),

                    const Text("Gender", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),

                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "male", child: Text("Male")),
                        DropdownMenuItem(
                          value: "female",
                          child: Text("Female"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => gender = value);
                      },
                    ),

                    const SizedBox(height: 28),

                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            _onClick();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            "Save",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ------------ PROFILE IMAGE ----------
            Positioned(
              left: 0,
              right: 0,
              top: -40,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        child: ClipOval(
                          child: image_url != null
                              ? Image.network(
                                  image_url!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.person, size: 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LOGIN FUNCTION
  Future<void> _onClick() async {
    final url = Uri.parse(kUpdateProfile);

    final name = fullName.text.trim();
    final emailVal = email.text.trim();
    final phoneVal = phone.text.trim();
    final dobVal = dob.text.trim();
    final addressVal = address.text.trim();
    final genderVal = gender;

    final bodyMap = <String, dynamic>{
      'name': name,
      'email': emailVal,
      'dob': dobVal,
      'phone_number': phoneVal,
      'gender': genderVal,
      'address': addressVal,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final res = await post(
        url,
        body: jsonEncode(bodyMap),
        headers: {
          'content-type': 'application/json',
          if (token.isNotEmpty) 'authorization': 'Bearer $token',
        },
      );

      // ignore: avoid_print
      print('[update profile] ${res.statusCode} ${res.body}');

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.of(context).pop(true);
      } else {
        String msg = 'Update failed';
        try {
          final parsed = jsonDecode(res.body) as Map<String, dynamic>;
          if (parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        _showError(msg);
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }
}
