import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'my_child_page.dart';

class AddChildPage extends StatefulWidget {
  final int userId;

  const AddChildPage({super.key, required this.userId});

  @override
  AddChildPageState createState() => AddChildPageState();
}

class AddChildPageState extends State<AddChildPage> {
  List<Map<String, String>> children = [];

  String _getRandomIcon(String gender) {
    final random = Random();
    if (gender == 'Male') {
      return 'assets/male${random.nextInt(2) + 1}.png';
    } else {
      return 'assets/female${random.nextInt(2) + 1}.png';
    }
  }

  Future<void> _submitChildData(String name, int age, String gender) async {
    if (!mounted) return; // Check if the widget is still mounted

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_child'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
          "name": name,
          "age": age,
          "gender": gender,
        }),
      );

      if (!mounted) return; // Check if the widget is still mounted

      if (response.statusCode == 201) {
        setState(() {
          children.add({
            'name': name,
            'age': age.toString(),
            'gender': gender,
            'icon': _getRandomIcon(gender),
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add child: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted

      debugPrint('Error: $e'); // Use debugPrint instead of print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _addChild() {
    showDialog(
      context: context,
      builder: (context) {
        final childNameController = TextEditingController();
        final childAgeController = TextEditingController();
        String selectedGender = 'Male';

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text(
            'Add Child',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: childNameController,
                  decoration: InputDecoration(
                    labelText: 'Child Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: childAgeController,
                  decoration: InputDecoration(
                    labelText: 'Child Age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  items: ['Male', 'Female']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedGender = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (childNameController.text.trim().isEmpty ||
                    int.tryParse(childAgeController.text) == null ||
                    int.parse(childAgeController.text) <= 0) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter valid child details.')),
                    );
                  }
                  return;
                }
                await _submitChildData(
                  childNameController.text.trim(),
                  int.parse(childAgeController.text),
                  selectedGender,
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
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
        title: const Text(
          'Add Child',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          _buildGradientBackground(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: children.isEmpty
                      ? const Center(
                          child: Text(
                            'No children added yet! Please add at least one child.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: children.length,
                          itemBuilder: (context, index) {
                            final child = children[index];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 5,
                              child: ListTile(
                                title: Text(
                                  child['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text('Age: ${child['age']}'),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                if (children.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyChildrenPage(
                            parentId: widget.userId,
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      child: Text(
                        'Complete',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: _addChild,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFFFF9C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
