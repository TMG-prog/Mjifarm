import 'package:flutter/material.dart';

class PestAlertPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pest Alerts")),
      body: Center(child: Text("Recent pest alerts and treatments")),
    );
  }
}
