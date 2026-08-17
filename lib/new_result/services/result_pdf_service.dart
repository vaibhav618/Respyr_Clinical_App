import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../common/get_score_title.dart';
import '../../utils/score_color_helper.dart';
import '../../utils/score_status_helper.dart';
import '../data/model/result_model.dart';
import '../data/model/result_profile_data_model.dart';
import '../data/report_texts.dart';
import '../presentation/widgets/custom_result_scorecard.dart'
    show getFullScoreInterpretation;
import '../presentation/widgets/lung_performance_chart.dart';

/// Renders a test result as the full PDF report — everything the result
/// screen shows: subject header, the body diagram with its four scores, the
/// band legend, vitals, per-marker quick interpretations, the exhale curve,
/// the complete four-score interpretation sections (meaning, considerations,
/// clinical tables, correlation, insight), and the full disclaimer and
/// regulatory status.
///
/// All prose is pulled from the same sources the screen renders
/// (getFullScoreInterpretation, report_texts.dart), so paper and screen
/// cannot drift apart.
class ResultPdfService {
  const ResultPdfService._();

  static const PdfColor _blue = PdfColor.fromInt(0xFF308BF9);
  static const PdfColor _ink = PdfColor.fromInt(0xFF252525);
  static const PdfColor _muted = PdfColor.fromInt(0xFF535359);
  static const PdfColor _faint = PdfColor.fromInt(0xFFA1A1A1);
  static const PdfColor _line = PdfColor.fromInt(0xFFE5E7EB);

  static const List<(String, ScoreType)> _categories = [
    ('respiratory', ScoreType.respiratory),
    ('sugar', ScoreType.sugar),
    ('liver', ScoreType.liver),
    ('gut', ScoreType.gut),
  ];

