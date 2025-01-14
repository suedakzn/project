import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class ImageProcessingPage extends StatefulWidget {
  final String? imagePath;
  const ImageProcessingPage({super.key, this.imagePath});

  @override
  _ImageProcessingPageState createState() => _ImageProcessingPageState();
}

class _ImageProcessingPageState extends State<ImageProcessingPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Confetti için controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Info butonuna tıklandığında açılacak açıklama popup'ı
  void _showInstructionsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'How to take a picture?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "scanning.json" animasyonu ekleniyor.
              Lottie.asset(
                'assets/animations/scanning.json',
                width: 150,
                height: 150,
                repeat: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please ensure that your entire beadwork is clearly visible in the frame. '
                'Hold your device steady, avoid glare, and use good lighting for the best results.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Görsel seçimi: Kamera veya Galeri
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _analyzeImage();
      } else {
        _showErrorDialog('No images have been selected.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while selecting the image: $e');
    }
  }

  // Flask API'ye görsel analizi için istek gönderme
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showErrorDialog('Please select an image.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedImagePath = _selectedImage!.path;

      const String apiUrl = 'http://192.168.0.16:5000/analyze_child_image';
      final url = Uri.parse(apiUrl);

      final request = http.MultipartRequest('POST', url)
        ..fields['label'] = 'correct_bead'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          selectedImagePath,
        ));

      final response =
          await request.send().timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final feedback = json.decode(responseData);
        _handleFeedback(feedback);
      } else {
        final errorMessage = await response.stream.bytesToString();
        _showErrorDialog(
          'Hata: Sunucu ${response.statusCode} kodu döndü. Detay: $errorMessage',
        );
      }
    } catch (e) {
      if (e is SocketException) {
        _showErrorDialog(
          'Could not connect to the server. Please check your internet connection.',
        );
      } else if (e is TimeoutException) {
        _showErrorDialog(
          'No response received from the server. Please try again later.',
        );
      } else {
        _showErrorDialog(
            'An error occurred while connecting to the server: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Analiz sonucuna göre işlem yapma
  void _handleFeedback(Map<String, dynamic> feedback) {
    if (feedback['status'] == 'success') {
      final details = feedback['feedback'] as List;
      final correct = details.where((d) => d['class'] == 'correct_bead').length;
      final missing = details.where((d) => d['class'] == 'missing_bead').length;
      final wrong = details.where((d) => d['class'] == 'wrong_bead').length;

      if (missing == 0 && wrong == 0) {
        _confettiController.play();
      }

      _showFeedbackPopup(correct, missing, wrong);
    } else {
      _showErrorDialog('The server returned an unexpected status.');
    }

    // Görseli geri bildirim sonrası kaldırma
    setState(() {
      _selectedImage = null;
    });
  }

  // Çocuk dostu geri bildirim popup'ı
  void _showFeedbackPopup(int correct, int missing, int wrong) {
    showDialog(
      context: context,
      builder: (context) {
        if (missing == 0 && wrong == 0) {
          // Başarılı durum
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: Column(
              children: [
                // Başarılı animasyonu
                Lottie.asset(
                  'assets/animations/image_processing_correct.json',
                  width: 150,
                  height: 150,
                  repeat: false,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: const Text(
              'All beads placed correctly!\nYou did a great job!',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Eksik veya yanlış boncuk durumu
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: Center(
              child: Lottie.asset(
                'assets/animations/image_processing_wrong.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Analysis Result',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      'Correct Bead: $correct',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                      'Missing Bead: $missing',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange),
                    const SizedBox(width: 10),
                    Text(
                      'Wrong Bead: $wrong',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'The beadwork is not placed correctly.\nPlease try again to correct the placement.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // Hata mesajını gösteren dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Error',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content:
              Text(message.isNotEmpty ? message : 'An unknown error occurred.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  // Kamera ve Galeri Seçim Modalı
  void _showImageSourceModal() {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Image.asset(
                  'assets/yellow_camera_button.png',
                  width: 30,
                  height: 30,
                ),
                title: const Text(
                  'Take Image with Camera',
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text(
                  'Select Image from Gallery',
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar içinde info butonu ekleniyor.
      appBar: AppBar(
        title: const Text('Scan Beadwork'),
        backgroundColor: const Color.fromARGB(255, 255, 190, 88),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructionsPopup,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 253, 247, 130),
              Color.fromARGB(255, 255, 190, 88),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti Animasyonu
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.red,
                Colors.purple
              ],
            ),
            // Görseli Ortaya Yerleştirme
            Positioned(
              top: 100,
              child: Center(
                child: Image.asset(
                  'assets/image-processing.png',
                  width: 250,
                  height: 250,
                ),
              ),
            ),
            // Button ve metni yerleştirme
            Positioned(
              bottom: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: Lottie.asset(
                              'assets/animations/image_processing_loading_button.json'),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'The image is being analyzed, please wait...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else if (_selectedImage != null)
                    Image.file(
                      _selectedImage!,
                      height: 200,
                    )
                  else
                    Column(
                      children: const [
                        SizedBox(height: 20),
                        Text(
                          'Upload or select an image',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 24.0),
                    child: ElevatedButton(
                      onPressed: _showImageSourceModal,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        'Select Image',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
