import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EduCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool hasGradientBorder;
  final double borderRadius;

  const EduCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.hasGradientBorder = false,
    this.borderRadius = 16,
  });

  @override
  State<EduCard> createState() => _EduCardState();
}

class _EduCardState extends State<EduCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: widget.margin,
      padding: EdgeInsets.all(widget.hasGradientBorder ? 1.5 : 0),
      decoration: BoxDecoration(
        color: widget.hasGradientBorder ? null : AppTheme.cardColor,
        gradient: widget.hasGradientBorder ? AppTheme.primaryGradient : null,
        borderRadius: radius,
        border: widget.hasGradientBorder
            ? null
            : Border.all(color: const Color(0xFFDCE5EF)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withAlpha(_hovered ? 30 : 14),
            blurRadius: _hovered ? 20 : 12,
            offset: Offset(0, _hovered ? 8 : 4),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.cardColor,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHover: widget.onTap == null
              ? null
              : (value) => setState(() => _hovered = value),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return EduCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.primaryColor).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class EduButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;

  const EduButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );

    final button = isOutlined
        ? OutlinedButton(onPressed: isLoading ? null : onPressed, child: child)
        : FilledButton(onPressed: isLoading ? null : onPressed, child: child);

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              EduButton(text: actionText!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