  static Future<Uint8List> build({
    required NewResultModel result,
    required ResultProfileDataModel profile,
    double? bmi,
    double? bmr,
  }) async {
    final DateTime testTime =
        DateTime.fromMillisecondsSinceEpoch(result.timestamp * 1000);

    final doc = pw.Document(
      title: 'Respyr Test Report',
      author: 'Respyr Clinical',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
        footer: _footer,
        // A flat list, one widget per block, so page breaks can fall between
        // blocks — a single tall Column would refuse to split across pages.
        build: (context) => [
          _header(profile, testTime),
          pw.SizedBox(height: 16),
          // The scores lead, each written out on its own row with its value,
          // band, marker reading and one-line interpretation — no diagram.
          _sectionTitle('Scores'),
          _scoresTable(result),
          pw.SizedBox(height: 14),
          _legend(),
          pw.SizedBox(height: 14),
          _vitalsRow(result, bmi, bmr),
          pw.SizedBox(height: 16),
          _breathCurve(result),
          pw.SizedBox(height: 6),
          ..._allScoreSections(result),
          pw.SizedBox(height: 14),
          _sectionTitle('Disclaimer'),
          pw.Paragraph(
            text: _t(kDisclaimerText),
            style: const pw.TextStyle(
              fontSize: 8,
              color: _muted,
              lineSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 8),
          _sectionTitle('Regulatory Status'),
          pw.Paragraph(
            text: _t(kRegulatoryIntro),
            style: const pw.TextStyle(
              fontSize: 8,
              color: _muted,
              lineSpacing: 2,
            ),
          ),
          for (final String bullet in kRegulatoryBullets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '-  ',
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      _t(bullet),
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: _muted,
                        lineSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  static double _scoreFor(NewResultModel result, String category) {
    switch (category) {
      case 'sugar':
        return result.sugarScore;
      case 'liver':
        return result.liverScore;
      case 'gut':
        return result.gutScore;
      case 'respiratory':
      default:
        return result.respiratoryScore;
    }
  }

  static PdfColor _bandColor(double score) {
    return PdfColor.fromInt(ScoreColorHelper.getScoreColor(score).toARGB32());
  }

  static double _peakPressure(NewResultModel result) {
    final List<double> values = result.blowRawValues
        .toString()
        .split(',')
        .map((e) => double.tryParse(e.trim()))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// Replaces characters the PDF's built-in Helvetica has no glyph for —
  /// subscript two, en/em dashes, bullets — which otherwise render as boxes.
  static String _t(String s) {
    return s
        .replaceAll('₂', '2')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('•', '-')
        .replaceAll('≥', '>=')
        .replaceAll('≤', '<=');
  }

  static String _fmt(dynamic v, {int decimals = 2}) {
    final double? d = double.tryParse(v?.toString() ?? '');
    if (d == null) return v?.toString() ?? '-';
    return d
        .toStringAsFixed(decimals)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  // ── Header / footer ──────────────────────────────────────────────────────

  static pw.Widget _header(ResultProfileDataModel profile, DateTime testTime) {
    final String subject = profile.profileName ?? 'Unknown subject';
    final List<String> details = [
      if (profile.subjectId != null) 'ID ${profile.subjectId}',
      if (profile.age != null) '${profile.age} yrs',
      if (profile.gender != null) '${profile.gender}',
      if (profile.height != null) '${profile.height} cm',
      if (profile.weight != null) '${profile.weight} kg',
    ];

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Respyr Clinical - Test Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _blue,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  subject,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                if (details.isNotEmpty)
                  pw.Text(
                    details.join('  |  '),
                    style: const pw.TextStyle(fontSize: 9, color: _muted),
                  ),
                if (profile.clinicName != null)
                  pw.Text(
                    'Clinic: ${profile.clinicName}',
                    style: const pw.TextStyle(fontSize: 9, color: _muted),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                DateFormat('d MMMM yyyy').format(testTime),
                style: const pw.TextStyle(fontSize: 10, color: _ink),
              ),
              pw.Text(
                DateFormat('h:mm a').format(testTime),
                style: const pw.TextStyle(fontSize: 10, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // The build marker exists so a stale-code PDF is provable at a
          // glance — bump the number when iterating on this layout.
          pw.Text(
            'Generated by Respyr Clinical  ·  r10',
            style: const pw.TextStyle(fontSize: 7, color: _faint),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _faint),
          ),
        ],
      ),
    );
  }


  static pw.Widget _legend() {
    pw.Widget segment(String label, String range, PdfColor color) {
      return pw.Expanded(
        child: pw.Column(
          children: [
            pw.Container(height: 4, color: color),
            pw.SizedBox(height: 3),
            pw.Text(
              '$label  $range',
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ],
        ),
      );
    }

    return pw.Row(
      children: [
        segment('Poor', '0-69', const PdfColor.fromInt(0xFFEA5455)),
        pw.SizedBox(width: 4),
        segment('Fair', '70-79', const PdfColor.fromInt(0xFFFFC412)),
        pw.SizedBox(width: 4),
        segment('Good', '80-100', const PdfColor.fromInt(0xFF3EAF58)),
      ],
    );
  }

  // ── Vitals / quick interpretation / curve ────────────────────────────────

  static pw.Widget _vitalsRow(NewResultModel result, double? bmi, double? bmr) {
    final measured = result.blowArraysFevFvcValues?.respyrMeasured;

    pw.Widget stat(String label, String value) => pw.Expanded(
          child: pw.Column(
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                label,
                style: const pw.TextStyle(fontSize: 7, color: _faint),
              ),
            ],
          ),
        );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        children: [
          if (bmi != null) stat('BMI', bmi.toStringAsFixed(1)),
          if (bmr != null) stat('BMR (kcal/day)', bmr.toStringAsFixed(0)),
          if (measured != null) ...[
            stat('FEV1 (L)', _fmt(measured['FEV1(L)'])),
            stat('FVC (L)', _fmt(measured['FVC(L)'])),
            stat('FEV1/FVC (%)', _fmt(measured['FEV1/FVC Ratio(%)'])),
            stat('PEF (L/min)', _fmt(measured['PEF(L/min)'])),
          ],
        ],
      ),
    );
  }

  static pw.Widget _scoresTable(NewResultModel result) {
    final rows = [
      ('Sugar Score', result.sugarScore, 'sugar', 'Acetone',
          result.acetonePpm, 'ppm'),
      ('Liver Stress Score', result.liverScore, 'liver', 'Ethanol',
          result.ethanolPpm, 'ppm'),
      ('Gut Fermentation Score', result.gutScore, 'gut', 'Hydrogen (H2)',
          result.h2Ppm, 'ppm'),
      ('Respiratory Score', result.respiratoryScore, 'respiratory',
          'Peak Pressure', _peakPressure(result), 'hPa'),
    ];

    return pw.Column(
      children: [
        for (final (title, score, category, marker, value, unit) in rows)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: const pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    '${score.toStringAsFixed(0)}%  '
                    '${ScoreStatusHelper.getScoreTitle(score)}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _bandColor(score),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    '$marker\n${value.toStringAsFixed(3)} $unit',
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                ),
                pw.Expanded(
                  flex: 7,
                  child: pw.Text(
                    _t((getFullScoreInterpretation(category, score)['subtitles']
                                as List<String>?)
                            ?.first ?? ''),
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// The exhale flow curve, from the same pressures-to-flow model the in-app
  /// chart uses. Skipped silently if the raw values cannot be parsed.
  static pw.Widget _breathCurve(NewResultModel result) {
    final List<double> pressures = result.blowRawValues
        .toString()
        .split(',')
        .map((e) => double.tryParse(e.trim()))
        .whereType<double>()
        .toList();
    if (pressures.length < 3) return pw.SizedBox();

    final Map<double, double> flow;
    try {
      flow = LungPerformanceChart().calculateLungFlows(
        allPressures: pressures,
      );
    } catch (_) {
      return pw.SizedBox();
    }
    if (flow.length < 2) return pw.SizedBox();

    final points = flow.entries.toList();
    final double minX = points.first.key;
    final double maxX = points.last.key;
    final double minY =
        points.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final double maxY =
        points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double spanX = (maxX - minX) == 0 ? 1 : maxX - minX;
    final double spanY = (maxY - minY) == 0 ? 1 : maxY - minY;

    // A FIXED-height container so the title and the chart are one
    // unbreakable block. A plain wrapper wasn't enough — MultiPage still
    // split the column, stranding the heading at the bottom of one page and
    // the chart on the next; a fixed height cannot be split.
    return pw.Container(
        height: 165,
        child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Lung Performance - Flow (L/s) over time'),
        pw.Container(
          height: 110,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line, width: 1),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          padding: const pw.EdgeInsets.all(8),
          child: pw.CustomPaint(
            size: const PdfPoint(500, 94),
            painter: (canvas, size) {
              canvas
                ..setStrokeColor(_blue)
                ..setLineWidth(1.2);
              for (int i = 0; i < points.length; i++) {
                final double x = (points[i].key - minX) / spanX * size.x;
                final double y = (points[i].value - minY) / spanY * size.y;
                if (i == 0) {
                  canvas.moveTo(x, y);
                } else {
                  canvas.lineTo(x, y);
                }
              }
              canvas.strokePath();
            },
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          '${spanX.toStringAsFixed(1)}s exhale  |  '
          'peak flow ${maxY.toStringAsFixed(2)} L/s',
          style: const pw.TextStyle(fontSize: 7, color: _faint),
        ),
      ],
    ));
  }

  // ── Full per-score sections ──────────────────────────────────────────────

  static String _markerValueLine(NewResultModel result, String category) {
    switch (category) {
      case 'sugar':
        return 'Acetone: ${result.acetonePpm.toStringAsFixed(2)} ppm';
      case 'liver':
        return 'Ethanol: ${result.ethanolPpm.toStringAsFixed(2)} ppm';
      case 'gut':
        return 'Hydrogen: ${result.h2Ppm.toStringAsFixed(2)} ppm';
      case 'respiratory':
      default:
        return 'Peak Pressure: '
            '${_peakPressure(result).toStringAsFixed(3)} hPa';
    }
  }

  static List<pw.Widget> _allScoreSections(NewResultModel result) {
    final List<pw.Widget> sections = [];
    for (final (category, type) in _categories) {
      sections.addAll(_scoreSection(result, category, type));
    }
    return sections;
  }

  /// One score in full, mirroring the score card's order: meaning, the
  /// category aspect, main marker (with the respiratory table where it
  /// applies), considerations, correlation, clinical insight.
  static List<pw.Widget> _scoreSection(
    NewResultModel result,
    String category,
    ScoreType type,
  ) {
    final double score = _scoreFor(result, category);
    final PdfColor band = _bandColor(score);
    final data = getFullScoreInterpretation(category, score);
    final List<String> titles = (data['titles'] as List).cast<String>();
    final List<String> subtitles = (data['subtitles'] as List).cast<String>();

    pw.Widget block(String title, String body) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _t(body),
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _muted,
                  lineSpacing: 2,
                ),
              ),
            ],
          ),
        );

