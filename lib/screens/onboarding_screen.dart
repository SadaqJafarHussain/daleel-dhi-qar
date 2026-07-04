import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/onboarding_slide_model.dart';
import '../providers/language_provider.dart';
import '../utils/app_localization.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingSlide> _slides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSlides();
  }

  Future<void> _fetchSlides() async {
    try {
      final data = await Supabase.instance.client
          .from('onboarding_slides')
          .select()
          .eq('active', true)
          .order('sort_order', ascending: true)
          .timeout(const Duration(seconds: 5));

      final slides = (data as List)
          .map((e) => OnboardingSlide.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _slides  = slides.isNotEmpty ? slides : _fallbackSlides;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _slides  = _fallbackSlides;
          _loading = false;
        });
      }
    }
  }

  List<OnboardingSlide> get _fallbackSlides {
    final loc = AppLocalizations.of(context);
    return [
      OnboardingSlide(id: 0, sortOrder: 0, active: true, bgColor: '#B91C4C',
        titleAr: loc.t('onboarding_title_1'), titleEn: loc.t('onboarding_title_1'),
        subtitleAr: loc.t('onboarding_desc_1'), subtitleEn: loc.t('onboarding_desc_1')),
      OnboardingSlide(id: 1, sortOrder: 1, active: true, bgColor: '#22C55E',
        titleAr: loc.t('onboarding_title_2'), titleEn: loc.t('onboarding_title_2'),
        subtitleAr: loc.t('onboarding_desc_2'), subtitleEn: loc.t('onboarding_desc_2')),
      OnboardingSlide(id: 2, sortOrder: 2, active: true, bgColor: '#3B82F6',
        titleAr: loc.t('onboarding_title_3'), titleEn: loc.t('onboarding_title_3'),
        subtitleAr: loc.t('onboarding_desc_3'), subtitleEn: loc.t('onboarding_desc_3')),
    ];
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc   = AppLocalizations.of(context);
    final isAr  = context.watch<LanguageProvider>().isArabic;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: _finish,
                  child: Text(
                    loc.t('skip'),
                    style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _buildSlide(_slides[i], i, isAr),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width:  _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? _slides[i].color
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _slides.length - 1) {
                          _finish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_currentPage].color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? loc.t('get_started')
                            : loc.t('next'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, int index, bool isAr) {
    // Use remote image if provided, else fall back to local asset
    final localAsset = 'assets/images/onboarding${index + 1}.png';
    final hasRemote  = slide.imageUrl != null && slide.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          hasRemote
              ? Image.network(
                  slide.imageUrl!,
                  height: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(localAsset),
                )
              : Image.asset(localAsset),
          const SizedBox(height: 48),
          Text(
            slide.title(isAr),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle(isAr),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
