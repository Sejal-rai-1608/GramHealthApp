import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';

class ConnectivityBadge extends StatelessWidget {
  const ConnectivityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkStatus>(
      stream: ConnectivityService.instance.statusStream,
      initialData: ConnectivityService.instance.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? NetworkStatus.online;
        switch (status) {
          case NetworkStatus.online:
            return const SizedBox.shrink();
          case NetworkStatus.weak:
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.amberWash,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.amberPale),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.signal_wifi_bad, size: 14, color: AppColors.amberDeep),
                  const SizedBox(width: 6),
                  Text(
                    'Weak connection — audio preferred',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: AppColors.amberDeep,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            );
          case NetworkStatus.offline:
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.groundAlt,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 14, color: AppColors.inkMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Working offline — sync paused',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}
