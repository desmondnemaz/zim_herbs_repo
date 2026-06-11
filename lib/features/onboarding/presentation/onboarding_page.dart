import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/onboarding/bloc/onboarding_cubit.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/home_page.dart';
import 'package:zim_herbs_repo/utils/responsive_sizes.dart';

// --- Model ---

class OnboardingModel {
  final String title;
  final String description;
  final String image;

  const OnboardingModel({
    required this.title,
    required this.description,
    required this.image,
  });

  static List<OnboardingModel> get items => const [
    OnboardingModel(
      title: "Discover Zimbabwe's Heritage",
      description:
          "Explore a vast collection of indigenous Zimbabwean herbs and their traditional uses.",
      image: "assets/images/great_zimbabwe.png",
    ),
    OnboardingModel(
      title: "Natural Healing",
      description:
          "Find natural treatments and preparations for various health conditions.",
      image: "assets/images/medicines.png",
    ),
    OnboardingModel(
      title: "Community Wisdom",
      description:
          "Access shared knowledge and professional resources for traditional medicine.",
      image: "assets/images/community.png",
    ),
  ];
}

// --- Main Page ---

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  int _currentPage = 0;
  final List<OnboardingModel> _contents = OnboardingModel.items;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepChanged(int index) => setState(() => _currentPage = index);

  void _handleNavigation(BuildContext context) {
    if (_currentPage == _contents.length - 1) {
      context.read<OnboardingCubit>().completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);

    return BlocProvider(
      create: (context) => OnboardingCubit(),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (state is OnboardingError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Builder(
          builder: (innerContext) {
            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onStepChanged,
                    itemCount: _contents.length,
                    itemBuilder: (context, index) {
                      return _BuildPageContent(
                        rs: rs,
                        content: _contents[index],
                      );
                    },
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        const Spacer(),
                        _FooterSection(
                          rs: rs,
                          total: _contents.length,
                          current: _currentPage,
                          onPressed: () => _handleNavigation(innerContext),
                          onSkip: () => innerContext.read<OnboardingCubit>().completeOnboarding(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}

// --- Sub-Widgets ---

class _BuildPageContent extends StatelessWidget {
  final ResponsiveSize rs;
  final OnboardingModel content;

  const _BuildPageContent({required this.rs, required this.content});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            content.image,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Center(
                    child: Hero(
                      tag: content.image,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          content.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        content.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: rs.pick(mobile: 24, tablet: 32, desktop: 36),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        content.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: rs.pick(mobile: 16, tablet: 18, desktop: 20),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  final ResponsiveSize rs;
  final int total;
  final int current;
  final VoidCallback onPressed;
  final VoidCallback onSkip;

  const _FooterSection({
    required this.rs,
    required this.total,
    required this.current,
    required this.onPressed,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = current == total - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              total,
              (index) => _BuildDotWidget(isActive: index == current),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: rs.pick(mobile: double.infinity, tablet: 400, desktop: 400),
            height: 56,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isLast ? "GET STARTED" : "CONTINUE",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!isLast)
            ElevatedButton(
              onPressed: onSkip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                "SKIP",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _BuildDotWidget extends StatelessWidget {
  final bool isActive;

  const _BuildDotWidget({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.secondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive 
            ? activeColor 
            : activeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
