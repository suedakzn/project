import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'child_detail_page.dart';
import 'custom_drawer.dart';

class MyChildrenPage extends StatefulWidget {
  final int parentId;

  const MyChildrenPage({super.key, required this.parentId});

  @override
  State<MyChildrenPage> createState() => _MyChildrenPageState();
}

class _MyChildrenPageState extends State<MyChildrenPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> children = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    fetchChildren();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _controller.forward();
  }

  Future<void> fetchChildren() async {
    try {
      final apiUrl = Uri.parse('$baseUrl/children/${widget.parentId}');
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.containsKey('children')) {
          final childrenData =
              List<Map<String, dynamic>>.from(data['children']);
          if (!mounted) return;
          setState(() {
            children = childrenData;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No children found.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'Failed to load children profiles. Status Code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Children',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            const Color.fromARGB(255, 56, 176, 246), // Açık mavi ton
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          _buildGradientBackground(), // Dinamik arka plan
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    )
                  : children.isEmpty
                      ? Center(
                          child: Text(
                            'No children available.',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 18),
                          ),
                        )
                      : _buildChildrenGrid(),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    final gradientColors = children.isNotEmpty
        ? children.map((child) {
            if (child['card_color'] != null) {
              return Color(int.parse(child['card_color']));
            } else {
              return child['child_gender'] == 'Male'
                  ? const Color.fromARGB(255, 157, 216, 236) // Açık mavi
                  : const Color.fromARGB(255, 247, 226, 229); // Açık pembe
            }
          }).toList()
        : [
            const Color.fromARGB(255, 173, 216, 230), // Varsayılan mavi
            const Color.fromARGB(255, 255, 182, 193) // Varsayılan pembe
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildChildrenGrid() {
    return FadeTransition(
      opacity: _controller,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChildDetailPage(
                    childId: child['id'],
                    childName: child['child_name'] ?? 'Unknown',
                    childGender: child['child_gender'] ?? 'Unknown',
                  ),
                ),
              );
            },
            child: _buildChildCard(child),
          );
        },
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    Color cardColor = child['card_color'] != null
        ? Color(int.parse(child['card_color'])) // Backend'den gelen renk
        : (child['child_gender'] == 'Male'
            ? Colors.blueAccent // Erkek çocuk için mavi
            : Colors.pinkAccent); // Kız çocuk için pembe

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(
                child['child_image'],
              ),
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            child['child_name'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
