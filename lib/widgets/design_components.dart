import 'package:flutter/material.dart';
import '../theme/palette.dart';

class CircleAction extends StatelessWidget {
  const CircleAction({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.gradient = false,
    this.size = 52,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool gradient;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: gradient ? null : Colors.white.withValues(alpha: .8),
      gradient: gradient ? Palette.gradient : null,
      border: gradient ? null : Border.all(color: Palette.line),
    ),
    child: IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon, size: size > 60 ? 30 : 22),
      color: gradient ? Colors.white : Palette.ink,
    ),
  );
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Palette.lavender,
      borderRadius: BorderRadius.circular(28),
    ),
    child: child,
  );
}

class OutlinePill extends StatelessWidget {
  const OutlinePill({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: selected ? Palette.gradient : null,
      color: selected ? null : Palette.line,
    ),
    padding: const EdgeInsets.all(1),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Palette.muted),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String formatDuration(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    this.title,
    this.leading,
    required this.actions,
    required this.onBack,
  });
  final String? title;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      MediaQuery.sizeOf(context).width >= 1180 ? 56 : 26,
      20,
      24,
    ),
    child: Row(
      children: [
        leading ??
            CircleAction(
              icon: Icons.chevron_left_rounded,
              label: 'Go to notepad',
              onPressed: onBack,
            ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: -.5,
            ),
          ),
        ),
        ...actions,
      ],
    ),
  );
}
