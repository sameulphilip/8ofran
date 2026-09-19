import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_nav.dart';
import '../../../core/utils/url_actions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand_mark.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.aboutPage),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        children: [
          const Center(child: BrandMark(size: 88)),
          const SizedBox(height: 16),
          const Center(child: BrandWordmark(size: 44)),
          const SizedBox(height: 20),
          AppCard(
            child: Text(
              AppStrings.aboutBody,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.75,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.supportAddress,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.serviceHours,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.contactUs),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: AppColors.accent),
            title: const Text(AppStrings.contactPhone),
            subtitle: const Text(AppStrings.supportPhone),
            onTap: UrlActions.callSupport,
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined, color: AppColors.accent),
            title: const Text(AppStrings.contactWhatsApp),
            onTap: UrlActions.whatsAppSupport,
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: AppColors.accent),
            title: const Text(AppStrings.contactEmail),
            subtitle: const Text(AppStrings.supportEmail),
            onTap: UrlActions.emailSupport,
          ),
        ],
      ),
    );
  }
}
