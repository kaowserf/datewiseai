import 'package:flutter/material.dart';

/// The three subscription tiers from the PRD (section 4), named to evoke
/// increasing romantic magnetism.
enum SubscriptionTier {
  spark,
  flame,
  magnet;

  static SubscriptionTier fromId(String? id) {
    return SubscriptionTier.values.firstWhere(
      (t) => t.name == id,
      orElse: () => SubscriptionTier.spark,
    );
  }
}

/// A single capability that may be unlocked by a tier.
enum Capability {
  profileAudit('Profile Audit'),
  bioRewrites('Bio Rewrites'),
  openingLines('Opening Lines'),
  dailyTips('Daily Tips'),
  unlimitedChat('Unlimited Chat'),
  conversationScripts('Conversation Scripts'),
  datePlanning('Date Planning'),
  messageReviews('Message Reviews'),
  photoCoach('AI Photo Coach'),
  outfitCritique('Outfit Critique'),
  matchRatePrediction('Match-Rate Prediction'),
  priorityResponse('Priority Response');

  const Capability(this.label);
  final String label;
}

/// Static, immutable description of a tier: pricing, marketing copy, and the
/// exact capability matrix from the PRD pricing table.
class TierInfo {
  const TierInfo({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.description,
    required this.weeklyPrice,
    required this.accentColor,
    required this.capabilities,
    required this.highlights,
    required this.highlight,
    this.topBadge,
    this.dark = false,
  });

  final SubscriptionTier tier;
  final String name;
  final String tagline;

  /// One-line value statement shown under the price.
  final String description;
  final double weeklyPrice;
  final Color accentColor;
  final Set<Capability> capabilities;

  /// Curated, human-readable feature bullets shown on the pricing card.
  final List<String> highlights;

  /// Whether this tier is visually emphasised as the "most popular" choice.
  final bool highlight;

  /// Optional badge shown above the card (e.g. "PHOTO COACH").
  final String? topBadge;

  /// Whether to render the card on a dark surface.
  final bool dark;

  bool can(Capability capability) => capabilities.contains(capability);

  String get priceLabel => '\$${weeklyPrice.toStringAsFixed(2)}';

  static const TierInfo spark = TierInfo(
    tier: SubscriptionTier.spark,
    name: 'Spark',
    tagline: 'Your profile, rewritten.',
    description: 'Perfect to fix a flat profile fast.',
    weeklyPrice: 4.99,
    accentColor: Color(0xFFC99A2E),
    highlight: false,
    highlights: [
      'AI profile audit — bio, prompts, hooks',
      'Personalized bio rewrites for any app',
      'Opening line generator',
      'Daily flirting & confidence tips',
    ],
    capabilities: {
      Capability.profileAudit,
      Capability.bioRewrites,
      Capability.openingLines,
      Capability.dailyTips,
    },
  );

  static const TierInfo flame = TierInfo(
    tier: SubscriptionTier.flame,
    name: 'Flame',
    tagline: 'Coached every step.',
    description: 'Daily coaching for real conversations.',
    weeklyPrice: 7.99,
    accentColor: Color(0xFFCC6B2C),
    highlight: true,
    highlights: [
      'Everything in Spark',
      'Unlimited chat with your AI coach',
      'Conversation scripts & ghosting recovery',
      'Date planning & venue picks',
      'First-message reviews',
    ],
    capabilities: {
      Capability.profileAudit,
      Capability.bioRewrites,
      Capability.openingLines,
      Capability.dailyTips,
      Capability.unlimitedChat,
      Capability.conversationScripts,
      Capability.datePlanning,
      Capability.messageReviews,
    },
  );

  static const TierInfo magnet = TierInfo(
    tier: SubscriptionTier.magnet,
    name: 'Magnet',
    tagline: 'Look unforgettable.',
    description: 'Our highest-converting plan.',
    weeklyPrice: 13.99,
    accentColor: Color(0xFF2A6F97),
    highlight: false,
    dark: true,
    topBadge: 'PHOTO COACH',
    highlights: [
      'Everything in Flame',
      'AI Photo Coach — upload your pics for instant feedback',
      'Outfit, lighting, pose & expression critique',
      'Match-rate prediction per photo',
      'Profile-order optimization',
      'Priority response time',
    ],
    capabilities: {
      Capability.profileAudit,
      Capability.bioRewrites,
      Capability.openingLines,
      Capability.dailyTips,
      Capability.unlimitedChat,
      Capability.conversationScripts,
      Capability.datePlanning,
      Capability.messageReviews,
      Capability.photoCoach,
      Capability.outfitCritique,
      Capability.matchRatePrediction,
      Capability.priorityResponse,
    },
  );

  static const List<TierInfo> all = [spark, flame, magnet];

  static TierInfo of(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.spark:
        return spark;
      case SubscriptionTier.flame:
        return flame;
      case SubscriptionTier.magnet:
        return magnet;
    }
  }
}

/// The full feature matrix rendered in the pricing comparison table.
const List<Capability> kComparisonFeatures = [
  Capability.profileAudit,
  Capability.bioRewrites,
  Capability.openingLines,
  Capability.dailyTips,
  Capability.unlimitedChat,
  Capability.conversationScripts,
  Capability.datePlanning,
  Capability.messageReviews,
  Capability.photoCoach,
  Capability.outfitCritique,
  Capability.matchRatePrediction,
  Capability.priorityResponse,
];
