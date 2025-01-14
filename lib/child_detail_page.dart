import 'package:flutter/material.dart';
import 'image_processing_page.dart';
import 'custom_drawer.dart'; // CustomDrawer widget'ını import ettik

class ChildDetailPage extends StatelessWidget {
  final int childId;
  final String childName;
  final String childGender; // Çocuğun cinsiyeti (Male veya Female)

  const ChildDetailPage({
    super.key,
    required this.childId,
    required this.childName,
    required this.childGender,
  });

  @override
  Widget build(BuildContext context) {
    // Tema renklerini cinsiyete göre belirliyoruz
    final Color primaryColor = childGender == 'Male'
        ? Colors.blueAccent // Erkek çocuk için mavi
        : Colors.pinkAccent; // Kız çocuk için pembe

    final Color gradientStartColor = childGender == 'Male'
        ? const Color(0xFFE3F2FD) // Açık mavi
        : const Color(0xFFFCE4EC); // Açık pembe

    final Color gradientEndColor = childGender == 'Male'
        ? const Color(0xFFBBDEFB) // Daha koyu mavi
        : const Color(0xFFF8BBD0); // Daha koyu pembe

    final List<Color> buttonColors = childGender == 'Male'
        ? [
            Colors.lightBlueAccent, // İlk buton için açık mavi
            Colors.indigoAccent, // İkinci buton için koyu mavi
            const Color.fromARGB(
                255, 27, 224, 224), // Üçüncü buton için turkuaz
          ]
        : [
            Colors.deepOrangeAccent, // İlk buton için pembe
            Colors.purpleAccent, // İkinci buton için turuncu
            Colors.pinkAccent, // Üçüncü buton için mor
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$childName\'s Page',
          style: const TextStyle(
            fontFamily: 'ComicSans',
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: primaryColor.withOpacity(0.7),
            height: 2.0,
          ),
        ),
      ),
      drawer: const CustomDrawer(), // Drawer widget olarak çağrıldı
      body: Stack(
        children: [
          _buildGradientBackground(gradientStartColor, gradientEndColor),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  _buildCardButton(
                    image: 'assets/yellow_camera_button.png',
                    title: 'Scan Beadwork ',
                    color: buttonColors[0], // İlk buton rengi
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImageProcessingPage(
                            imagePath: '', // Placeholder değer
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildCardButton(
                    image: 'assets/white_game_button.png',
                    title: 'Play Game',
                    color: buttonColors[1], // İkinci buton rengi
                    onTap: () {
                      // Oyun Sayfası
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildCardButton(
                    image: 'assets/report_button.png',
                    title: 'Weekly Summary',
                    color: buttonColors[2], // Üçüncü buton rengi
                    onTap: () {
                      // Haftalık rapor
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground(Color startColor, Color endColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildCardButton({
    required String image,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            color: color.withAlpha((0.9 * 255).toInt()),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Image.asset(
                image,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ComicSans',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
