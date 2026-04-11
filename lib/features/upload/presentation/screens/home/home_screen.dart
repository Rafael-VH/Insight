import 'package:flutter/material.dart';
import 'package:insight/features/upload/domain/entities/stats_upload_type.dart';
import 'package:insight/features/upload/presentation/screens/upload/upload_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _HeroSliverHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _UploadSection(onNavigate: _navigateToUpload),
                const SizedBox(height: 24),
                const _TipsSection(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUpload(BuildContext context, StatsUploadType type) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => UploadScreen(uploadType: type)));
  }
}

// ════════════════════════════════════════════════════════════════
// Hero header con stats decorativas
// ════════════════════════════════════════════════════════════════

class _HeroSliverHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: _HeroHeader());
  }
}

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: colorScheme.primary),
      child: Stack(
        children: [
          // Círculos decorativos de fondo
          Positioned(top: -50, right: -50, child: _DecorativeCircle(size: 200, opacity: 0.06)),
          Positioned(bottom: -30, right: 20, child: _DecorativeCircle(size: 130, opacity: 0.05)),
          Positioned(top: 30, left: -60, child: _DecorativeCircle(size: 160, opacity: 0.04)),
          // Contenido
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBadge(color: colorScheme.onPrimary),
                  const SizedBox(height: 14),
                  Text(
                    'Analiza tu\nrendimiento',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escanea tus capturas y convierte\ntus partidas en datos reales.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimary.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _HeroStatsRow(onPrimaryColor: colorScheme.onPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.onPrimary.withValues(alpha: opacity), width: 1),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Mobile Legends Stats',
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatsRow extends StatelessWidget {
  const _HeroStatsRow({required this.onPrimaryColor});
  final Color onPrimaryColor;

  @override
  Widget build(BuildContext context) {
    final items = [('28', 'Campos OCR'), ('4', 'Modos'), ('100%', 'Automático')];

    return Row(
      children: items.asMap().entries.map((entry) {
        final isLast = entry.key == items.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: _HeroStatItem(
                  value: entry.value.$1,
                  label: entry.value.$2,
                  onPrimaryColor: onPrimaryColor,
                ),
              ),
              if (!isLast)
                Container(
                  width: 0.5,
                  height: 36,
                  color: onPrimaryColor.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({required this.value, required this.label, required this.onPrimaryColor});

  final String value;
  final String label;
  final Color onPrimaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: onPrimaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: onPrimaryColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onPrimaryColor),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: onPrimaryColor.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Sección de carga: las dos tarjetas de acción
// ════════════════════════════════════════════════════════════════

class _UploadSection extends StatelessWidget {
  const _UploadSection({required this.onNavigate});

  final void Function(BuildContext, StatsUploadType) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: 'Cargar estadísticas',
          subtitle: 'Elige el tipo de captura que tienes',
        ),
        const SizedBox(height: 12),
        _UploadCard(
          uploadType: StatsUploadType.total,
          accentColor: const Color(0xFF059669),
          iconColor: const Color(0xFF0F6E56),
          iconBackground: const Color(0xFFE1F5EE),
          icon: Icons.dashboard_rounded,
          description: 'Resumen general de todas las partidas en una sola imagen',
          onTap: () => onNavigate(context, StatsUploadType.total),
        ),
        const SizedBox(height: 10),
        _UploadCard(
          uploadType: StatsUploadType.byModes,
          accentColor: const Color(0xFF7C3AED),
          iconColor: const Color(0xFF534AB7),
          iconBackground: const Color(0xFFEEEDFE),
          icon: Icons.view_module_rounded,
          description: 'Clasificatoria, Clásica y Coliseo por separado',
          onTap: () => onNavigate(context, StatsUploadType.byModes),
        ),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.uploadType,
    required this.accentColor,
    required this.iconColor,
    required this.iconBackground,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  final StatsUploadType uploadType;
  final Color accentColor;
  final Color iconColor;
  final Color iconBackground;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cuerpo de la tarjeta ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícono
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? accentColor.withValues(alpha: 0.15) : iconBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: isDark ? accentColor : iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    // Texto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uploadType.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
              // ── Pie de la tarjeta ────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${uploadType.imageCount} imagen${uploadType.imageCount > 1 ? 'es' : ''} requerida${uploadType.imageCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Chips de modos para byModes, label simple para total
                    if (uploadType == StatsUploadType.byModes)
                      _ModesChipRow(accentColor: accentColor)
                    else
                      _ModeChip(label: 'Total', color: accentColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? color : color.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _ModesChipRow extends StatelessWidget {
  const _ModesChipRow({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    const modes = ['Ranked', 'Clásica', 'Coliseo'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: modes
          .map(
            (m) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _ModeChip(label: m, color: accentColor),
            ),
          )
          .toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Sección de consejos
// ════════════════════════════════════════════════════════════════

class _TipsSection extends StatelessWidget {
  const _TipsSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const tips = [
      (
        Icons.crop_free_rounded,
        'Encuadre completo',
        'Asegúrate de que todas las estadísticas sean visibles sin recortes.',
      ),
      (
        Icons.wb_sunny_outlined,
        'Buena iluminación',
        'Evita reflejos, desenfoque o baja luminosidad en la captura.',
      ),
      (
        Icons.percent_rounded,
        'Porcentaje visible',
        'El porcentaje de victorias debe estar completamente visible.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: 'Consejos de captura',
          subtitle: 'Para mejores resultados con el OCR',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.15)),
          ),
          child: Column(
            children: tips.asMap().entries.map((entry) {
              final isLast = entry.key == tips.length - 1;
              final tip = entry.value;
              return Column(
                children: [
                  _TipRow(
                    index: entry.key + 1,
                    icon: tip.$1,
                    title: tip.$2,
                    description: tip.$3,
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colorScheme.outline.withValues(alpha: isDark ? 0.12 : 0.08),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.index,
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
    required this.isDark,
  });

  final int index;
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ícono + texto
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Widget reutilizable: encabezado de sección
// ════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.subtitle});

  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}
