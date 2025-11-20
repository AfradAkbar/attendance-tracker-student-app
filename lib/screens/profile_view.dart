import 'package:attendance_tracker_frontend/screens/profile_details_screen.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ProfileDetailsScreen();
                  },
                ),
              );
            },
            leading: Container(
              width: 70,
              height: 80,
              color: Colors.green,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AFRAD AKBAR'),
                Text('Department of Computer Science'),
                Text('BCA-2023-26'),
                Text('MO23BCAR19'),
              ],
            ),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Card(
          child: InkWell(
            onTap: () => {},
            child: ListTile(
              leading: Icon(Icons.supervisor_account),
              title: Text('Guardian'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Card(
          child: InkWell(
            onTap: () => {},
            child: ListTile(
              leading: Icon(Icons.description),
              title: Text('Admission Details'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Card(
          child: InkWell(
            onTap: () => {},
            child: ListTile(
              leading: Icon(Icons.money),
              title: Text(' Fees Structure'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Card(
          child: InkWell(
            onTap: () => {},
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text(' Logout'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }
}
