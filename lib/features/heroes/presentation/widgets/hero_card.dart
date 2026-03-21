import 'package:flutter/material.dart';
import 'package:insight/features/heroes/domain/entities/mlbbhero.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.hero, required this.onTap});

  final MlbbHero hero;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: hero.iconUrl.isNotEmpty
                      ? Image.network(
                          hero.iconUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.sports_esports,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.sports_esports,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  hero.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
