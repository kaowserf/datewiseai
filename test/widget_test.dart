// Basic smoke tests for DateWise AI.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:datewise_ai/models/photo_analysis.dart';
import 'package:datewise_ai/models/tier.dart';
import 'package:datewise_ai/screens/landing_screen.dart';
import 'package:datewise_ai/services/mock_ai_service.dart';
import 'package:datewise_ai/services/storage_service.dart';
import 'package:datewise_ai/state/app_state.dart';

void main() {
  testWidgets('Landing page renders the hero', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final state = AppState(storage: storage, ai: MockAIService());

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: LandingScreen()),
        ),
      );
      await tester.pump();
    });

    // Hero copy + primary CTAs are above the fold in the test viewport.
    expect(find.textContaining('matched'), findsWidgets);
    expect(find.text('Start your free session'), findsOneWidget);
    expect(find.text('See pricing'), findsOneWidget);
  });

  test('Tier capability gating matches the PRD matrix', () {
    expect(TierInfo.spark.can(Capability.unlimitedChat), isFalse);
    expect(TierInfo.flame.can(Capability.unlimitedChat), isTrue);
    expect(TierInfo.flame.can(Capability.photoCoach), isFalse);
    expect(TierInfo.magnet.can(Capability.photoCoach), isTrue);
  });

  test('Mock photo analysis is deterministic per image', () async {
    final ai = MockAIService();
    const img = 'AAAABBBBCCCCDDDDEEEEFFFFGGGG';
    final a = await ai.analyzePhoto(imageBase64: img, tier: SubscriptionTier.magnet);
    final b = await ai.analyzePhoto(imageBase64: img, tier: SubscriptionTier.magnet);
    expect(a.overallScore, b.overallScore);
    expect(a.overallScore, inInclusiveRange(1, 10));
    expect(PhotoVerdict.values, contains(a.verdict));
  });
}
