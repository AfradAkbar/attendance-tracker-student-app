import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/models/batch/batch_list_response/batch.dart';
import 'package:attendance_tracker_frontend/models/batch/batch_list_response/batch_list_response.dart';
import 'package:attendance_tracker_frontend/screens/face_capture_screen.dart';
import 'package:attendance_tracker_frontend/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color primaryColor = Color(0xFF5B8A72);

  bool passwordVisible = false;
  bool _isSubmitting = false;

  List<Batch> _batches = [];
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  DateTime? _selectedDob;
  String? _selectedGender;

  // Profile photo (from gallery) - for display purposes
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Face verification images (from camera) - for attendance matching
  List<File> _faceImages = [];

  /// Pick profile photo from gallery only
  Future<void> _pickProfilePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      log('Image picker error: $e');
    }
  }

  /// Open face capture screen to take 3 face verification images
  Future<void> _captureFaceImages() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
    );

    if (result != null) {
      setState(() {
        _faceImages = List<File>.from(result['images'] ?? []);
      });
    }
  }

  void _getBatchesFromApi() async {
    print('get batches');
    try {
      final url = kBatchListUrl;
      final res = await get(Uri.parse(url));
      print('res ${res.statusCode}, ${res.body}');
      if (res.statusCode == 200) {
        final parsedBody = BatchListResponse.fromJson(jsonDecode(res.body));
        print(res);
        final batches = parsedBody.data;

        if (batches == null) {
          print('batches null');
          return;
        }

        setState(() {
          _batches = batches;
        });
        print(_batches);
      } else {
        log(res.toString());
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
    }
  }

  @override
  void initState() {
    passwordVisible = true;
    _getBatchesFromApi();
    super.initState();
  }

  String selectedValue = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2003, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        // Use YYYY-MM-DD format
        _dobController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final parentPhone = _parentPhoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final batchId = selectedValue;
    final dob = _dobController.text;

    // Validate all required fields
    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        batchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
        ),
      );
      return;
    }

    // Validate profile image
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a profile photo'),
        ),
      );
      return;
    }

    // Validate face verification images
    if (_faceImages.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture all 3 face verification images'),
        ),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isSubmitting = true);

    final url = '$kBaseUrl/student/signup';

    try {
      // Prepare JSON body
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'phone_number': phone,
        'parent_phone': parentPhone,
        'batch': batchId,
        'password': password,
      };
      if (dob.isNotEmpty) body['dob'] = dob;
      if (_selectedGender != null) body['gender'] = _selectedGender;

      // Convert profile image to base64
      try {
        final bytes = await _profileImage!.readAsBytes();
        final b64 = base64Encode(bytes);
        final dataUri = 'data:image/jpeg;base64,$b64';
        body['profile_image'] = dataUri;
      } catch (e) {
        log('Failed to read profile image bytes: $e');
      }

      // Convert face verification images to base64
      final faceImagesB64 = <String>[];
      for (final img in _faceImages) {
        try {
          final bytes = await img.readAsBytes();
          final b64 = base64Encode(bytes);
          faceImagesB64.add('data:image/jpeg;base64,$b64');
        } catch (e) {
          log('Failed to read face image bytes: $e');
        }
      }
      body['face_verification_images'] = faceImagesB64;

      // Note: Face descriptors are generated on the camera app side when verifying
      // The images uploaded here are downloaded by the camera app for registration

      // Send JSON request
      final response = await post(
        Uri.parse(url),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      );

      log('[signup] ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signup successful')));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        String msg = 'Signup failed';
        try {
          final parsed = jsonDecode(response.body) as Map<String, dynamic>;
          if (parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}

        // Show error dialog for duplicate errors
        if (response.statusCode == 409) {
          _showErrorDialog('Registration Error', msg);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      log('Signup error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Network error')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign up',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),

                  Container(color: Colors.orange, width: 60, height: 2),
                  SizedBox(height: 30),
                  Text(
                    "Name",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, size: 18.0),
                      hintText: 'Enter your Full Name',
                    ),
                  ),
                  SizedBox(height: 30),

                  Text(
                    "Email",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email, size: 18.0),
                      hintText: 'Enter your Email',
                    ),
                  ),
                  SizedBox(height: 30),

                  Text(
                    "Phone ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.phone, size: 18.0),
                      hintText: 'Enter your Phone number',
                    ),
                  ),
                  SizedBox(height: 30),

                  Text(
                    "Parent's Phone",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _parentPhoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.family_restroom, size: 18.0),
                      hintText: "Enter parent's phone number",
                    ),
                  ),
                  SizedBox(height: 30),

                  Text(
                    "Date of Birth",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _pickDob,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.cake, size: 18.0),
                      hintText: 'Select Date of Birth',
                    ),
                  ),
                  const SizedBox(height: 30),

                  Text(
                    "Gender",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownMenu<String>(
                    width: double.infinity,
                    inputDecorationTheme: const InputDecorationTheme(
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    hintText: "Select Gender",
                    leadingIcon: Icon(Icons.person_outline, size: 18),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'male', label: 'Male'),
                      DropdownMenuEntry(value: 'female', label: 'Female'),
                    ],
                    onSelected: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30),

                  Text(
                    "Batch",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  DropdownMenu(
                    width: double.infinity,
                    // Make dropdown look like TextField underline
                    inputDecorationTheme: const InputDecorationTheme(
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      // prefixIcon: Icon(Icons.list, size: 18),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),

                    hintText: "Select Batch",

                    dropdownMenuEntries: _batches
                        .map(
                          (e) => DropdownMenuEntry(
                            value: e.id,
                            label: e.name ?? '',
                          ),
                        )
                        .toList(),
                    onSelected: (value) {
                      setState(() {
                        selectedValue = value?.toString() ?? '';
                      });
                    },
                  ),

                  SizedBox(height: 30),
                  Text(
                    "Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  TextField(
                    controller: _passwordController,
                    obscureText: passwordVisible,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.key_rounded, size: 19.0),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(
                            () {
                              passwordVisible = !passwordVisible;
                            },
                          );
                        },
                      ),
                      hintText: 'Enter your Password',
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Confirm Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.key_rounded, size: 19.0),
                      hintText: 'Confirm your Password',
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ============ PROFILE PHOTO SECTION ============
                  _buildSectionHeader(
                    title: "Profile Photo",
                    subtitle: "This will be displayed on your profile",
                    icon: Icons.photo_library,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        if (_profileImage != null)
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade200,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _pickProfilePhoto,
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            _profileImage == null
                                ? 'Upload from Gallery'
                                : 'Change Photo',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ============ FACE VERIFICATION SECTION ============
                  _buildSectionHeader(
                    title: "Face Verification",
                    subtitle: "Capture 3 photos for attendance verification",
                    icon: Icons.face,
                  ),
                  const SizedBox(height: 10),

                  // Show captured face images or placeholder
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 3; i++)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: i < _faceImages.length
                                        ? primaryColor
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: i < _faceImages.length
                                      ? null
                                      : Colors.grey.shade200,
                                ),
                                child: i < _faceImages.length
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _faceImages[i],
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.camera_alt,
                                              color: Colors.grey,
                                            ),
                                            Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _captureFaceImages,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _faceImages.isEmpty
                                ? 'Capture Face Images'
                                : 'Retake Face Images',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor.withOpacity(0.2),
                            foregroundColor: primaryColor,
                          ),
                        ),
                        if (_faceImages.length == 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'All 3 images captured',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
