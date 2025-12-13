import 'dart:convert';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reset Password",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(color: Colors.orange, width: 60, height: 2),
                  const SizedBox(height: 16),
                  const Text(
                    "Enter your email address and we'll send you a code to reset your password.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Email Label
                  const Text(
                    "Email",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // EMAIL FIELD
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
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

                  const SizedBox(height: 30),

                  // SEND CODE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onSubmit,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : const Text('SEND RESET CODE'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back to Login
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = Uri.parse(kForgotPasswordRoute);
    final body = jsonEncode({"email": _emailController.text.trim()});

    try {
      final res = await http.post(
        url,
        body: body,
        headers: {"content-type": "application/json"},
      );

      final parsedBody = jsonDecode(res.body);

      if (res.statusCode == 200 && parsedBody['success'] == true) {
        if (mounted) {
          _showSuccess(
            parsedBody['message'] ??
                "If an account with that email exists, a password reset code has been sent.",
          );

          // Navigate to reset password screen after a short delay
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const ResetPasswordScreen(),
              ),
            );
          }
        }
      } else {
        _showError(parsedBody['message'] ?? "Failed to send reset code");
      }
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
