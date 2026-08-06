import 'package:flutter/material.dart';

void main() {
  runApp(const ZoneHuntApp());
}

class ZoneHuntApp extends StatelessWidget {
  const ZoneHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZoneHunt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZoneHunt'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ZONEHUNT',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Create Game'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Join Game'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}