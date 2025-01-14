import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'add_child_page.dart';
import 'constants.dart';

class ParentInfoPage extends StatefulWidget {
  final int userId;
  static const String baseUrl = 'http://192.168.0.16:5000';

  const ParentInfoPage({super.key, required this.userId});

  @override
  State<ParentInfoPage> createState() => _ParentInfoPageState();
}

class _ParentInfoPageState extends State<ParentInfoPage> {
  final _formKey = GlobalKey<FormState>();

  // Form kontrolleri
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? _selectedCountry;
  String? _selectedGender;
  String _selectedCountryCode = "+90";

  final List<Map<String, String>> _countries = [
    {'name': 'Turkey', 'code': '+90'},
    {'name': 'United States', 'code': '+1'},
    {'name': 'Germany', 'code': '+49'},
    {'name': 'France', 'code': '+33'},
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];

  bool _isLoadingProfile = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Sayfa açılır açılmaz ebeveyn bilgilerini çek
    _loadParentInfo();
  }

  // Parent bilgilerini GET ile çekiyoruz.
  Future<void> _loadParentInfo() async {
    final url = Uri.parse('${ParentInfoPage.baseUrl}/parent/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Gelen veriyi form kontrollerine dolduruyoruz
        setState(() {
          _firstNameController.text = data['first_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
          _birthDateController.text = data['birth_date'] ?? '';
          _selectedCountry = data['country'];
          _selectedGender = data['gender'];
          _phoneNumberController.text = (data['phone_number'] != null)
              ? data['phone_number'].toString().split(" ").last
              : '';
          // Ülke seçilirse country code'u güncelliyoruz:
          if (_selectedCountry != null) {
            _selectedCountryCode = _countries.firstWhere(
                    (country) => country['name'] == _selectedCountry,
                    orElse: () => {'code': '+90'})['code'] ??
                '+90';
          }
          _isLoadingProfile = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
          _errorMessage =
              'Failed to load profile data. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // Tarih Seçici
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDateController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_birthDateController.text)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  // Ülkeye Göre Telefon Kodu Ayarı
  void _updateCountryCode(String? selectedCountry) {
    setState(() {
      _selectedCountry = selectedCountry;
      _selectedCountryCode = _countries.firstWhere(
              (country) => country['name'] == selectedCountry,
              orElse: () => {'code': '+90'})['code'] ??
          '+90';
    });
  }

  // Backend'e güncellenmiş ebeveyn bilgisini POST ile gönderme
  Future<void> submitParentInfo() async {
    try {
      final url = Uri.parse('$baseUrl/parent');
      final bodyData = json.encode({
        "user_id": widget.userId,
        "first_name": _firstNameController.text,
        "last_name": _lastNameController.text,
        "birth_date": _birthDateController.text,
        "country": _selectedCountry,
        "phone_number": '$_selectedCountryCode ${_phoneNumberController.text}',
        "gender": _selectedGender,
      });

      print("DEBUG -> POST to $url with body: $bodyData");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: bodyData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AddChildPage(userId: widget.userId),
            ),
          );
        }
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['error'] ??
                  'An error occurred while updating information.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Profil yükleniyorsa veya hata mesajı varsa bunları gösterelim
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Parent Info'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Parent Info'),
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Complete Parent Information',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextField('First Name', _firstNameController),
              _buildTextField('Last Name', _lastNameController),
              _buildDatePickerField('Birth Date', _birthDateController),
              _buildCountryDropdown(),
              _buildPhoneField(),
              _buildDropdownField('Gender', _genders, _selectedGender,
                  (value) => setState(() => _selectedGender = value)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    submitParentInfo();
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TextField Helper Widget
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  // Dropdown Helper Widget
  Widget _buildDropdownField(String label, List<String> items,
      String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(labelText: label),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  // Country Dropdown
  Widget _buildCountryDropdown() {
    return _buildDropdownField(
      'Country',
      _countries.map((country) => country['name']!).toList(),
      _selectedCountry,
      _updateCountryCode,
    );
  }

  // Phone Number Field with Country Code
  Widget _buildPhoneField() {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: TextFormField(
            readOnly: true,
            initialValue: _selectedCountryCode,
            decoration: const InputDecoration(labelText: 'Code'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            validator: (value) => value == null || value.length != 10
                ? 'Enter 10-digit phone number'
                : null,
          ),
        ),
      ],
    );
  }

  // DatePicker Field
  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select $label' : null,
      ),
    );
  }
}
