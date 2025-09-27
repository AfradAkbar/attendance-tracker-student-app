import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(),
                color: const Color.fromRGBO(187, 203, 215, 1),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muhammed Afrad Akbar ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(),
                  Text(
                    'BCA-2023-26',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text('Register No:23456'),
                  Text('Admission No:123456'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
