import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/language_selector_modal.dart';
import '../widgets/slide_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final List<String> _quoteKeys = [
    'quote_1',
    'quote_2',
    'quote_3',
    'quote_4',
    'quote_5',
  ];

  int _quoteIndex = 0;
  late AnimationController _floatCtrl;
  late AnimationController _blob1Ctrl;
  late AnimationController _blob2Ctrl;
  late Animation<double> _floatY;
  late Animation<double> _floatRotate;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _blob1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _blob2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _floatY = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _floatRotate = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Cycle quotes every 5 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      setState(() => _quoteIndex = (_quoteIndex + 1) % _quoteKeys.length);
      return true;
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _blob1Ctrl.dispose();
    _blob2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Animated blobs
          _buildBlobs(),

          // Language selector button at top right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => showLanguageSelector(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, size: 18, color: AppColors.textDark),
                        const SizedBox(width: 6),
                        Text(
                          context.currentLanguage.nativeName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Plus decorative icon
          Positioned(
            top: 70,
            left: 40,
            child: Opacity(
              opacity: 0.3,
              child: const Icon(Icons.add, size: 24, color: AppColors.medicalGreen),
            ),
          ),

          Column(
            children: [
              // Top section with floating quote
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatY.value),
                      child: Transform.rotate(
                        angle: _floatRotate.value,
                        child: child,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Floating icons
                        Positioned(
                          top: -40,
                          right: -20,
                          child: _floatingIcon(Icons.favorite),
                        ),
                        Positioned(
                          bottom: -20,
                          left: -30,
                          child: _floatingIcon(Icons.show_chart, size: 20),
                        ),
                        // Quote card
                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          constraints: const BoxConstraints(minHeight: 180),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.medicalGreen.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.medicalGreen.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 24,
                                color: AppColors.lightGreenAccent,
                              ),
                              const SizedBox(height: 10),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 800),
                                child: Text(
                                  context.tr(_quoteKeys[_quoteIndex]),
                                  key: ValueKey('$_quoteIndex-${context.currentLanguage.code}'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkNavy,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: 40,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.medicalGreen,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom card
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 60, end: 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, val, child) =>
                    Transform.translate(offset: Offset(0, val), child: child),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xF2FFFFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, -10),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('care_made_simple'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkNavy,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.tr('onboarding_desc'),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SlideButton(
                        title: context.tr('get_started'),
                        onComplete: () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _floatingIcon(IconData icon, {double size = 24}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Icon(icon, size: size, color: AppColors.medicalGreen),
    );
  }

  Widget _buildBlobs() {
    return AnimatedBuilder(
      animation: Listenable.merge([_blob1Ctrl, _blob2Ctrl]),
      builder: (_, __) {
        final b1x = -20 + 40 * _blob1Ctrl.value;
        final b1y = 0 + 30 * _blob1Ctrl.value;
        final b2x = 30 - 40 * _blob2Ctrl.value;
        final b2y = -20 + 30 * _blob2Ctrl.value;
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1 + b1y,
              left: -MediaQuery.of(context).size.width * 0.1 + b1x,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1FADD).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(150),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.2 + b2y,
              right: -MediaQuery.of(context).size.width * 0.1 + b2x,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E6FF).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
