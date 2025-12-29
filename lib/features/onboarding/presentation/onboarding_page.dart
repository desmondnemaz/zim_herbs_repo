import 'package:flutter/material.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/home_page.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';
import 'package:hive/hive.dart';
import 'package:zim_herbs_repo/features/settings/bloc/settings_bloc.dart';
import 'package:zim_herbs_repo/core/presentation/widgets/zimbabwe_widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "Discover Zimbabwe's Heritage",
      description:
          "Explore a vast collection of indigenous Zimbabwean herbs and their traditional uses.",
      image: "assets/images/onboarding_herbs.png",
    ),
    OnboardingContent(
      title: "Natural Healing",
      description:
          "Find natural treatments and preparations for various health conditions.",
      image: "assets/images/onboarding_healing.png",
    ),
    OnboardingContent(
      title: "Community Wisdom",
      description:
          "Access shared knowledge and professional resources for traditional medicine.",
      image: "assets/images/onboarding_community.png",
    ),
  ];

  void _onFinish() async {
    final box = await Hive.openBox(SettingsBloc.boxName);
    await box.put('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ZimbabweWorkBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _contents.length,
                      itemBuilder: (context, index) {
                        return OnboardingSlide(
                          content: _contents[index],
                          rs: rs,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _contents.length,
                              (index) => buildDot(index, context),
                            ),
                          ),
                          const Spacer(),
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: rs.pick(
                                  mobile: double.infinity,
                                  tablet: 400.0,
                                  desktop: 400.0,
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_currentPage == _contents.length - 1) {
                                      _onFinish();
                                    } else {
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeIn,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _currentPage == _contents.length - 1
                                        ? "GET STARTED"
                                        : "NEXT",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 16,
                right: 24,
                child: TextButton(
                  onPressed: _onFinish,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text(
                    "SKIP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        height: 8,
        width: _currentPage == index ? 24 : 8,
        decoration: BoxDecoration(
          color:
              _currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String image;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingSlide extends StatelessWidget {
  final OnboardingContent content;
  final ResponsiveSize rs;

  const OnboardingSlide({super.key, required this.content, required this.rs});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = rs.pick(
      mobile: 32.0,
      tablet: 64.0,
      desktop: 120.0,
    );
    final spacing = rs.pick(mobile: 32.0, tablet: 48.0, desktop: 64.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 40,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(content.image, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: spacing),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rs.pick(mobile: 28.0, tablet: 36.0, desktop: 44.0),
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rs.pick(mobile: 16.0, tablet: 18.0, desktop: 20.0),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
