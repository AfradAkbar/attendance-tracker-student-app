import 'dart:convert';
import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
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
                    "Enter the 6-digit code sent to your email and your new password.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Token Label
                  const Text(
                    "Reset Code",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // TOKEN FIELD
                  TextFormField(
                    controller: _tokenController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      height: 2.5,
                      letterSpacing: 4,
                      fontSize: 18,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Reset code is required';
                      }
                      if (value.length != 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.pin, size: 18),
                      hintText: '000000',
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 30),

                  // New Password Label
                  const Text(
                    "New Password",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // NEW PASSWORD FIELD
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
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
                      prefixIcon: const Icon(Icons.lock, size: 18),
                      hintText: 'Enter new password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Confirm Password Label
                  const Text(
                    "Confirm Password",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // CONFIRM PASSWORD FIELD
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(height: 2.5),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      hintText: 'Confirm new password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // RESET PASSWORD BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onSubmit,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : const Text('RESET PASSWORD'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back to Login
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
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

    final url = Uri.parse(kResetPasswordRoute);
    final body = jsonEncode({
      "token": _tokenController.text.trim(),
      "newPassword": _passwordController.text.trim(),
    });

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
            parsedBody['message'] ?? "Password has been reset successfully",
          );

          // Navigate to login screen after a short delay
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } else {
        _showError(parsedBody['message'] ?? "Failed to reset password");
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
