import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(trackingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar Alert'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Durum: ${controller.status}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (controller.lastSnapshot != null) ...[
                      Text(
                        'Konum: ${controller.lastSnapshot!.lat.toStringAsFixed(5)}, '
                        '${controller.lastSnapshot!.lon.toStringAsFixed(5)}',
                      ),
                      Text(
                        'Hız: ${(controller.lastSnapshot!.speedMps * 3.6).round()} km/s',
                      ),
                    ],
                    if (controller.activeCorridor != null)
                      Text(
                        'Aktif koridor oturumu: #${controller.activeCorridor!.corridorId}',
                      ),
                    if (controller.lastAlert != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Son uyarı: ${controller.lastAlert}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.isSyncing ? null : controller.syncData,
              icon: controller.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download),
              label: const Text('Bursa verisini senkronize et'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: controller.isRunning ? controller.stop : controller.start,
              icon: Icon(controller.isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(controller.isRunning ? 'Durdur' : 'Takibi Başlat'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Arka planda çalışırken Android bildirim çubuğunda kalıcı bir bildirim görünür. '
              'Pil optimizasyonunu kapatmanız önerilir.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
