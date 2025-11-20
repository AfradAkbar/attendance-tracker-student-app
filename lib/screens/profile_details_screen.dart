import 'package:flutter/material.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Column(
        children: [
          Center(
            child: Container(
              height: 80,
              width: 80,
              color: Colors.black,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          ListTile(
            leading: Text(
              'About you',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ListTile(
            leading: Text(
              "Name",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            trailing: Text(
              "afrad akbar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
