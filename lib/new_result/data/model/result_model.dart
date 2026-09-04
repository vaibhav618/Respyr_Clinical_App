/// The scoring API returns the result in one of two shapes:
///   {"status":"success","data":{...}}   (wrapped, older/PHP style)
///   {"data":[{...}]}                     (raw upstream — current Lambda)
/// Return the single result object from either, or null if neither is present.
Map<String, dynamic>? extractResultObject(dynamic json) {
  if (json is! Map) return null;
  final data = json['data'];
  if (data is List && data.isNotEmpty && data.first is Map) {
    return Map<String, dynamic>.from(data.first as Map);
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  return null;
}

// Safe number coercion — the scoring API mixes numbers, numeric strings, empty
// strings and nulls (e.g. "bpm":"" ), which crash `.toInt()` / `as num`.
double _d(dynamic v) => v == null
    ? 0.0
    : (v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0));
double? _dn(dynamic v) => v == null
    ? null
    : (v is num ? v.toDouble() : double.tryParse(v.toString()));
int _i(dynamic v) => v == null
    ? 0
    : (v is num ? v.toInt() : (double.tryParse(v.toString())?.toInt() ?? 0));

class NewResultModel {
  final int status;
  final double acetonePpm;
  final double ppPress;
  final double ethanolPpm;
  final double? battery;
  final double finalTemp;
  final int duration;
  final double? rawMic;
  final double? bmHumid;
  final double bestHumid;
  final int bpm;
  final double? valPress;
  final double? peakPress;
  final double cap;
  final double val1820;
  final double valFinal1820;
  final double mvAcetone;
  final double h2Ppm;
  final int hwid;
  final double? lastMv;
  final double sugarScore;
  final double respiratoryScore;
  final double gutScore;
  final double liverScore;
  final int timestamp;
  final dynamic blowRawValues;
  final BlowArraysFevFvcValues? blowArraysFevFvcValues;


  NewResultModel({
    required this.status,
    required this.acetonePpm,
    required this.ppPress,
    required this.ethanolPpm,
    required this.battery,
    required this.finalTemp,
    required this.duration,
    required this.rawMic,
    required this.bmHumid,
    required this.bestHumid,
    required this.bpm,
    required this.valPress,
    required this.peakPress,
    required this.cap,
    required this.val1820,
    required this.valFinal1820,
    required this.mvAcetone,
    required this.h2Ppm,
    required this.hwid,
    required this.lastMv,
    required this.sugarScore,
    required this.respiratoryScore,
    required this.gutScore,
    required this.liverScore,
    required this.timestamp,
    required this.blowRawValues,
    required this.blowArraysFevFvcValues,
  });

  factory NewResultModel.fromJson(Map<String, dynamic> json) {
    return NewResultModel(
      status: _i(json['status']),
      acetonePpm: _d(json['AcetonePpm']),
      ppPress: _d(json['pp_press']),
      ethanolPpm: _d(json['ethanolPpm']),
      battery: _dn(json['battry']),
      finalTemp: _d(json['finaltemp']),
      duration: _i(json['duration']),
      rawMic: _dn(json['rawmic']),
      bmHumid: _dn(json['bmhumid']),
      bestHumid: _d(json['besthumid']),
      bpm: _i(json['bpm']),
      valPress: _dn(json['valpress']),
      peakPress: _dn(json['peak_press']),
      cap: _d(json['cap']),
      val1820: _d(json['val1820']),
      valFinal1820: _d(json['valFinal1820']),
      mvAcetone: _d(json['MVacetone']),
      h2Ppm: _d(json['H2Ppm']),
      hwid: _i(json['hwid']),
      lastMv: _dn(json['lastmv']),
      sugarScore: _d(json['SugarScore']),
      respiratoryScore: _d(json['RespiratoryScore']),
      gutScore: _d(json['GutScore']),
      liverScore: _d(json['LiverScore']),
      timestamp: _i(json['timestamp']),
      blowRawValues: json['BlowRawValues'],
      blowArraysFevFvcValues: json['Blow_arrays_fev_fvc_values'] != null
          ? BlowArraysFevFvcValues.fromJson(json['Blow_arrays_fev_fvc_values'])
          : null,
    );
  }
}

class BlowArraysFevFvcValues {
  final Map<String, double> comparisonWithPredicted;
  final Map<String, double> predicted;
  final Map<String, double> respyrMeasured;

  BlowArraysFevFvcValues({
    required this.comparisonWithPredicted,
    required this.predicted,
    required this.respyrMeasured,
  });

  factory BlowArraysFevFvcValues.fromJson(Map<String, dynamic> json) {
    return BlowArraysFevFvcValues(
      comparisonWithPredicted: Map<String, double>.from(
          json['Comparison_with_Predicted(%)']?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {}),
      predicted: Map<String, double>.from(
          json['Predicted']?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {}),
      respyrMeasured: Map<String, double>.from(
          json['Respyr_Measured']?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {}),
    );
  }
}

