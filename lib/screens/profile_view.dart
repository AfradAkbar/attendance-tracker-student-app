import 'package:attendance_tracker_frontend/screens/profile_details_screen.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        actions: [],
      ),

      body: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
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

                    _field(label: "Full Name", value: "AFRAD AKBAR"),
                    _field(
                      label: "Department",
                      value: "Department of Computer Science",
                    ),
                    _field(label: "Course", value: "BCA"),
                    _field(label: "Batch", value: "BCA - 2023-26"),
                    _field(label: "Register No", value: "MO23BCAR19"),

                    const SizedBox(height: 20),

                    _sectionTitle("Admission Details"),
                    _field(label: "Admission No", value: "ADM2023BCA019"),
                    _field(label: "Admission Date", value: "01-06-2023"),

                    const SizedBox(height: 20),

                    _sectionTitle("Guardian Details"),
                    _field(label: "Guardian Name", value: "Akbar"),
                    _field(label: "Phone", value: "9876543210"),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            const Positioned(
              left: 0,
              right: 0,
              top: -40,
              child: Center(child: _ProfileImage()),
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

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileDetailsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: const Center(
        child: Text("Edit Page"),
      ),
    );
  }
}
