import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/utils/app_info_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('about_us'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SplitSathi',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            FutureBuilder<String>(
              future: getIt<AppInfoService>().getVersionString(),
              builder: (context, snapshot) {
                return Text(
                  'version_label'.tr(args: [snapshot.data ?? '...']),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'about_us_description'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text('privacy_policy'.tr()),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  launchUrl(Uri.parse('https://your-privacy-policy-url.com')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text('terms_of_service'.tr()),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => launchUrl(Uri.parse('https://your-terms-url.com')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text('contact_us'.tr()),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  launchUrl(Uri.parse('mailto:your-email@example.com')),
            ),
          ],
        ),
      ),
    );
  }
}
