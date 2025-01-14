import 'package:flutter/material.dart';

class SplashBackground extends StatefulWidget {
  const SplashBackground({Key? key}) : super(key: key);

  @override
  State<SplashBackground> createState() => _SplashBackgroundState();
}

class _SplashBackgroundState extends State<SplashBackground>
    with TickerProviderStateMixin {
  late final AnimationController _shipController;
  late final AnimationController _planeController;
  late final AnimationController _cloudController;
  late final AnimationController _fishController;

  late final Animation<double> _cloudAnimation;

  @override
  void initState() {
    super.initState();

    // GEMİ (SHIP) - sürekli soldan sağa
    _shipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: false);

    // UÇAK (PLANE) - sürekli soldan sağa
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: false);

    // BULUT (CLOUD) - örnek: ileri-geri kalsın (dilerseniz reverse: false yapabilirsiniz)
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: true);

    _cloudAnimation = Tween<double>(begin: -50, end: 50).animate(
      CurvedAnimation(
        parent: _cloudController,
        curve: Curves.easeInOut,
      ),
    );

    // BALIK (FISH) - sürekli soldan sağa
    _fishController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _shipController.dispose();
    _planeController.dispose();
    _cloudController.dispose();
    _fishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        /// Arkadaki degrade zemin
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue.shade300, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        /// Güneş
        Positioned(
          top: 30,
          left: 30,
          child: Image.asset('assets/sun.png', width: 100),
        ),

        /// Bulutlar (ileri-geri animasyon; dilerseniz siz de soldan sağa çevirebilirsiniz)
        AnimatedBuilder(
          animation: _cloudController,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: 50,
                  left: 30 + _cloudAnimation.value,
                  child: Image.asset('assets/cloud.png', width: 140),
                ),
                Positioned(
                  top: 80,
                  left: 200 - _cloudAnimation.value,
                  child: Image.asset('assets/cloud.png', width: 140),
                ),
                Positioned(
                  top: 150,
                  left: 100 + _cloudAnimation.value,
                  child: Image.asset('assets/cloud.png', width: 140),
                ),
                Positioned(
                  top: 160,
                  left: 250 - _cloudAnimation.value,
                  child: Image.asset('assets/cloud.png', width: 140),
                ),
                Positioned(
                  top: 170,
                  left: 50 + _cloudAnimation.value,
                  child: Image.asset('assets/cloud.png', width: 110),
                ),
              ],
            );
          },
        ),

        /// Deniz (mavi şerit)
        Positioned(
          bottom: 0,
          child: Container(
            height: 200,
            width: screenWidth,
            color: const Color.fromARGB(255, 35, 111, 199),
          ),
        ),

        /// GEMİ animasyonu (tek yönde soldan sağa)
        AnimatedBuilder(
          animation: _shipController,
          builder: (context, child) {
            // controller.value 0.0 -> 1.0
            // Ekran genişliğine +200 ekliyoruz, gemi önce soldan (ekran dışından) girsin ve sağdan tamamen çıksın.
            double cycle = _shipController.value * (screenWidth + 200);
            cycle = cycle % (screenWidth + 200);

            // -200 ile konumu hafif sola kaydırıyoruz (gemi ekrana girmeden önce görünmesin)
            return Positioned(
              bottom: 100,
              left: cycle - 200,
              child: Image.asset('assets/ship.png', width: 170),
            );
          },
        ),

        /// BALIK animasyonu (tek yönde soldan sağa)
        AnimatedBuilder(
          animation: _fishController,
          builder: (context, child) {
            double cycle = _fishController.value * (screenWidth + 150);
            cycle = cycle % (screenWidth + 150);

            return Positioned(
              bottom: 40,
              left: cycle - 150, // balık soldan başlasın
              child: Image.asset('assets/fishes.png', width: 100),
            );
          },
        ),

        /// UÇAK animasyonu (tek yönde soldan sağa)
        AnimatedBuilder(
          animation: _planeController,
          builder: (context, child) {
            double cycle = _planeController.value * (screenWidth + 140);
            cycle = cycle % (screenWidth + 140);

            return Positioned(
              top: 100,
              left: cycle - 140, // uçak soldan başlasın
              child: Image.asset('assets/airplane.png', width: 140),
            );
          },
        ),
      ],
    );
  }
}
