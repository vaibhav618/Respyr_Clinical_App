import 'dart:convert';

import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../clinical_dashboard/clinic_details/model/clinical_details_model.dart';
import 'package:respyr_clinical/shared/nodeurl.dart';
import '../clinical_dashboard/widgets/clinical_logo_widget.dart';
import '../clinical_dashboard/widgets/test_details_widget.dart';
import '../common/auth_logout.dart';
import '../help_support/screens/help_center.dart';
import '../widgets/logout_bpx.dart';

class MenuScreen extends StatefulWidget {
  final String loginId;
  final Map<String, dynamic>? clinicalTestCountData;
  final int totalSubjectsOnboarded;
  const MenuScreen({
    super.key,
    required this.loginId,
    required this.clinicalTestCountData,
    required this.totalSubjectsOnboarded,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const Color _blue = Color(0xFF308BF9);
  static const Color _ink = Color(0xFF252525);
  static const Color _muted = Color(0xFF535359);
  static const Color _line = Color(0xFFE5E7EB);
  static const Color _red = Color(0xFFEA5455);

  bool _hasInternet = true;
  bool _hasFetchedInitialData = false;
  Future<List<ClinicalDetailsModel>>? _clinicDataFuture;

  @override
  void initState() {
    super.initState();
    _startFetchIfNeeded();
  }

  void _startFetchIfNeeded() {
    if (!_hasFetchedInitialData && _hasInternet) {
      setState(() {
        _clinicDataFuture = fetchClinicData(clinicName: widget.loginId);
        _hasFetchedInitialData = true;
      });
    }
  }

  Future<List<ClinicalDetailsModel>> fetchClinicData({
    required String clinicName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("No token found");
    }

    final response = await http.post(
      Uri.parse(NodeUrls.fetchClinicDetails),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'clinic_name': clinicName}),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200 && decoded['status'] == 'success') {
      return List<ClinicalDetailsModel>.from(
        (decoded['data'] as List).map((e) => ClinicalDetailsModel.fromJson(e)),
      );
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matches the dashboard, so the white blocks below read as cards. The
      // screen used to be white-on-white, which left the clinic details and
      // the usage meter floating with nothing to sit on.
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          "Account",
          style: GoogleFonts.poppins(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _line),
        ),
      ),
      body: InternetConnectivityHandler(
        isBody: true,
        onConnectivityChanged: (hasInternet) {
          _hasInternet = hasInternet;

          if (hasInternet) {
            _hasFetchedInitialData = false; // allow one more fetch
            _startFetchIfNeeded();
          }
        },

        child: FutureBuilder<List<ClinicalDetailsModel>>(
          future: _clinicDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: ListShimmer(rows: 6, rowHeight: 56),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return _errorState();
            }

            final clinic = snapshot.data!.first;

            // Scrolls when the content is tall, but keeps logout and the
            // version pinned to the bottom when it is not — the Stack this
            // replaced overlapped the two on short screens.
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            _clinicCard(clinic),
                            const SizedBox(height: 12),
                            TestDetailsWidget(
                              clinicalTestCountData:
                                  widget.clinicalTestCountData,
                              totalSubjectsOnboarded:
                                  widget.totalSubjectsOnboarded,
                            ),
                            const SizedBox(height: 12),
                            if (_hasHiddenActions) ...[
                              _actionsCard(clinic),
                              const SizedBox(height: 12),
                            ],
                            // Logout sits alone at the very bottom, away from
                            // anything else tappable.
                            const Spacer(),
                            const SizedBox(height: 24),
                            _logoutCard(),
                            const SizedBox(height: 14),
                            _versionLabel(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Identity card: badge and clinic name, with the subject count filling the
  /// right-hand side.
  ///
  /// The row was left half-blank when it held only a name and a phone number.
  /// Centring it and enlarging the badge filled the space but made the card
  /// far too tall for what it says. Putting the count on the right instead
  /// uses the width at the original height, and matches the value-over-caption
  /// stat used in the dashboard header.
  Widget _clinicCard(ClinicalDetailsModel clinic) {
    // `total_profiles` comes from this screen's own fetch, so it is the value
    // to trust. The count passed in from the dashboard is a snapshot taken
    // during that screen's build and is still 0 if its data had not landed.
    final int subjects = clinic.totalProfiles > 0
        ? clinic.totalProfiles
        : widget.totalSubjectsOnboarded;

    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          ClinicLogoWidget(
            clinicName: clinic.clinicName,
            size: 54,
            elevated: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clinic.clinicName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                // Phone only. `location` is also on the model, but nothing in
                // this app ever writes it — clinic accounts are provisioned
                // server-side, so its contents are unverified free text.
                if (clinic.phoneNo.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.call_rounded,
                        size: 12,
                        color: Color(0xFFA1A1A1),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          clinic.phoneNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 38, color: _line),
          const SizedBox(width: 12),
          _subjectStat(subjects),
        ],
      ),
    );
  }

  Widget _subjectStat(int subjects) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          subjects.toString(),
          style: GoogleFonts.poppins(
            color: _blue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "SUBJECTS",
          style: GoogleFonts.poppins(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  // Both entries below are switched off, as they were before. The card is
  // skipped entirely rather than rendering an empty bordered box.
  static const bool _hasHiddenActions = false;

  Widget _actionsCard(ClinicalDetailsModel clinic) {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _menuTile(
            icon: Icons.help_outline_rounded,
            label: "Help Center",
            onTap: () => _openHelpCenter(clinic.clinicName),
          ),
          Divider(height: 1, thickness: 1, color: _line, indent: 50),
          _menuTile(
            icon: Icons.flag_outlined,
            label: "Report an Issue",
            onTap: () => _openHelpCenter(widget.loginId),
          ),
        ],
      ),
    );
  }

  Widget _logoutCard() {
    return _card(
      padding: EdgeInsets.zero,
      child: _menuTile(
        icon: Icons.logout_rounded,
        label: "Logout",
        danger: true,
        onTap: () {
          LogoutBox().showDialogBox(
            context: context,
            clinicName: widget.loginId,
            onLogoutClick: () {
              AuthLogout.logout(context);
            },
          );
        },
      ),
    );
  }

  void _openHelpCenter(String loginId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HelpCenter(loginId: loginId)),
    );
  }

  /// Rows were ElevatedButtons with a transparent background, which meant an
  /// unpredictable tap area and no divider between them.
  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final Color tint = danger ? _red : _ink;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: tint,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (!danger)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFA1A1A1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, required EdgeInsets padding}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: child,
      ),
    );
  }

  Widget _versionLabel() {
    return FutureBuilder<String>(
      future: getAppVersion(),
      builder: (context, snapshot) {
        final String version = snapshot.hasData ? snapshot.data! : "—";
        return Center(
          child: Text(
            "App version $version",
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFFA1A1A1),
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }

  /// The old failure path was a bare centred sentence with no way out of it
  /// but the back button.
  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: _blue,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load clinic details",
              style: GoogleFonts.poppins(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Check your connection and try again.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _hasFetchedInitialData = false;
                });
                _startFetchIfNeeded();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                side: const BorderSide(color: _blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
              ),
              child: Text(
                "Retry",
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
