import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'care_card.dart';
import 'empty_state.dart';
import 'loading_state.dart';
import 'primary_button.dart';

/// A screen that must never be blank.
///
/// Every role screen renders through this so a failed or slow request always
/// produces a visible, actionable state instead of an empty surface.
class RoleAsyncView<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final bool isEmpty;
  final VoidCallback? onRetry;
  final String errorTitle;

  const RoleAsyncView({
    super.key,
    required this.loader,
    required this.builder,
    this.loading,
    this.emptyTitle = 'Nothing here yet',
    this.emptySubtitle = 'Records will appear here as soon as they exist.',
    this.emptyIcon = Icons.inbox_outlined,
    this.isEmpty = false,
    this.onRetry,
    this.errorTitle = 'Could not load this right now',
  });

  @override
  State<RoleAsyncView<T>> createState() => _RoleAsyncViewState<T>();
}

class _RoleAsyncViewState<T> extends State<RoleAsyncView<T>> {
  late Future<T> _future;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _reload() {
    setState(() {
      _error = null;
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loading ?? const LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorPane(
            title: widget.errorTitle,
            message: _messageFor(snapshot.error),
            onRetry: widget.onRetry ?? _reload,
          );
        }
        final data = snapshot.data as T;
        if (widget.isEmpty) {
          return EmptyState(
            icon: widget.emptyIcon,
            title: widget.emptyTitle,
            subtitle: widget.emptySubtitle,
            action: widget.onRetry == null
                ? null
                : TonalButton(
                    title: 'Refresh',
                    icon: Icons.refresh_rounded,
                    onPress: widget.onRetry ?? _reload,
                  ),
          );
        }
        return widget.builder(context, data);
      },
    );
  }

  String _messageFor(Object? error) {
    final raw = error.toString();
    if (raw.contains('401')) {
      return 'Your session has expired. Sign in again to continue.';
    }
    if (raw.contains('403')) {
      return 'Your role does not have access to this data.';
    }
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return 'No connection. Showing what is stored on this device.';
    }
    return raw.replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
  }
}

/// Inline error panel — never a blank surface.
class _ErrorPane extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorPane({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: CareCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coralWash,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    size: 28, color: AppColors.coralDeep),
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                message,
                style: GoogleFonts.manrope(
                    fontSize: 13, color: AppColors.inkMuted, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size(140, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section heading used across the role dashboards.
class RoleSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const RoleSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: AppColors.inkMuted, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Compact metric tile used by the console dashboards.
class RoleMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? caption;
  final VoidCallback? onTap;

  const RoleMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.teal,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CareCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
              height: 1.3,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: GoogleFonts.manrope(
                  fontSize: 11, color: AppColors.inkFaint, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single-line list row used by the console tables.
class RoleListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  final String? initials;
  final Color? avatarColor;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final Widget? trailingWidget;

  const RoleListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.initials,
    this.avatarColor,
    this.trailingIcon,
    this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CareCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (initials != null) ...[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (avatarColor ?? AppColors.teal).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                initials!,
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w800, color: avatarColor ?? AppColors.teal),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: AppColors.inkMuted, height: 1.35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailingWidget != null) ...[
            const SizedBox(width: 10),
            trailingWidget!,
          ] else if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              trailing!,
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
            ),
          ],
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            Icon(trailingIcon, size: 18, color: AppColors.inkFaint),
          ],
        ],
      ),
    );
  }
}
