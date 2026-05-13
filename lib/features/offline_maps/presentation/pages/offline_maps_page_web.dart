import 'package:flutter/material.dart';

class OfflineMapsPage extends StatelessWidget {
  const OfflineMapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Offline maps not supported on web')),
    );
  }
}
