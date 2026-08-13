import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../model/OverallDataByDateModel.dart';
import '../views/subject_profile.dart';
import 'dashboard_theme.dart';

/// The day's readings, newest block first, as a tappable list.
///
/// It used to be a 350px-tall scroll area nested inside the page's own scroll,
/// with an OverscrollNotification listener manually pushing leftover drag into
/// the parent to stop it feeling stuck. A capped preview plus a "view all"
/// footer removes the nested scroll entirely, so there is only ever one thing
/// under the reader's thumb.
class TestLogWidget extends StatelessWidget {
  final String loginId;
  final String scoreType;
  final List<ScoreData> scoreData;

  /// Opens the full log. Supplied by the dashboard, which switches to its log
  /// tab — pushing a route from here would stack the log over the bottom bar
  /// that also leads to it.
  final VoidCallback onViewAll;

  /// Rows shown before the list is cut off and handed to the full log.
  static const int previewLimit = 6;

  const TestLogWidget({
    super.key,
    required this.loginId,
    required this.scoreType,
    required this.scoreData,
    required this.onViewAll,
  });

  void _openSubject(BuildContext context, String subjectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectProfileScreen(
          clinicName: loginId,
          profileName: subjectId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool truncated = scoreData.length > previewLimit;
    final List<ScoreData> visible =
        truncated ? scoreData.sublist(0, previewLimit) : scoreData;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashTheme.gutter),
      child: Container(
        decoration: DashTheme.card,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < visible.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: DashTheme.line,
                  indent: 62,
                ),
              _row(context, visible[i]),
            ],
            if (truncated) ...[
              Divider(height: 1, thickness: 1, color: DashTheme.line),
              _viewAllFooter(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _viewAllFooter(BuildContext context) {
    return InkWell(
      onTap: onViewAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "View all ${scoreData.length} tests",
              style: GoogleFonts.poppins(
                color: DashTheme.blue,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DashTheme.blue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ScoreData item) {
    final double score = getScoreByType(item, scoreType);
    final Color band = DashTheme.scoreColor(score);

    return InkWell(
      onTap: () => _openSubject(context, item.profileId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _initialAvatar(item.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: DashTheme.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDate(item.scoreDttm),
                    style: GoogleFonts.poppins(
                      color: DashTheme.faint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // The score reads as a result, so it carries its band colour
            // rather than sitting in grey next to a coloured dot.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: band.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${score.toStringAsFixed(0)}%",
                style: GoogleFonts.poppins(
                  color: band,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DashTheme.faint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialAvatar(String name) {
    final String initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      height: 36,
      width: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DashTheme.blue.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          color: DashTheme.blue,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }

  double getScoreByType(ScoreData item, String scoreType) {
    switch (scoreType.trim()) {
      case 'Sugar score':
        return double.tryParse(item.dbScore) ?? 0.0;
      case 'Liver stress score':
        return double.tryParse(item.liverScore) ?? 0.0;
      case 'Respiratory score':
        return double.tryParse(item.blowScore) ?? 0.0;
      case 'Gut fermentation score':
        return double.tryParse(item.gutScorePer) ?? 0.0;
      default:
        return 0.0;
    }
  }

  String formatDate(String input) {
    try {
      final dt = DateFormat("MM/dd/yyyy HH:mm:ss").parse(input);
      return DateFormat("h:mm a").format(dt);
    } catch (_) {
      return input; // Fallback if parsing fails
    }
  }
}
