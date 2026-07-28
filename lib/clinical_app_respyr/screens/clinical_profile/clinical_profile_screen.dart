import 'package:flutter/material.dart';
import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:respyr_clinical/clinical_app_respyr/screens/clinical_profile/clinical_profile_view.dart';
import 'package:respyr_clinical/clinical_app_respyr/services/clinical_profile_fetch_api.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../../../new_result/data/model/result_profile_data_model.dart';

class ClinicalProfileScreen extends StatefulWidget {
  final bool isClinicalTest;
  const ClinicalProfileScreen({super.key, this.isClinicalTest = false});

  @override
  State<ClinicalProfileScreen> createState() => _ClinicalProfileScreenState();
}

class _ClinicalProfileScreenState extends State<ClinicalProfileScreen>
    with SingleTickerProviderStateMixin {
  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  List<ResultProfileDataModel> _profiles = [];
  List<ResultProfileDataModel> _searchProfile = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _searchController.addListener(() {
      _searchProfiles(_searchController.text);
    });
  }

  void _handleTap() {
    Get.to(() => ClinicalProfileScreen());
  }

  Future<void> _loadProfile() async {
    try {
      final profiles = await ClinicalProfileApi.fetchProfiles("OFFC");

      // Sort by descending date
      profiles.sort((a, b) {
        final dateA = DateTime.tryParse(a.dttm ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b.dttm ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA); // Newest first
      });

      setState(() {
        _profiles = profiles;
        _searchProfile = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error Loading profiles: $e");
    }
  }

  void _searchProfiles(String query) {
    final filtered =
        _profiles.where((profile) {
          final name = profile.profileName?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();

    setState(() {
      _searchProfile = filtered;
    });
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '';

    try {
      final DateTime parseDate = DateTime.parse(dateTimeString);

      return DateFormat("MMM d, h:mm a").format(parseDate);
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.whiteColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'All Profiles',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColor.primaryBlackColor,
          ),
        ),
        backgroundColor: AppColor.whiteColor,
        surfaceTintColor: AppColor.whiteColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                TextFormField(
                  focusNode: _textFocusNode,
                  controller: _searchController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 15,
                    ),
                    hintText: 'Search profiles',
                    hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF87BDFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: SvgPicture.asset(
                        'assets/clinical_search_icon.svg',
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                  ),
                ),
                const SizedBox(height: 15),
                _isLoading
                    ? const ListShimmer(
                      rows: 6,
                      rowHeight: 64,
                      padding: EdgeInsets.zero,
                    )
                    : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final profile = _searchProfile[index];

                        return InkWell(
                          onTap: () {
                            Get.to(
                              () =>
                                  widget.isClinicalTest
                                      ? ClinicalProfileView(
                                        isClinicalTest: true,
                                        profileDetails: profile,
                                      )
                                      : ClinicalProfileView(
                                        profileDetails: profile,
                                      ),
                            );
                          },
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset('assets/profile_list.svg'),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.profileName ?? 'Unknown',
                                        style: GoogleFonts.poppins(
                                          color: AppColor.primaryBlackColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(profile.dttm),
                                        style: GoogleFonts.poppins(
                                          color: AppColor.primaryBlackColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  SvgPicture.asset(
                                    'assets/svg_icons/right_arrow_button.svg',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (c, _) {
                        return const SizedBox(height: 25);
                      },
                      itemCount: _searchProfile.length,
                    ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton:
          widget.isClinicalTest
              ? GestureDetector(
                onTap: _handleTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FloatingActionButton.extended(
                    onPressed: null, // Disable default onPressed
                    label: Row(
                      children: [
                        Icon(Icons.add, color: AppColor.whiteColor),
                        const SizedBox(width: 8),
                        Text(
                          "Create Profile",
                          style: GoogleFonts.poppins(
                            color: AppColor.whiteColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColor.primaryBlueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              )
              : null,
    );
  }
}
