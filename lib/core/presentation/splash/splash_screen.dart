import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/navigation/presentation/screens/main_screen.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // ── Controladores ─────────────────────────────────────────────
  late final AnimationController _particleController;
  late final AnimationController _iconController;
  late final AnimationController _textController;
  late final AnimationController _exitController;

  // ── Animaciones del ícono ─────────────────────────────────────
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconGlow;

  // ── Animaciones del texto ─────────────────────────────────────
  late final Animation<double> _textFade;
  late final Animation<double> _taglineFade;
  late final Animation<int> _titleCharCount;

  // ── Animación de salida ───────────────────────────────────────
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  // ── Partículas ────────────────────────────────────────────────
  late final List<_Particle> _particles;
  Color _accentColor = const Color(0xFF059669);

  static const String _appTitle = 'Insight';
  static const String _tagline = 'ML Stats OCR';

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimations();
    _startSequence();
  }

  // ── Inicialización ─────────────────────────────────────────────

  void _initParticles() {
    final rng = math.Random(42);
    _particles = List.generate(
      30,
      (i) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 2.5 + 0.5,
        speed: rng.nextDouble() * 0.003 + 0.001,
        opacity: rng.nextDouble() * 0.5 + 0.1,
        phase: rng.nextDouble() * math.pi * 2,
      ),
    );
  }

  void _initAnimations() {
    // Partículas — loop infinito
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    // Ícono — 900ms
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.95).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_iconController);

    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _iconGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.4).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_iconController);

    // Texto — 1200ms (título con typewriter + tagline fade)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleCharCount = StepTween(begin: 0, end: _appTitle.length).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.linear),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Salida — 500ms
    _exitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _exitFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _exitScale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
  }

  Future<void> _startSequence() async {
    // 1. Aparece el ícono
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _iconController.forward();

    // 2. Aparece el texto
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _textController.forward();

    // 3. Pausa con todo visible
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // 4. Transición de salida
    await _exitController.forward();
    if (!mounted) return;

    _navigateToMain();
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _iconController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Tomamos el color primario del ThemeBloc si ya está cargado
    final themeState = context.watch<ThemeBloc>().state;
    if (themeState is ThemeLoaded) {
      _accentColor = themeState.currentTheme.lightColorScheme.primary;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _particleController,
          _iconController,
          _textController,
          _exitController,
        ]),
        builder: (context, _) {
          return FadeTransition(
            opacity: _exitFade,
            child: ScaleTransition(
              scale: _exitScale,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Capa de partículas ────────────────────────
                  CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                      accentColor: _accentColor,
                    ),
                  ),

                  // ── Viñeta radial ─────────────────────────────
                  _buildVignette(),

                  // ── Contenido central ─────────────────────────
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIcon(),
                        const SizedBox(height: 28),
                        _buildTitle(),
                        const SizedBox(height: 8),
                        _buildTagline(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Widgets internos ───────────────────────────────────────────

  Widget _buildVignette() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Colors.transparent, const Color(0xFF0A0C10).withValues(alpha: 0.7)],
          stops: const [0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final glowRadius = 40.0 * _iconGlow.value;

    return FadeTransition(
      opacity: _iconFade,
      child: ScaleTransition(
        scale: _iconScale,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _accentColor.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.35 * _iconGlow.value),
                blurRadius: glowRadius,
                spreadRadius: glowRadius * 0.3,
              ),
            ],
          ),
          child: Icon(Icons.insights_rounded, size: 52, color: _accentColor),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final visibleChars = _titleCharCount.value;
    final visible = _appTitle.substring(0, visibleChars);
    final hidden = _appTitle.substring(visibleChars);

    return FadeTransition(
      opacity: _textFade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Letras visibles
          Text(
            visible,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [Shadow(color: _accentColor.withValues(alpha: 0.6), blurRadius: 12)],
            ),
          ),
          // Letras todavía invisibles (mantienen el espacio)
          Text(
            hidden,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.transparent,
              letterSpacing: 2,
            ),
          ),
          // Cursor parpadeante mientras escribe
          if (visibleChars < _appTitle.length) _BlinkingCursor(color: _accentColor),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineFade,
      child: Text(
        _tagline,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 3,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Cursor parpadeante
// ══════════════════════════════════════════════════════════════════

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});
  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
      ..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: 3,
        height: 38,
        margin: const EdgeInsets.only(left: 4, bottom: 2),
        decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Sistema de partículas
// ══════════════════════════════════════════════════════════════════

class _Particle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double opacity;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color accentColor;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Movimiento vertical suave con onda sinusoidal
      final dy = (p.y - progress * p.speed * 10) % 1.0;
      final dx = p.x + math.sin(progress * math.pi * 2 + p.phase) * 0.02;

      final offset = Offset(dx * size.width, dy * size.height);

      // Alternar entre puntos de acento y blancos
      final isAccent = particles.indexOf(p) % 4 == 0;
      final color = isAccent
          ? accentColor.withValues(alpha: p.opacity * 0.8)
          : Colors.white.withValues(alpha: p.opacity * 0.4);

      canvas.drawCircle(offset, p.radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.accentColor != accentColor;
}
