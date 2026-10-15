import 'package:flutter/material.dart';

import '../landing/landing_about_cta_footer.dart';
import '../landing/landing_dashboard.dart';
import '../landing/landing_features_workflow.dart';
import '../landing/landing_hero.dart';
import '../landing/landing_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          LandingNavbar(
            onHomeTap: _scrollToTop,
            onFeaturesTap: () => _scrollTo(_featuresKey),
            onHowItWorksTap: () => _scrollTo(_howItWorksKey),
            onAboutTap: () => _scrollTo(_aboutKey),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  LandingHero(onExploreFeatures: () => _scrollTo(_featuresKey)),
                  LandingFeaturesSection(key: _featuresKey),
                  LandingHowItWorksSection(key: _howItWorksKey),
                  const LandingDashboardSection(),
                  LandingAboutSection(key: _aboutKey),
                  const LandingCtaSection(),
                  LandingFooter(
                    onHomeTap: _scrollToTop,
                    onFeaturesTap: () => _scrollTo(_featuresKey),
                    onHowItWorksTap: () => _scrollTo(_howItWorksKey),
                    onAboutTap: () => _scrollTo(_aboutKey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
