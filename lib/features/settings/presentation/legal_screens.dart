import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_nav.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.privacyPolicy),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Text(AppStrings.privacyBody, style: TextStyle(height: 1.7)),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => goBack(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text(AppStrings.termsTitle),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.termsBody, style: TextStyle(height: 1.7)),
            SizedBox(height: 16),
            Text(
              AppStrings.noConfessionStored,
              style: TextStyle(height: 1.7, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
