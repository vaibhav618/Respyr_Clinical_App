class CorporateInterpretation {
  final bool success;
  final String generatedAt;
  final Disclaimer disclaimer;
  final List<ScoreInterpretation> scores;

  CorporateInterpretation({
    required this.success,
    required this.generatedAt,
    required this.disclaimer,
    required this.scores,
  });

  factory CorporateInterpretation.fromJson(Map<String, dynamic> json) {
    return CorporateInterpretation(
      success: json['success'] == true,
      generatedAt: (json['generated_at'] ?? '').toString(),
      disclaimer: Disclaimer.fromJson(
        (json['disclaimer'] as Map<String, dynamic>? ?? const {}),
      ),
      scores: (json['scores'] as List<dynamic>? ?? const [])
          .map((e) => ScoreInterpretation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'generated_at': generatedAt,
    'disclaimer': disclaimer.toJson(),
    'scores': scores.map((e) => e.toJson()).toList(),
  };
}

class Disclaimer {
  final String toolType;
  final bool notDiagnostic;
  final bool notMedicalAdvice;
  final List<String> doesNotReplaceTests;
  final String note;

  Disclaimer({
    required this.toolType,
    required this.notDiagnostic,
    required this.notMedicalAdvice,
    required this.doesNotReplaceTests,
    required this.note,
  });

  factory Disclaimer.fromJson(Map<String, dynamic> json) {
    return Disclaimer(
      toolType: (json['tool_type'] ?? '').toString(),
      notDiagnostic: json['not_diagnostic'] == true,
      notMedicalAdvice: json['not_medical_advice'] == true,
      doesNotReplaceTests: (json['does_not_replace_tests'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      note: (json['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tool_type': toolType,
    'not_diagnostic': notDiagnostic,
    'not_medical_advice': notMedicalAdvice,
    'does_not_replace_tests': doesNotReplaceTests,
    'note': note,
  };
}

class ScoreInterpretation {
  final String scoreKey;
  final String scoreName;
  final double scoreValue;
  final String category; // Good / Fair / Poor
  final String range; // >80 / 70–79.99 / <70
  final String correlation;
  final MainMarker mainMarker;
  final String wellnessInsight;
  final BandDetails bandDetails;

  ScoreInterpretation({
    required this.scoreKey,
    required this.scoreName,
    required this.scoreValue,
    required this.category,
    required this.range,
    required this.correlation,
    required this.mainMarker,
    required this.wellnessInsight,
    required this.bandDetails,
  });

  factory ScoreInterpretation.fromJson(Map<String, dynamic> json) {
    return ScoreInterpretation(
      scoreKey: (json['score_key'] ?? '').toString(),
      scoreName: (json['score_name'] ?? '').toString(),
      scoreValue: _toDouble(json['score_value']),
      category: (json['category'] ?? '').toString(),
      range: (json['range'] ?? '').toString(),
      correlation: (json['correlation'] ?? '').toString(),
      mainMarker: MainMarker.fromJson(
        (json['main_marker'] as Map<String, dynamic>? ?? const {}),
      ),
      wellnessInsight: (json['wellness_insight'] ?? '').toString(),
      bandDetails: BandDetails.fromJson(
        (json['band_details'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'score_key': scoreKey,
    'score_name': scoreName,
    'score_value': scoreValue,
    'category': category,
    'range': range,
    'correlation': correlation,
    'main_marker': mainMarker.toJson(),
    'wellness_insight': wellnessInsight,
    'band_details': bandDetails.toJson(),
  };
}

class MainMarker {
  final String name;
  final String unit;
  final String sample;

  MainMarker({
    required this.name,
    required this.unit,
    required this.sample,
  });

  factory MainMarker.fromJson(Map<String, dynamic> json) {
    return MainMarker(
      name: (json['name'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      sample: (json['sample'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'sample': sample,
  };
}

class BandDetails {
  final String meaning;
  final String interpretation;
  final String suggestedAction;

  BandDetails({
    required this.meaning,
    required this.interpretation,
    required this.suggestedAction,
  });

  factory BandDetails.fromJson(Map<String, dynamic> json) {
    return BandDetails(
      meaning: (json['meaning'] ?? '').toString(),
      interpretation: (json['interpretation'] ?? '').toString(),
      suggestedAction: (json['suggested_action'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'meaning': meaning,
    'interpretation': interpretation,
    'suggested_action': suggestedAction,
  };
}

/* ---------- helpers ---------- */
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
