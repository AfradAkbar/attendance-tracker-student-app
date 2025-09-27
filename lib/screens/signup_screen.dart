import 'package:attendance_tracker_frontend/screens/login_screen.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool passwordVisible = false;

  @override
  void initState() {
    super.initState();
    passwordVisible = true;
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
                    // controller: _emailController,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      //  border: OutlineInputBorder(),
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
                    // controller: _emailController,
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
                    // controller: _passwordController,
                    obscureText: passwordVisible,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      //  border: OutlineInputBorder(),
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
                    // controller: _emailController,
                    style: TextStyle(height: 2.5),
                    decoration: InputDecoration(
                      //  border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key_rounded, size: 19.0),
                      hintText: 'Confirm your Password',
                    ),
                  ),

                  SizedBox(height: 30),

                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // _onClick(
                        //   _emailController.text,
                        //   _passwordController.text,
                        // );
                      },
                      child: Text('Submit'),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
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
}
