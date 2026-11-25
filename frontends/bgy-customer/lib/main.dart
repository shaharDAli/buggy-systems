import 'package:flutter/material.dart';

void main() => runApp(const BuggyApp());

class BuggyApp extends StatelessWidget {
  const BuggyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Buggy',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF00584E),
      scaffoldBackgroundColor: const Color(0xFFFAF7F0),
    ),
    home: const CustomerHome(),
  );
}

const restaurants = [
  (
    name: 'Green Tiffin',
    initials: 'GT',
    tint: Color(0xFFDBEAC8),
    cuisine: 'South Indian',
    eta: '20–30 min',
    menu: ['Masala dosa · ₹110', 'Idli with sambar · ₹75'],
  ),
  (
    name: 'Oven Lane',
    initials: 'OL',
    tint: Color(0xFFF3D2BF),
    cuisine: 'Pizza',
    eta: '30–40 min',
    menu: ['Margherita · ₹240', 'Mushroom pizza · ₹290'],
  ),
  (
    name: 'Rice House',
    initials: 'RH',
    tint: Color(0xFFF2E1AA),
    cuisine: 'Rice bowls',
    eta: '25–35 min',
    menu: ['Vegetable bowl · ₹145', 'Chicken bowl · ₹185'],
  ),
];

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches = restaurants.where(
      (restaurant) => [
        restaurant.name,
        restaurant.cuisine,
        ...restaurant.menu,
      ].any((value) => value.toLowerCase().contains(query)),
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              children: [
                Text(
                  'Buggy',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 18),
                    SizedBox(width: 4),
                    Text('Indiranagar'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'What’s for lunch?',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) =>
                  setState(() => query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                labelText: 'Search restaurants or cuisines',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Nearby restaurants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final restaurant in matches)
              ExpansionTile(
                key: PageStorageKey(restaurant.name),
                tilePadding: EdgeInsets.zero,
                leading: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: restaurant.tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    restaurant.initials,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  restaurant.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${restaurant.cuisine} · ${restaurant.eta}'),
                children: [
                  for (final item in restaurant.menu)
                    ListTile(title: Text(item), dense: true),
                ],
              ),
            if (matches.isEmpty)
              const Text('No restaurants match your search.'),
          ],
        ),
      ),
    );
  }
}
