import 'dart:convert';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/screens/app_shell.dart';
import 'package:attendance_tracker_frontend/screens/forgot_password_screen.dart';
import 'package:attendance_tracker_frontend/screens/parent/parent_app_shell.dart';
import 'package:attendance_tracker_frontend/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool isParentLogin = false;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sign in",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(color: Colors.orange, width: 60, height: 2),
                  const SizedBox(height: 20),

                  // Parent / Student toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Login as Parent",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: isParentLogin,
                          onChanged: (value) {
                            setState(() {
                              isParentLogin = value;
                              _otpSent = false;
                              _passwordController.clear();
                              for (var c in _otpControllers) {
                                c.clear();
                              }
                            });
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Email label
                  const Text(
                    "Email",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Email input
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(height: 2.5),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email, size: 18),
                      hintText: 'Enter your Email',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Student login → Password
                  if (!isParentLogin) ...[
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      style: const TextStyle(height: 2.5),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.key_rounded, size: 19),
                        hintText: 'Enter your Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    // Parent login → OTP
                    if (!_otpSent) ...[
                      const Text(
                        "We'll send an OTP to your registered parent phone",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ] else ...[
                      const Text(
                        "Enter OTP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          return SizedBox(
                            width: 60,
                            height: 60,
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: "",
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 3) {
                                  _otpFocusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _otpFocusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),

                      TextButton(
                        onPressed: _isLoading ? null : _requestOTP,
                        child: const Text("Resend OTP"),
                      ),
                    ],
                  ],

                  if (!isParentLogin) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // LOGIN / SEND OTP BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isParentLogin
                                  ? (_otpSent ? "VERIFY OTP" : "SEND OTP")
                                  : "LOGIN",
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Signup only for students
                  if (!isParentLogin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text("Sign Up"),
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

  void _handleSubmit() {
    if (isParentLogin) {
      if (!_otpSent) {
        if (_emailController.text.trim().isEmpty) {
          _showError("Please enter student email");
        } else {
          _requestOTP();
        }
      } else {
        if (_otpValue.length == 4) {
          _verifyOTP();
        } else {
          _showError("Please enter complete OTP");
        }
      }
    } else {
      if (_formkey.currentState!.validate()) {
        _studentLogin();
      }
    }
  }

  Future<void> _requestOTP() async {
    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse(kParentRequestOTP),
        body: jsonEncode({"student_email": _emailController.text.trim()}),
        headers: {"content-type": "application/json"},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent to parent phone"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(data["message"] ?? "Failed to send OTP");
      }
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse(kParentVerifyOTP),
        body: jsonEncode({
          "student_email": _emailController.text.trim(),
          "otp": _otpValue,
        }),
        headers: {"content-type": "application/json"},
      );

      print(res.body);

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("jwt_token", data["token"]);
        prefs.setString("user_type", "parent");
        prefs.setString("student_id", data["user"]["_id"]);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ParentAppShell()),
          (route) => false,
        );
      } else {
        _showError(data["message"] ?? "Invalid OTP");
      }
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _studentLogin() async {
    setState(() => _isLoading = true);

    final body = jsonEncode({
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
    });

    try {
      final res = await http.post(
        Uri.parse(kStudentLoginRoute),
        body: body,
        headers: {"content-type": "application/json"},
      );

      final parsedBody = jsonDecode(res.body);
      print(res.body);
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('jwt_token', parsedBody['data']['token']);
        prefs.setString('student_id', parsedBody['data']['user']['_id']);
        prefs.setString('user_type', 'student');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      } else if (res.statusCode == 401) {
        _showError(parsedBody['message'] ?? 'Login failed');
      } else {
        _showError("Login failed");
      }
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    }

    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