    return [
      // Section heading: score name with its value and band, above a rule in
      // the band's colour.
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 12, bottom: 8),
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: band, width: 1.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              getScoreTitle(isCorporate: false, score: type),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.Text(
              '${score.toStringAsFixed(0)}%  '
              '${ScoreStatusHelper.getScoreTitle(score)}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: band,
              ),
            ),
          ],
        ),
      ),
      if (titles.length > 1 && subtitles.length > 1)
        block(titles[1], subtitles[1]),
      if (titles.isNotEmpty && subtitles.isNotEmpty)
        block(titles[0], subtitles[0]),
      block(
        'Main Marker',
        '${_markerValueLine(result, category)}\n${data['mainMarker']}',
      ),
      if (category == 'respiratory') _respiratoryTable(result),
      if (titles.length > 2 && subtitles.length > 2)
        block(titles[2], subtitles[2]),
      block('Correlation', data['correlation'] as String),
      block('Clinical Insight', data['insight'] as String),
    ];
  }

  static pw.Widget _respiratoryTable(NewResultModel result) {
    final blow = result.blowArraysFevFvcValues;
    if (blow == null) return pw.SizedBox();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.TableHelper.fromTextArray(
        headers: ['Values (Exhale)', 'Respyr Measured', 'Predicted', 'vs Predicted'],
        data: [
          [
            'FEV1 (L)',
            _fmt(blow.respyrMeasured['FEV1(L)']),
            _fmt(blow.predicted['FEV1(L)']),
            '${_fmt(blow.comparisonWithPredicted['FEV1_vs_Predicted'])}%',
          ],
          [
            'FVC (L)',
            _fmt(blow.respyrMeasured['FVC(L)']),
            _fmt(blow.predicted['FVC(L)']),
            '${_fmt(blow.comparisonWithPredicted['FVC_vs_Predicted'])}%',
          ],
          [
            'Ratio (%)',
            _fmt(blow.respyrMeasured['FEV1/FVC Ratio(%)']),
            _fmt(blow.predicted['FEV1/FVC_Ratio(%)']),
            '${_fmt(blow.comparisonWithPredicted['Ratio_vs_Predicted'])}%',
          ],
          [
            'PEF (L/min)',
            _fmt(blow.respyrMeasured['PEF(L/min)']),
            '-',
            '-',
          ],
        ],
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
        cellStyle: const pw.TextStyle(fontSize: 8, color: _muted),
        headerDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 0.8)),
        ),
        border: null,
        rowDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.4)),
        ),
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      ),
    );
  }
}
