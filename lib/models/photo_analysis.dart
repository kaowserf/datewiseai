/// Result of the Magnet-tier photo coach (PRD section 5.3).
///
/// Each uploaded photo receives a 1-10 score, a verdict, and dimension-level
/// feedback across lighting, expression, outfit, framing, and overall vibe.
enum PhotoVerdict {
  keep('KEEP'),
  reshoot('RESHOOT'),
  delete('DELETE');

  const PhotoVerdict(this.label);
  final String label;

  static PhotoVerdict fromScore(int score) {
    if (score >= 8) return PhotoVerdict.keep;
    if (score >= 5) return PhotoVerdict.reshoot;
    return PhotoVerdict.delete;
  }

  static PhotoVerdict fromId(String? id) => PhotoVerdict.values.firstWhere(
    (v) => v.label == id || v.name == id,
    orElse: () => PhotoVerdict.reshoot,
  );
}

class PhotoDimension {
  const PhotoDimension({
    required this.name,
    required this.score,
    required this.note,
  });

  final String name;
  final int score; // 1-10
  final String note;

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'note': note,
  };

  factory PhotoDimension.fromJson(Map<String, dynamic> json) => PhotoDimension(
    name: json['name'] as String,
    score: (json['score'] as num).toInt(),
    note: json['note'] as String,
  );
}

class PhotoAnalysis {
  const PhotoAnalysis({
    required this.overallScore,
    required this.verdict,
    required this.headline,
    required this.dimensions,
    required this.matchRateDelta,
    required this.tips,
  });

  final int overallScore; // 1-10
  final PhotoVerdict verdict;
  final String headline;
  final List<PhotoDimension> dimensions;

  /// Predicted change in match rate if the suggestions are applied, e.g. +18.
  final int matchRateDelta;
  final List<String> tips;

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'verdict': verdict.label,
    'headline': headline,
    'dimensions': dimensions.map((d) => d.toJson()).toList(),
    'matchRateDelta': matchRateDelta,
    'tips': tips,
  };

  factory PhotoAnalysis.fromJson(Map<String, dynamic> json) => PhotoAnalysis(
    overallScore: (json['overallScore'] as num).toInt(),
    verdict: PhotoVerdict.fromId(json['verdict'] as String?),
    headline: json['headline'] as String,
    dimensions: (json['dimensions'] as List)
        .map((d) => PhotoDimension.fromJson(d as Map<String, dynamic>))
        .toList(),
    matchRateDelta: (json['matchRateDelta'] as num).toInt(),
    tips: (json['tips'] as List).map((t) => t as String).toList(),
  );
}
