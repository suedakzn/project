import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants.dart'; // baseUrl tanımlı

class ProfilePage extends StatefulWidget {
  final int userId; // parentId yerine userId kullanıyoruz

  const ProfilePage({required this.userId, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      // URL'yi query parametresi olarak user_id göndererek oluşturuyoruz.
      final response = await http.get(
        Uri.parse('$baseUrl/profile?user_id=${widget.userId}'),
      );

      // Yanıtı kontrol etmek için konsola yazdırıyoruz
      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profileData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load profile data. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Exception: $e');
      setState(() {
        errorMessage = 'Error fetching profile data: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parent Profile')),
        body: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Parent Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProfileRow('First Name', profileData?['first_name']),
            _buildProfileRow('Last Name', profileData?['last_name']),
            _buildProfileRow('Birth Date', profileData?['birth_date']),
            _buildProfileRow('Country', profileData?['country']),
            _buildProfileRow('Phone Number', profileData?['phone_number']),
            _buildProfileRow('Gender', profileData?['gender']),
          ],
        ),
      ),
    );
  }

  /// Profil bilgisini bir satır olarak gösterir.
  Widget _buildProfileRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value != null ? value.toString() : 'Not provided',
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
