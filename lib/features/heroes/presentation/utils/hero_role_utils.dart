import 'package:flutter/material.dart';

/// Utilidades de presentación para roles y colores de héroes.
/// Centraliza la lógica de color para que HeroCard, HeroDetailScreen
/// y los chips de rol usen siempre los mismos valores.
class HeroRoleUtils {
  HeroRoleUtils._();

  // ── Mapa de colores por rol ───────────────────────────────────

  static const Map<String, Color> _roleColors = {
    'Marksman': Color(0xFF3B82F6),
    'Mage': Color(0xFF8B5CF6),
    'Fighter': Color(0xFFF59E0B),
    'Tank': Color(0xFF10B981),
    'Assassin': Color(0xFFEF4444),
    'Support': Color(0xFF14B8A6),
  };

  static const List<Color> _avatarPalette = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
    Color(0xFFF97316),
    Color(0xFF0EA5E9),
  ];

  /// Color del dot/chip para un rol dado.
  static Color colorForRole(String role) => _roleColors[role] ?? const Color(0xFF6B7280);

  /// Color de fondo del avatar para un héroe dado (por ID).
  static Color avatarColorForId(int heroId) => _avatarPalette[heroId % _avatarPalette.length];

  /// Construye un chip de rol con colores semánticos.
  static Widget buildRoleChip(String role, {bool small = false}) {
    final color = colorForRole(role);
    return _RoleChip(role: role, color: color, small: small);
  }

  /// Construye la lista de chips de roles.
  static Widget buildRoleChips(List<String> roles, {bool small = false}) {
    if (roles.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: roles.map((r) => buildRoleChip(r, small: small)).toList(),
    );
  }
}

// ── Widget de chip de rol ─────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, required this.color, required this.small});

  final String role;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? 9.0 : 10.0;
    final hPad = small ? 7.0 : 9.0;
    final vPad = small ? 2.0 : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
