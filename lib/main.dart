import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'profile_page.dart';
import 'account_setting_page.dart';
import 'weekly_report_page.dart';
import 'parental_control.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Başlangıç rotası
      routes: {
        '/signIn': (context) => const SignInPage(),
        // Profil sayfası
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as int? ?? 0;
          return ProfilePage(userId: args);
        },
        '/accountSettings': (context) =>
            AccountSettingsPage(), // Hesap ayarları
        '/weeklyReport': (context) => WeeklyReportPage(), // Haftalık rapor
        '/parentalControl': (context) {
          // Bu satırda, gelen arguments'i (örneğin int türünde) alıyoruz
          final parentId = ModalRoute.of(context)!.settings.arguments as int;
          // Daha sonra bu parentId'yi sayfaya parametre olarak geçiyoruz
          return ParentalControlPage(loggedInParentId: parentId);
        },
      },
      home: const SignInPage(),
    );
  }
}
