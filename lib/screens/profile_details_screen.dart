import 'package:attendance_tracker_frontend/api_service.dart';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/notifiers/user_notifier.dart';
import 'package:flutter/material.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // <-- incoming data

  const ProfileDetailsScreen({super.key, required this.userData});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  // Soft color palette
  static const Color primaryColor = Color(0xFF5B8A72); // Sage green
  static const Color surfaceColor = Color(0xFFF8F6F4); // Warm off-white

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
    final g = data["gender"];
    gender = g == null ? null : g.toString().toLowerCase();

    setState(() {});
  }

  Widget buildInput(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black54, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 24, 16),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                // spacing: 50,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: image_url != null && image_url!.isNotEmpty
                            ? Image.network(image_url!, fit: BoxFit.cover)
                            : Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Profile Image
            const SizedBox(height: 32),

            // Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInput("Full Name", fullName),
                    buildInput("Phone Number", phone),
                    buildInput("Email", email),
                    // buildInput("Batch", batch, readOnly: true),

                    // Date of Birth
                    Text(
                      "Date of Birth",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dob,
                      readOnly: true,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.black54,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      onTap: () async {
                        DateTime initialDate = DateTime(2000);
                        if (dob.text.isNotEmpty) {
                          try {
                            initialDate = DateTime.parse(dob.text);
                          } catch (_) {}
                        }

                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate.isAfter(DateTime.now())
                              ? DateTime.now()
                              : initialDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.black87,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          final formatted =
                              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          setState(() => dob.text = formatted);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    buildInput("Address", address),

                    // Gender
                    Text(
                      "Gender",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.black54,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500,
                      ),
                      items: const [
                        DropdownMenuItem(value: "male", child: Text("Male")),
                        DropdownMenuItem(
                          value: "female",
                          child: Text("Female"),
                        ),
                      ],
                      onChanged: (value) => setState(() => gender = value),
                    ),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _onClick(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATE PROFILE FUNCTION
  Future<void> _onClick() async {
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
      final parsed = await ApiService.post(kUpdateProfile, bodyMap);

      if (parsed != null && parsed['user'] != null) {
        print("Updating userNotifier with: ${parsed['user']}");
        try {
          userNotifier.value = UserModel.fromJson(parsed['user']);
          print("userNotifier updated. New name: ${userNotifier.value?.name}");
        } catch (e) {
          print("Error updating userNotifier: $e");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        _showError('Update failed');
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
