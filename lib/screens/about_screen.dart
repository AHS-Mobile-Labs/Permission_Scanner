import 'package:flutter/material.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/social_media_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'asset/icon/Permission Scanner.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permission Scanner',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Permission Scanner is a privacy-focused mobile app that helps you understand what permissions your installed apps are requesting and using.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textLight,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Social Media Section
            const Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            SocialMediaButton(
              label: 'Email: ahsmobilelabs@gmail.com',
              icon: Icons.mail_outline_rounded,
              url: 'mailto:ahsmobilelabs@gmail.com',
              backgroundColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFE63946),
            ),
            const SizedBox(height: 10),
            SocialMediaButton(
              label: 'Instagram @ahsmobilelabs',
              icon: Icons.camera_alt_outlined,
              url: 'https://instagram.com/ahsmobilelabs',
              backgroundColor: const Color(0xFFFDF6EE),
              iconColor: const Color(0xFFD946A6),
            ),
            const SizedBox(height: 10),
            SocialMediaButton(
              label: 'YouTube @AHSMobileLabs',
              icon: Icons.play_circle_outline_rounded,
              url: 'https://www.youtube.com/@AHSMobileLabs',
              backgroundColor: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 10),
            SocialMediaButton(
              label: 'X (Twitter) @ahsmobilelabs',
              icon: Icons.tag_outlined,
              url: 'https://twitter.com/ahsmobilelabs',
              backgroundColor: const Color(0xFFF3F4F6),
              iconColor: const Color(0xFF1F2937),
            ),
            const SizedBox(height: 10),
            SocialMediaButton(
              label: 'Linktree /ahsmobilelabs',
              icon: Icons.link_rounded,
              url: 'https://linktr.ee/ahsmobilelabs',
              backgroundColor: const Color(0xFFEFEDFD),
              iconColor: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 32),

            // QR Code Section
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'Scan to visit all links',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'asset/app image/Linktree QR code/ahsmobilelabs.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Linktree QR Code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                'Made with ❤️ by AHS Mobile Labs',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
