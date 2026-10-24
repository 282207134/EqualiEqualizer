import 'package:flutter/material.dart';

import 'theme.dart';

class NeuBox extends StatelessWidget {
  const NeuBox({
    super.key,
    required this.child,
    this.radius = 12,
    this.pressed = false,
    this.padding = EdgeInsets.zero,
    this.color,
  });
  final Widget child;
  final double radius;
  final bool pressed;
  final EdgeInsetsGeometry padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: color,
      gradient: color == null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pressed
                  ? [const Color(0xFFDDE7F2), const Color(0xFFF0F5F9)]
                  : [const Color(0xFFF0F5F9), EqualiColors.background],
            )
          : null,
      border: Border.all(color: Colors.white.withValues(alpha: .5), width: .8),
      boxShadow: pressed
          ? []
          : [
              const BoxShadow(color: Color(0x26435A7A), offset: Offset(2, 2), blurRadius: 5),
              BoxShadow(
                color: Colors.white.withValues(alpha: .85),
                offset: const Offset(-2, -2),
                blurRadius: 5,
              ),
            ],
    ),
    child: child,
  );
}

class NeuIcon extends StatelessWidget {
  const NeuIcon(
    this.icon, {
    super.key,
    required this.label,
    required this.onTap,
    this.size = 32,
    this.iconSize = 22,
    this.selected = false,
    this.circle = false,
    this.asset,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size, iconSize;
  final bool selected, circle;
  final String? asset;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    selected: selected,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: size / 2 + 8,
        child: SizedBox(
          width: size < 44 ? 44 : size,
          height: size < 44 ? 44 : size,
          child: Center(
            child: SizedBox(
              width: size,
              height: size,
              child: NeuBox(
                radius: circle ? size : 10,
                pressed: selected,
                child: asset != null
                    ? Center(
                        child: Image.asset(
                          'assets/images/$asset.png',
                          width: iconSize,
                          height: iconSize,
                        ),
                      )
                    : Icon(
                        icon,
                        size: iconSize,
                        color: selected ? EqualiColors.primary : EqualiColors.icon,
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.text, {super.key, required this.onPressed, this.icon});
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: EqualiColors.primary,
        disabledBackgroundColor: EqualiColors.line,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 2,
        shadowColor: const Color(0x55616F8C),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

class Artwork extends StatelessWidget {
  const Artwork(this.name, {super.key, this.size = 40, this.radius = 8});
  final String name;
  final double size, radius;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: NeuBox(
      radius: radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Transform.scale(
          scale:
              [
                'avatar',
                'lofi',
                'pure',
                'rain',
                'chinese',
                'city',
                'japanese',
                'english',
                'space',
                'heat',
                'zico',
              ].contains(name)
              ? 1.35
              : ['dj', 'hip-hop'].contains(name)
              ? 1.195
              : 1.135,
          child: Image.asset(
            'assets/images/$name.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing, this.subtitle, this.onBack});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeuIcon(
          Icons.arrow_back_rounded,
          label: 'Back',
          onTap: onBack ?? () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(color: EqualiColors.muted)),
                ],
              ],
            ),
          ),
        ),
        trailing ?? const SizedBox(width: 44),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(action!, style: const TextStyle(color: EqualiColors.primary)),
          ),
        ),
    ],
  );
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hint = 'Search',
    this.autofocus = false,
  });
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hint;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => NeuBox(
    radius: 24,
    pressed: true,
    child: TextField(
      key: const ValueKey('search-input'),
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: EqualiColors.muted),
        prefixIcon: const Icon(Icons.search_rounded, size: 22, color: EqualiColors.icon),
        suffixIcon: IconButton(
          tooltip: 'Clear search',
          icon: const Icon(Icons.close, size: 20),
          onPressed: () {
            controller.clear();
            onChanged?.call('');
          },
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuBox(
            radius: 24,
            padding: const EdgeInsets.all(26),
            child: Icon(icon, size: 42, color: EqualiColors.primary),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: EqualiColors.muted, height: 1.6),
          ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    ),
  );
}

Future<T?> openPage<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(
  PageRouteBuilder(
    pageBuilder: (_, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, secondaryAnimation, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(.04, 0), end: Offset.zero).animate(animation),
        child: child,
      ),
    ),
  ),
);

void toast(BuildContext context, String message) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));

Future<T?> showEqualiSheet<T>(BuildContext context, Widget child, {bool full = false}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: EqualiColors.background,
      barrierColor: EqualiColors.text.withValues(alpha: .13),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: full
            ? SizedBox(height: MediaQuery.sizeOf(context).height * .88, child: child)
            : SafeArea(top: false, child: child),
      ),
    );
