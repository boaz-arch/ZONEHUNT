import 'package:flutter/material.dart';

import 'session.dart';

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
      home: FutureBuilder<Widget>(
        future: resolveStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              !snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}