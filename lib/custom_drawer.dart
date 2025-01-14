import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parental_control.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  /// Logout işlemi
  Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Oturum bilgilerini temizle

      if (!context.mounted) return; // Context kontrolü

      // Kullanıcıyı SignInPage'e yönlendir ve tüm önceki rotaları temizle
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/signIn', (route) => false);
    } catch (e) {
      // Hata durumunda kullanıcıya mesaj göster
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          _buildGradientBackground(),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 95, 139, 251),
                            Color.fromARGB(255, 114, 206, 249)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Menu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Divider(
                            color: Colors.white70,
                            thickness: 1,
                          ),
                        ],
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      iconWidget: const Icon(Icons.person,
                          color: Color.fromARGB(255, 23, 194, 251), size: 28),
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context,
                      iconWidget: const Icon(Icons.settings,
                          color: Color.fromARGB(255, 50, 56, 48), size: 28),
                      title: 'Account Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/accountSettings');
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context,
                      iconWidget: const Icon(Icons.bar_chart,
                          color: Color.fromARGB(255, 249, 9, 181), size: 28),
                      title: 'Weekly Report',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/weeklyReport');
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context,
                      iconWidget: const Icon(
                        Icons.security,
                        color: Color.fromARGB(255, 255, 112, 2),
                        size: 28,
                      ),
                      title: 'Parental Control',
                      onTap: () async {
                        Navigator.pop(context);

                        final prefs = await SharedPreferences.getInstance();
                        final parentId = prefs.getInt('loggedInParentId');

                        if (parentId == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please log in again. Parent ID not found.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ParentalControlPage(
                                loggedInParentId: parentId,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                  ],
                ),
              ),
              _buildMenuItem(
                context,
                iconWidget:
                    const Icon(Icons.logout, color: Colors.red, size: 28),
                title: 'Logout',
                onTap: () async {
                  await logout(context);
                },
                isLogout: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 239, 239, 248),
            Color.fromARGB(255, 231, 234, 246)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required Widget iconWidget,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
      highlightColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color:
                    isLogout ? Colors.red : const Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.teal.withOpacity(0.5),
      thickness: 0.8,
      indent: 16,
      endIndent: 16,
    );
  }
}
