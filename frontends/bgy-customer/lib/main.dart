import 'package:flutter/material.dart';

void main() => runApp(const BuggyApp());

class BuggyApp extends StatelessWidget {
  const BuggyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Buggy';

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
                  const Icon(Icons.restaurant_menu, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Order food',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse restaurants, place an order, and follow its delivery.',
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
