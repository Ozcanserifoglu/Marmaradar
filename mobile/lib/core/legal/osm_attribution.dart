import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// OpenStreetMap copyright / ODbL notice.
/// See https://www.openstreetmap.org/copyright and OSMF Attribution Guidelines.
const kOsmCopyrightUrl = 'https://www.openstreetmap.org/copyright';
const kPrivacyUrl = 'https://www.marmaradar.com/gizlilik';
const kTermsUrl = 'https://www.marmaradar.com/kullanim-sartlari';

Future<bool> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
  } catch (_) {
    // Fall through to platform default.
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  }
}

/// Compact map-corner credit (interactive maps safe harbour).
class OsmMapAttribution extends StatelessWidget {
  const OsmMapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => openExternalUrl(kOsmCopyrightUrl),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Kamera verisi © OpenStreetMap',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile / About block with OSM credit and legal links (opens marmaradar.com).
class LegalCreditsSection extends StatelessWidget {
  const LegalCreditsSection({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final ok = await openExternalUrl(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant, fontSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Veri ve yasal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'EDS / koridor kamera verilerinin bir kısmı OpenStreetMap katkıcılarından '
          'alınmıştır ve Open Database License (ODbL) altındadır.',
          style: muted,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 0,
          children: [
            TextButton(
              onPressed: () => _open(context, kPrivacyUrl),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Gizlilik'),
            ),
            TextButton(
              onPressed: () => _open(context, kTermsUrl),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Kullanım Şartları'),
            ),
            TextButton(
              onPressed: () => _open(context, kOsmCopyrightUrl),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('© OpenStreetMap'),
            ),
          ],
        ),
      ],
    );
  }
}
