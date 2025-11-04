import 'dart:convert';

import 'package:attendance_tracker_frontend/constants.dart';
import 'package:attendance_tracker_frontend/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sign in",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Container(color: Colors.orange, width: 60, height: 2),
                  SizedBox(height: 30),
                  Text(
                    "Email",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _emailController,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      //  border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, size: 18.0),
                      hintText: 'Enter your Email',
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      //  border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key_rounded, size: 19.0),
                      hintText: 'Enter your Password',
                    ),
                  ),
                  SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text("Forgot Password?"),
                    ),
                  ),

                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _onClick(
                          _emailController.text,
                          _passwordController.text,
                        );
                      },
                      child: Text('LOGIN'),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text('Dont have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text('Sign Up'),
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

  Future<void> _onClick(String email, String password) async {
    final url = Uri.parse(kStudentLoginRoute);
    final body = jsonEncode({"email": email, "password": password});
    final res = await post(
      url,
      body: body,

      headers: {"content-type": "application/json"},
    );
    print(res.body);

    if (res.statusCode == 200) {
      final parsedBody = jsonDecode(res.body);

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('jwt_token', parsedBody['data']['token']);
    }
  }
}


// afrad@gmail.com
// password