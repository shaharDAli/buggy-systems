import 'package:flutter/material.dart';

void main() => runApp(const DeliveryPartnerApp());

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Buggy Delivery Partner';

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF00584E)),
      home: Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.delivery_dining, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Manage deliveries',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find pickups, view your assignment, and update delivery status.',
                    textAlign: TextAlign.center,
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
