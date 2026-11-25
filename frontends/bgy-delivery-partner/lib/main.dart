import 'package:flutter/material.dart';

void main() => runApp(const DeliveryPartnerApp());

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Buggy Delivery Partner',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF00584E),
      scaffoldBackgroundColor: const Color(0xFFE9F1EC),
    ),
    home: const DeliveryHome(),
  );
}

enum DeliveryStage {
  available('Available pickups', 'Claim pickup', ''),
  claimed(
    'Your pickup',
    'Confirm pickup',
    'Pickup claimed. Collect order #1040 at Green Tiffin.',
  ),
  collected(
    'Your delivery',
    'Mark delivered',
    'Order collected. Deliver to 42 Lake Street.',
  ),
  delivered(
    'Available pickups',
    '',
    'Order #1040 delivered. No more pickups available.',
  );

  const DeliveryStage(this.heading, this.action, this.status);
  final String heading;
  final String action;
  final String status;
}

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({super.key});

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  DeliveryStage stage = DeliveryStage.available;

  @override
  Widget build(BuildContext context) {
    final next = stage == DeliveryStage.delivered
        ? null
        : DeliveryStage.values[stage.index + 1];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Buggy Delivery Partner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            Text(
              stage.heading,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            if (next != null)
              Card(
                color: Colors.white,
                margin: EdgeInsets.zero,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Order #1040',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      const _RouteStop(
                        icon: Icons.storefront,
                        label: 'Pickup',
                        place: 'Green Tiffin',
                        address: '12 Market Road',
                      ),
                      const Divider(height: 24),
                      const _RouteStop(
                        icon: Icons.location_on_outlined,
                        label: 'Drop-off',
                        place: '42 Lake Street',
                        address: 'Indiranagar',
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => setState(() => stage = next),
                        child: Text(stage.action),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Semantics(liveRegion: true, child: Text(stage.status)),
          ],
        ),
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.label,
    required this.place,
    required this.address,
  });
  final IconData icon;
  final String label;
  final String place;
  final String address;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(
              place,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(address),
          ],
        ),
      ),
    ],
  );
}
