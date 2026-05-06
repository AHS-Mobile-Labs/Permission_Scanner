import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_scanner/utils/app_colors.dart';
import 'package:permission_scanner/widgets/social_media_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ═══════════════════════════════════════════════════════════
            // HEADER SECTION - Enhanced
            // ═══════════════════════════════════════════════════════════
            Center(
              child: Column(
                children: [
                  // App Icon - Larger with enhanced shadow (Material 3 style)
                  Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'asset/icon/Permission Scanner.png',
                        width: 144,
                        height: 144,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Name - Bold and larger
                  const Text(
                    'Permission Scanner',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline - New section
                  const Text(
                    'Understand what your apps ask for',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Version Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ═══════════════════════════════════════════════════════════
            // ABOUT SECTION - Enhanced with mission statement
            // ═══════════════════════════════════════════════════════════
            _buildSectionCard(
              title: 'About',
              children: [
                const Text(
                  'Permission Scanner is a privacy-first, open-source tool built to help Android users understand what permissions their apps request and why.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textLight,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textLight,
                      height: 1.8,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Our Mission: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text:
                            'Transparency, privacy, and local-first data handling.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // KEY FEATURES - New section (2x2 Grid)
            // ═══════════════════════════════════════════════════════════
            _buildSectionCard(
              title: 'Key Features',
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildFeatureItem('🔍', 'Complete Scan'),
                    _buildFeatureItem('🎯', 'Risk Analysis'),
                    _buildFeatureItem('✅', 'Justification'),
                    _buildFeatureItem('📊', 'Database'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // SOCIAL MEDIA SECTION - Enhanced
            // ═══════════════════════════════════════════════════════════
            _buildSectionCard(
              title: 'Connect With Us',
              children: [
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
                const SizedBox(height: 10),
                SocialMediaButton(
                  label: 'GitHub - View Source',
                  icon: Icons.code_rounded,
                  url: 'https://github.com/AHS-Mobile-Labs/Permission_Scanner',
                  backgroundColor: const Color(0xFFF0F0F0),
                  iconColor: const Color(0xFF24292F),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // QR CODE SECTION - Fixed and styled
            // ═══════════════════════════════════════════════════════════
            _buildSectionCard(
              title: 'Quick Access',
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Scan to visit all links',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'asset/icon/qr_linktree.png',
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
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════
            // LEGAL & RESOURCES SECTION - New
            // ═══════════════════════════════════════════════════════════
            _buildSectionCard(
              title: 'Legal & Resources',
              children: [
                _buildLinkButton('Privacy Policy', () {
                  _launchUrl(
                    'https://github.com/AHS-Mobile-Labs/Permission_Scanner/blob/main/privacypolicy.txt',
                  );
                }),
                const SizedBox(height: 8),
                _buildLinkButton('License (MIT)', () {
                  _launchUrl(
                    'https://github.com/AHS-Mobile-Labs/Permission_Scanner/blob/main/LICENSE',
                  );
                }),
                const SizedBox(height: 8),
                _buildLinkButton('Report Issue', () {
                  _launchUrl(
                    'https://github.com/AHS-Mobile-Labs/Permission_Scanner/issues',
                  );
                }),
                const SizedBox(height: 8),
                _buildLinkButton('Star on GitHub', () {
                  _launchUrl(
                    'https://github.com/AHS-Mobile-Labs/Permission_Scanner',
                  );
                }),
              ],
            ),
            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════════
            // FOOTER
            // ═══════════════════════════════════════════════════════════
            Column(
              children: [
                const Text(
                  'Made with ❤️ by AHS Mobile Labs',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '© 2026 AHS Mobile Labs • Privacy First • Open Source',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper widget for section cards (Material 3 style)
  static Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // Helper widget for feature items
  static Widget _buildFeatureItem(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for link buttons
  static Widget _buildLinkButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
