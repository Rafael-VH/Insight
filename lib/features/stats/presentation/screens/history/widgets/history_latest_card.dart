import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

class HistoryLatestCard extends StatelessWidget {
  const HistoryLatestCard({
    super.key,
    required this.collection,
    required this.formattedDate,
    required this.onTap,
    required this.onOptionsPressed,
  });

  final StatsCollection collection;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onOptionsPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onOptionsPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF059669).withValues(alpha: 0.9),
              const Color(0xFF10B981),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildDate(),
              const SizedBox(height: 12),
              if (collection.availableStats.isNotEmpty) ...[
                _buildModesLabel(),
                const SizedBox(height: 8),
                _buildModeChips(),
              ],
              const SizedBox(height: 16),
              _buildDetailsButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'MÁS RECIENTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onOptionsPressed,
          icon: const Icon(Icons.more_vert, color: Colors.white),
          tooltip: 'Más opciones',
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      collection.displayName,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDate() {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 18, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          formattedDate,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildModesLabel() {
    return Text(
      'Modos capturados:',
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildModeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: collection.availableStats.map((stats) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Text(
            stats.mode.shortName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF059669),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ver Detalles', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}
