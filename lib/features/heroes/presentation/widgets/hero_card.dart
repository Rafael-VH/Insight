import 'package:flutter/material.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';
import 'package:insight/features/heroes/presentation/utils/hero_role_utils.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.hero,
    required this.onTap,
    this.isSelected = false,
    this.roleHint,
  });

  final MlbbHero hero;
  final VoidCallback onTap;
  final bool isSelected;

  /// Rol principal del héroe (opcional — se usa para el dot de color).
  final String? roleHint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = HeroRoleUtils.colorForRole(roleHint ?? '');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: isDark ? 0.12 : 0.18),
              width: isSelected ? 1.5 : 0.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: _HeroImageArea(hero: hero, roleColor: roleColor),
              ),
              _HeroCardFooter(hero: hero, roleHint: roleHint, colorScheme: colorScheme),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Área de imagen ────────────────────────────────────────────────

class _HeroImageArea extends StatelessWidget {
  const _HeroImageArea({required this.hero, required this.roleColor});

  final MlbbHero hero;
  final Color roleColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen o placeholder
          hero.iconUrl.isNotEmpty
              ? Image.network(
                  hero.iconUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : _AvatarPlaceholder(hero: hero, colorScheme: colorScheme),
                  errorBuilder: (_, __, ___) =>
                      _AvatarPlaceholder(hero: hero, colorScheme: colorScheme),
                )
              : _AvatarPlaceholder(hero: hero, colorScheme: colorScheme),

          // Gradiente inferior para legibilidad del nombre
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),

          // Dot de rol en esquina superior derecha
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: roleColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder de avatar ─────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.hero, required this.colorScheme});

  final MlbbHero hero;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final color = HeroRoleUtils.avatarColorForId(hero.heroId);

    return Container(
      color: color.withValues(alpha: 0.18),
      child: Center(
        child: Text(
          hero.name.isNotEmpty ? hero.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Footer: nombre + tag de rol ───────────────────────────────────

class _HeroCardFooter extends StatelessWidget {
  const _HeroCardFooter({required this.hero, required this.roleHint, required this.colorScheme});

  final MlbbHero hero;
  final String? roleHint;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hero.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (roleHint != null && roleHint!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              roleHint!.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.7,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
