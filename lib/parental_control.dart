import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ParentalControlPage extends StatefulWidget {
  final int loggedInParentId;

  // Backend URL'si için sabit değişken
  static const String baseUrl = "http://192.168.0.16:5000";

  const ParentalControlPage({super.key, required this.loggedInParentId});

  @override
  State<ParentalControlPage> createState() => _ParentalControlPageState();
}

class _ParentalControlPageState extends State<ParentalControlPage> {
  /// Çocukları listelemek için GET isteği (loggedInParentId'ye göre)
  Future<List<Map<String, dynamic>>> fetchChildren() async {
    final url = Uri.parse(
      '${ParentalControlPage.baseUrl}/parental_control/children/${widget.loggedInParentId}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['children']);
    } else {
      throw Exception(
        'Failed to load children. Please check your network or server.',
      );
    }
  }

  /// Oyun limiti ayarlamak için POST isteği
  Future<void> setPlayLimit(int childId, int playLimit) async {
    final url = Uri.parse(
      '${ParentalControlPage.baseUrl}/parental_control/set_play_limit',
    );

    final bodyData = json.encode({
      "child_id": childId,
      "play_limit": playLimit,
    });

    print("DEBUG -> Setting play limit with body: $bodyData");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: bodyData,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set play limit. Please try again.');
    }
  }

  /// Oyun limiti düzenleme diyalog ekranı
  void _showPlayLimitDialog(
    BuildContext context,
    int childId,
    int currentLimit,
  ) {
    final playLimitController = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Play Limit'),
          content: TextField(
            controller: playLimitController,
            decoration: const InputDecoration(
              labelText: 'Play Limit (in minutes)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final playLimit = int.tryParse(playLimitController.text);
                if (playLimit == null || playLimit <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid play limit.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await setPlayLimit(childId, playLimit);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Play limit updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update play limit: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parental Control'),
        backgroundColor: const Color.fromARGB(255, 255, 112, 2),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchChildren(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Veri yüklenirken yükleniyor simgesi göster
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Hata durumunda daha açıklayıcı mesaj göster
            return Center(
              child: Text(
                'Error loading children: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Veri yoksa veya boşsa bilgi mesajı göster
            return const Center(
              child: Text(
                'No children found. Please add children in the system.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          } else {
            // Çocuklar başarıyla yüklendi
            final children = snapshot.data!;
            return ListView.builder(
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      child['child_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      'Play Limit: ${child['play_limit'] ?? 'None'} mins',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal),
                      onPressed: () {
                        _showPlayLimitDialog(
                          context,
                          child['id'],
                          child['play_limit'] ?? 0,
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
