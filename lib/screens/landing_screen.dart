import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tier.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common/brand_mark.dart';
import '../widgets/common/effects.dart';
import '../widgets/landing/pricing_card.dart';
import 'chat_screen.dart';

/// Responsive breakpoints used across the landing page.
class Breakpoints {
  Breakpoints._();
  static const double mobile = 600;
  static const double tablet = 900;

  static bool isMobile(BuildContext c) =>
      MediaQuery.sizeOf(c).width < mobile;
  static bool isDesktop(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= tablet;
}

/// Landing page & conversion funnel (PRD section 5.1): hero, feature
/// highlights, pricing comparison, testimonials, final CTA, and footer.
/// Fully responsive with hover effects and scroll-reveal animations.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _storiesKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  /// Enter coaching. Uses the user's saved tier if they have one, otherwise
  /// starts them on the recommended Flame plan. The unambiguous
  /// "get me into the app" action behind the hero's primary button.
  Future<void> _startCoaching() async {
    final state = context.read<AppState>();
    final tier = state.tier ?? SubscriptionTier.flame;
    await state.selectTier(tier);
    if (!mounted) return;
    _goToChat();
  }

  /// Pick a specific tier from the pricing cards / final CTA, then enter chat.
  Future<void> _selectTier(SubscriptionTier tier) async {
    await context.read<AppState>().selectTier(tier);
    if (!mounted) return;
    _goToChat();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  void _scrollToPricing() => _scrollTo(_pricingKey);

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTier = context.watch<AppState>().hasTier;

    // Sections are built lazily so RevealOnScroll fires as each scrolls in.
    final sections = <Widget>[
      _Hero(onStartCoaching: _startCoaching, onSeePlans: _scrollToPricing),
      const _FeatureStrip(),
      KeyedSubtree(key: _howKey, child: const _HowItWorks()),
      KeyedSubtree(key: _pricingKey, child: _Pricing(onSelect: _selectTier)),
      KeyedSubtree(key: _storiesKey, child: const _Stories()),
      _FinalCta(onStart: _startCoaching),
      _Footer(
        onStart: _startCoaching,
        onSeePlans: _scrollToPricing,
        onStories: () => _scrollTo(_storiesKey),
        onHowItWorks: () => _scrollTo(_howKey),
      ),
    ];

    return Scaffold(
      body: ScrollConfiguration(
        // Smooth, momentum-style scrolling on web/desktop too.
        behavior: const _SmoothScrollBehavior(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background.withValues(alpha: 0.92),
              elevation: 0,
              scrolledUnderElevation: 0.5,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              toolbarHeight: 66,
              title: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Breakpoints.isMobile(context)
                      ? AppSpacing.md
                      : AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    const BrandMark(),
                    // Centered nav links on desktop; a flexible gap otherwise.
                    if (Breakpoints.isDesktop(context))
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NavLink(label: 'Home', onTap: _scrollToTop),
                              _NavLink(
                                label: 'How it works',
                                onTap: () => _scrollTo(_howKey),
                              ),
                              _NavLink(
                                  label: 'Pricing', onTap: _scrollToPricing),
                              _NavLink(
                                label: 'Stories',
                                onTap: () => _scrollTo(_storiesKey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (!Breakpoints.isDesktop(context))
                      PopupMenuButton<VoidCallback>(
                        icon: const Icon(Icons.menu, color: AppColors.text),
                        tooltip: 'Menu',
                        onSelected: (cb) => cb(),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _scrollToTop,
                            child: const Text('Home'),
                          ),
                          PopupMenuItem(
                            value: () => _scrollTo(_howKey),
                            child: const Text('How it works'),
                          ),
                          PopupMenuItem(
                            value: _scrollToPricing,
                            child: const Text('Pricing'),
                          ),
                          PopupMenuItem(
                            value: () => _scrollTo(_storiesKey),
                            child: const Text('Stories'),
                          ),
                        ],
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    hasTier
                        ? HoverScale(
                            child: FilledButton(
                              onPressed: _goToChat,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Continue'),
                            ),
                          )
                        : HoverScale(
                            child: OutlinedButton(
                              onPressed: _startCoaching,
                              child: const Text('Start'),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            // All sections are laid out (not lazily built) so every section
            // anchor is reachable for scroll-to-section navigation. The reveal
            // animation is driven by the shared scroll controller instead.
            SliverToBoxAdapter(
              child: Column(
                children: [
                  for (final section in sections)
                    RevealOnScroll(
                      controller: _scrollController,
                      child: section,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enables smooth dragging via mouse on web/desktop without the default
/// scrollbar overlapping content.
class _SmoothScrollBehavior extends MaterialScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// A centred, max-width content section with responsive padding.
class _Section extends StatelessWidget {
  const _Section({required this.child, this.background});
  final Widget child;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? AppSpacing.xl : AppSpacing.xxl,
        horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: child,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onStartCoaching, required this.onSeePlans});

  final VoidCallback onStartCoaching;
  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < Breakpoints.mobile;
    final isWide = width >= Breakpoints.tablet;

    // Two-column (text + image) on desktop; stacked & centered below.
    final isRow = isWide;
    final cross =
        isRow ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = isRow ? TextAlign.left : TextAlign.center;

    final titleStyle = (isWide
            ? theme.textTheme.displayMedium
            : isMobile
                ? theme.textTheme.headlineMedium
                : theme.textTheme.displaySmall)
        ?.copyWith(fontWeight: FontWeight.w800, height: 1.05);

    final textColumn = Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(icon: Icons.auto_awesome, label: 'Your AI dating coach'),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isRow
              ? 'Become the\nmost matched\nversion of you.'
              : 'Become the most\nmatched version\nof you.',
          textAlign: textAlign,
          style: titleStyle,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "DateWise AI is a 24/7 dating coach in your pocket. Rewrite your bio, "
          "fix your photos, script the perfect opener — and finally feel like "
          "the kind of person you'd swipe right on.",
          textAlign: textAlign,
          style: (isMobile
                  ? theme.textTheme.bodyLarge
                  : theme.textTheme.titleMedium)
              ?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          alignment: isRow ? WrapAlignment.start : WrapAlignment.center,
          children: [
            HoverScale(
              child: ElevatedButton(
                onPressed: onStartCoaching,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start your free session'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            HoverScale(
              child: OutlinedButton(
                onPressed: onSeePlans,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('See pricing'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Privacy reassurance — we collect no personal data.
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              isRow ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'No sign-up. We never collect your personal data — everything '
                'stays private on your device.',
                textAlign: textAlign,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.symmetric(
        vertical: isWide
            ? 88
            : isMobile
                ? 40
                : 64,
        horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: isRow
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: textColumn),
                    const SizedBox(width: AppSpacing.xl),
                    const Expanded(flex: 6, child: _HeroImage()),
                  ],
                )
              : Column(
                  children: [
                    textColumn,
                    const SizedBox(height: AppSpacing.xl),
                    const _HeroImage(),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Hero visual: a warm portrait with a floating "match" badge for flair.
/// Loads from a bundled, optimized asset so it appears instantly (and offline).
class _HeroImage extends StatelessWidget {
  const _HeroImage();

  static const _imageAsset = 'assets/images/hero.jpg';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AspectRatio(
          aspectRatio: 3 / 2, // matches the source image (1536×1024)
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 50,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.asset(
                      _imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _HeroImageFallback(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -16,
                bottom: 28,
                child: _FloatingBadge(),
              ),
              const Positioned(
                right: -12,
                top: 24,
                child: _FloatingChip(label: '+34% matches'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImageFallback extends StatelessWidget {
  const _HeroImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.romanticGradient),
      child: Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white, size: 64),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: AppColors.romanticGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('DateWise AI says',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textMuted)),
              Text('“This one’s a KEEP ✨”',
                  style: theme.textTheme.labelLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: AppColors.romanticGradient,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.onDark = false,
  });
  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = onDark ? Colors.white : AppColors.text;
    final subColor =
        onDark ? Colors.white.withValues(alpha: 0.75) : AppColors.textMuted;
    return Column(
      children: [
        // Gold eyebrow label for an editorial, professional feel.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: onDark ? 0.22 : 0.16),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: onDark ? const Color(0xFFEDC373) : const Color(0xFFB07E20),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title,
            style: theme.textTheme.headlineMedium?.copyWith(color: titleColor),
            textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(color: subColor),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  static const _features = [
    (
      Icons.edit_note_rounded,
      'Profile audits & bio rewrites',
      'Full rewrites and a brutally honest audit that stops the scroll.'
    ),
    (
      Icons.chat_bubble_outline_rounded,
      'Conversation coaching',
      'Openers, scripts, ghosting recovery — exact words to copy and paste.'
    ),
    (
      Icons.camera_alt_outlined,
      'AI photo coach',
      'Score every photo 1-10 with KEEP / RESHOOT / DELETE verdicts.'
    ),
    (
      Icons.insights_rounded,
      'Match-rate predictions',
      'See the predicted lift before you ever change a thing.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    return _Section(
      background: Colors.white,
      child: Column(
        children: [
          const _SectionHeading(
            eyebrow: 'Features',
            title: 'Everything you need to date smarter',
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            alignment: WrapAlignment.center,
            children: _features.map((f) {
              return SizedBox(
                width: isMobile ? double.infinity : 250,
                child: HoverScale(
                  scale: 1.02,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: AppColors.romanticGradient,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(f.$1, color: Colors.white),
                        ),
                          const SizedBox(height: AppSpacing.md),
                          Text(f.$2, style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            f.$3,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    ('1', 'Pick your plan', 'Spark, Flame, or Magnet — each unlocks deeper coaching.'),
    ('2', 'Chat with DateWise AI', 'Threaded conversations for profile, dates, and photos.'),
    ('3', 'Apply & match', 'Copy-paste fixes and watch your reply rate climb.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    // A bold navy band — adds a strong block of color and breaks up the page.
    return _Section(
      background: AppColors.primary,
      child: Column(
        children: [
          const _SectionHeading(
            eyebrow: 'Process',
            title: 'How it works',
            onDark: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.lg,
            alignment: WrapAlignment.center,
            children: _steps.map((s) {
              return SizedBox(
                width: isMobile ? double.infinity : 260,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(s.$1,
                            style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 22)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(s.$2,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(s.$3,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72))),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Pricing extends StatelessWidget {
  const _Pricing({required this.onSelect});
  final ValueChanged<SubscriptionTier> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        children: [
          const _SectionHeading(
            eyebrow: 'Pricing',
            title: 'Choose your magnetism',
            subtitle: 'Weekly plans. Upgrade, downgrade, or cancel anytime.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            alignment: WrapAlignment.center,
            children: TierInfo.all
                .map((info) =>
                    PricingCard(info: info, onSelect: () => onSelect(info.tier)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// A success story: a quote attributed to a name/age and the tier that powered
/// the result.
class _Story {
  const _Story(this.quote, this.name, this.age, this.tier);
  final String quote;
  final String name;
  final int age;
  final SubscriptionTier tier;
}

class _Stories extends StatelessWidget {
  const _Stories();

  static const _stories = [
    _Story(
      'I went from 2 matches a week to 14. The bio rewrite alone was worth it.',
      'Maya',
      28,
      SubscriptionTier.spark,
    ),
    _Story(
      'The photo coach made me reshoot half my profile. My match rate doubled '
          'in 9 days.',
      'Jordan',
      34,
      SubscriptionTier.magnet,
    ),
    _Story(
      "Finally an opener that doesn't sound like a chatbot wrote it.",
      'Sara',
      31,
      SubscriptionTier.flame,
    ),
    _Story(
      'Three dates in one weekend. I had not had three dates in a whole year.',
      'Daniel',
      29,
      SubscriptionTier.flame,
    ),
    _Story(
      'DateWise AI flagged the one photo tanking my profile. Gone — instant '
          'difference.',
      'Priya',
      26,
      SubscriptionTier.magnet,
    ),
    _Story(
      'It rewrote my whole bio in 30 seconds and it actually sounded like me, '
          'just better.',
      'Alex',
      33,
      SubscriptionTier.spark,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return _Section(
      background: AppColors.surface,
      child: Column(
        children: [
          const _SectionHeading(
            eyebrow: 'Stories',
            title: 'The before-and-afters speak for themselves.',
            subtitle: 'Real results from real daters, across every plan.',
          ),
          const SizedBox(height: AppSpacing.xl),
          const _StatsBand(),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            alignment: WrapAlignment.center,
            children: _stories
                .map((s) => SizedBox(
                      width: isMobile ? double.infinity : 340,
                      child: _StoryCard(story: s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatsBand extends StatelessWidget {
  const _StatsBand();

  static const _stats = [
    ('+127%', 'avg. more matches'),
    ('10k+', 'profiles coached'),
    ('4.9★', 'average rating'),
    ('9 days', 'to first results'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.xxl,
      runSpacing: AppSpacing.lg,
      alignment: WrapAlignment.center,
      children: _stats.map((s) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.romanticGradient.createShader(bounds),
              child: Text(
                s.$1,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.$2,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});
  final _Story story;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierInfo = TierInfo.of(story.tier);
    return HoverScale(
      scale: 1.02,
      child: Container(
        height: 248,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (_) => const Icon(Icons.star_rounded,
                        color: AppColors.accent, size: 18),
                  ),
                ),
                const Spacer(),
                Icon(Icons.format_quote_rounded,
                    color: AppColors.accent.withValues(alpha: 0.5), size: 28),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Text(
                '“${story.quote}”',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: tierInfo.accentColor.withValues(alpha: 0.18),
                  child: Text(
                    story.name.substring(0, 1),
                    style: TextStyle(
                      color: tierInfo.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${story.name}, ${story.age}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _TierBadge(tierInfo: tierInfo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tierInfo});
  final TierInfo tierInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tierInfo.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
            color: tierInfo.accentColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        tierInfo.name,
        style: TextStyle(
          color: tierInfo.accentColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Animated text nav link for the app bar.
class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: _hover ? AppColors.primary : AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _FinalCta extends StatelessWidget {
  const _FinalCta({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    return _Section(
      child: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.xl : AppSpacing.xxl),
        decoration: BoxDecoration(
          gradient: AppColors.romanticGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Your next match is one rewrite away.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Start coaching with DateWise AI in under a minute.',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            HoverScale(
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 4),
                  child: Text('Get started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Professional multi-column footer with brand blurb, link columns, social
/// icons, and a responsive bottom bar.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.onStart,
    required this.onSeePlans,
    required this.onStories,
    required this.onHowItWorks,
  });
  final VoidCallback onStart;
  final VoidCallback onSeePlans;
  final VoidCallback onStories;
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);

    final brand = SizedBox(
      width: isMobile ? double.infinity : 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandMark(onLight: true),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your AI dating coach — brutal honesty, real strategy, and the warmth '
            'of a best friend. Present your most magnetic self.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: const [
              _SocialIcon(Icons.camera_alt_outlined, 'Instagram'),
              _SocialIcon(Icons.alternate_email, 'X / Twitter'),
              _SocialIcon(Icons.music_note, 'TikTok'),
              _SocialIcon(Icons.play_circle_outline, 'YouTube'),
            ],
          ),
        ],
      ),
    );

    final columns = [
      _FooterColumn(
        title: 'Product',
        links: [
          ('How it works', onHowItWorks),
          ('Pricing', onSeePlans),
          ('Stories', onStories),
          ('Start coaching', onStart),
        ],
      ),
      _FooterColumn(
        title: 'Company',
        links: [
          ('About', null),
          ('Careers', null),
          ('Press', null),
        ],
      ),
      _FooterColumn(
        title: 'Legal',
        links: [
          ('Privacy', null),
          ('Terms', null),
          ('Cookies', null),
        ],
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.text,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              Wrap(
                spacing: AppSpacing.xxl,
                runSpacing: AppSpacing.xl,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  brand,
                  ...columns,
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Divider(color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: AppSpacing.md),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.center,
                children: [
                  Text(
                    '© 2026 DateWise AI. All rights reserved.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  if (isMobile) const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Private by design · Your data stays on your device',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});
  final String title;
  final List<(String, VoidCallback?)> links;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.md),
        ...links.map((l) => _FooterLink(label: l.$1, onTap: l.$2)),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: _hover
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatefulWidget {
  const _SocialIcon(this.icon, this.tooltip);
  final IconData icon;
  final String tooltip;

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _hover
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
