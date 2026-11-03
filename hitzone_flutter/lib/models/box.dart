/// A row of the Supabase `boxes` table (a bookable ground / net).
class CricketBox {
  const CricketBox({
    required this.id,
    required this.name,
    required this.active,
  });

  final String id;
  final String name;
  final bool active;

  factory CricketBox.fromMap(Map<String, dynamic> m) {
    return CricketBox(
      id: m['id'].toString(),
      name: (m['name'] ?? 'Box') as String,
      active: m['active'] == true,
    );
  }
}
