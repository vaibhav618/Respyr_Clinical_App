import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/clinical_dashboard/views/subject_profile.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import '../bloc/test_log_bloc.dart';
import '../helper/timestamp_helper.dart';
import '../repositories/test_log_repository.dart';

class CompleteTestLog extends StatefulWidget {
  final String loginId;
  const CompleteTestLog({super.key, required this.loginId});

  @override
  State<CompleteTestLog> createState() => _CompleteTestLogState();
}

class _CompleteTestLogState extends State<CompleteTestLog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    //context.read<TestLogBloc>().add(FetchTestLogs(widget.loginId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          "Test Log",
          style: GoogleFonts.poppins(
            color: const Color(0xFF5A5A5A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.80,
          ),
        ),
      ),
      body: SafeArea(
        child: InternetConnectivityHandler(
          isBody: true,
          onConnectivityChanged: (hasInternet) {
            context.read<TestLogBloc>().add(FetchTestLogs(widget.loginId));
          },

          child: BlocBuilder<TestLogBloc, TestLogState>(
            builder: (context, state) {
              if (state is TestLogLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF308BF9)),
                );
              } else if (state is TestLogError) {
                return Center(child: Text(state.message));
              } else if (state is TestLogLoaded) {
                final filteredList =
                    state.filteredList
                        .where((item) => item.profileId.isNotEmpty)
                        .toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF5F7FA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF86BDFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.60,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF86BDFF),
                              ),
                              suffixIcon: Visibility(
                                visible: _controller.text.isNotEmpty,
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _controller.clear();
                                    context.read<TestLogBloc>().add(
                                      FilterTestLogs(''),
                                    );
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: InputBorder.none,
                              hintText: 'Search ‘Sagar’',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF86BDFF),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.60,
                              ),
                            ),
                            onChanged:
                                (value) => context.read<TestLogBloc>().add(
                                  FilterTestLogs(value),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      filteredList.isEmpty
                          ? Column(
                            children: [
                              const SizedBox(height: 50),
                              SvgPicture.asset(
                                "assets/sagar/folder-error-svgrepo-com.svg",
                                width: 100,
                                height: 100,
                                color: const Color(0xFFA1A1A1),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No test history found",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFA1A1A1),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.80,
                                ),
                              ),
                              const SizedBox(height: 50),
                            ],
                          )
                          : ListView.builder(
                            itemCount: filteredList.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];

                              if (item.profileName == "Unknown") {
                                return SizedBox.shrink();
                              }

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SubjectProfileScreen(
                                            clinicName: widget.loginId,
                                            profileName: item.profileId,
                                          ),
                                    ),
                                  );
                                },
                                child: listItem(
                                  formatDateTimeOrRelative(item.timestamp),
                                  item.profileId,
                                  item.profileName,
                                  item.diabeticScore,
                                  item.liverScore,
                                  item.respiratoryScore,
                                  item.gutScore,
                                  item.recordCount,
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget listItem(
    String dateTime,
    String profileId,
    String profileName,
    double diabeticScore,
    double liverScore,
    double respiratoryScore,
    double gutScore,
    int recordCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Patient name",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF535359),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.10,
                  letterSpacing: -0.48,
                ),
              ),
              const SizedBox(width: 16), // Buffer space
              // 👇 Wrapped the right side in Expanded to prevent layout breaking
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      profileName,
                      textAlign: TextAlign.right,
                      overflow:
                          TextOverflow
                              .ellipsis, // Neatly cuts off super long names
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.10,
                        letterSpacing: -0.30,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          // Allows profileId to shrink if the date is long
                          child: Text(
                            profileId,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF535359),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const ShapeDecoration(
                            color: Color(0xFF535359),
                            shape: OvalBorder(),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          // Allow dateTime to truncate safely too
                          child: Text(
                            dateTime,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF535359),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          infoRow("Test done", recordCount.toString()),
          const SizedBox(height: 5),
          infoRow("Sugar score", "${diabeticScore.toStringAsFixed(0)}%"),
          const SizedBox(height: 5),
          infoRow("Liver stress score", "${liverScore.toStringAsFixed(0)}%"),
          const SizedBox(height: 5),
          infoRow(
            "Respiratory score",
            "${respiratoryScore.toStringAsFixed(0)}%",
          ),
          const SizedBox(height: 5),
          infoRow("Gut fermentation score", "${gutScore.toStringAsFixed(0)}%"),
          const SizedBox(height: 20),
          const Divider(indent: 0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 👇 Wraps the label so long names like 'Gut fermentation score' don't push the % off screen
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.10,
              letterSpacing: -0.48,
            ),
          ),
        ),
        const SizedBox(width: 10), // Safe buffer
        Text(
          value,
          style: GoogleFonts.poppins(
            color: const Color(0xFF252525),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.10,
            letterSpacing: -0.30,
          ),
        ),
      ],
    );
  }
}
