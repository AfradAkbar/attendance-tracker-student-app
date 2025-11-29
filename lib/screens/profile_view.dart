import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/screens/login_screen.dart';
import 'package:attendance_tracker_frontend/screens/profile_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _getProfileData();
    setState(() {
      userData = data?['user'];
      isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _getProfileData() async {
    final url = Uri.parse(kMyDetails);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    try {
      final res = await http.get(
        url,
        headers: {
          'content-type': 'application/json',
          if (token.isNotEmpty) 'authorization': 'Bearer $token',
        },
      );

      print('[_getProfileData] ${res.statusCode} => ${res.body}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("ERROR: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final batch = userData?['batch_id'];
    final course = batch?['course'];

    return isLoading
        ? Scaffold(
            backgroundColor: Colors.white,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            ),
          )
        : Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              backgroundColor: Colors.transparent,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),

                    onPressed: () async {
                      final isUpdated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileDetailsScreen(
                            userData: userData ?? {},
                          ),
                        ),
                      );
                      if (isUpdated) _loadProfile();
                    },
                  ),
                ),
              ],
            ),

            body: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),

                          // ===== BASIC INFO =====
                          if (userData?['name'] != null)
                            _field(
                              label: "Full Name",
                              value: userData!['name'].toString().toUpperCase(),
                            ),

                          if (userData?['email'] != null)
                            _field(label: "Email", value: userData!['email']),

                          if (userData?['phone_number'] != null)
                            _field(
                              label: "Phone",
                              value: userData!['phone_number'].toString(),
                            ),

                          // ===== ADDRESS =====
                          if (userData?['address'] != null)
                            _field(
                              label: "Address",
                              value: userData!['address'].toString(),
                            ),

                          // ===== COURSE FROM API =====
                          if (course?['name'] != null)
                            _field(
                              label: "Course",
                              value: course!['name'],
                            ), // Example: BCA
                          // ===== BATCH NAME =====
                          if (batch?['name'] != null)
                            _field(
                              label: "Batch",
                              value: batch!['name'],
                            ), // Example: BCA - 2026/2029

                          const SizedBox(height: 20),

                          // ===== GUARDIAN ONLY IF EXISTS =====
                          // if (userData?['guardian'] != null)
                          //   _sectionTitle("Guardian Details"),

                          // if (userData?['guardian']?['name'] != null)
                          //   _field(
                          //     label: "Guardian Name",
                          //     value: userData?['guardian']['name'],
                          //   ),

                          // if (userData?['guardian']?['phone'] != null)
                          //   _field(
                          //     label: "Guardian Phone",
                          //     value: userData!['guardian']['phone'].toString(),
                          //   ),

                          // const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 0,
                    right: 0,
                    top: -40,
                    child: Center(
                      // child: _ProfileImage(
                      //   userData: userData ?? {},
                      // ),
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
                            ),
                            // Positioned(
                            //   right: 8,
                            //   top: 8,
                            //   // child:
                            // ),
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

  Widget _field({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

void showLogoutModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // prevent closing by tapping outside
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                "Logout",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              const Text(
                "Are you sure you want to log out?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Logout button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


// class _ProfileImage extends StatelessWidget {
//   const _ProfileImage({super.key, required this.userData});

//   final Map<String, dynamic> userData;

//   @override
//   Widget build(BuildContext context) {
//     return
//   }
// }


