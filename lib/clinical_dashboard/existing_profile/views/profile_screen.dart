import 'dart:async';
import 'package:flutter/material.dart';
import 'package:respyr_clinical/widgets/shimmer_placeholders.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import '../../create_profile/create_profile.dart';
import '../bloc/profile_bloc.dart';
import '../repositories/profile_repository.dart';
import '../widgets/profile_list_tile.dart';

class ExistingProfilesListScreen extends StatefulWidget {
  final String clinicName;
  final bool isCreateAccountButtonShow;
  const ExistingProfilesListScreen({
    required this.clinicName,
    required this.isCreateAccountButtonShow,
    super.key,
  });

  @override
  State<ExistingProfilesListScreen> createState() =>
      _ExistingProfilesListScreenState();
}

class _ExistingProfilesListScreenState
    extends State<ExistingProfilesListScreen> {
  // Debounces the search field so we don't fire a server query on every
  // keystroke — only ~400ms after the user stops typing.
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(BuildContext blocContext, String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      blocContext.read<ProfileBloc>().add(SearchProfiles(query));
    });
  }

  /// Covers both "this clinic has no subjects yet" and "the search matched
  /// nothing" — the previous bare "No profiles found." gave no sense of which.
  Widget _emptyState() {
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
                color: const Color(0xFF308BF9).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: Color(0xFF308BF9),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No subjects found",
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Try a different name or ID, or add a new subject.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Footer under the list: a spinner while the next page auto-loads on scroll.
  Widget _listFooter(ProfileLoaded state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFF308BF9),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Load once, when the bloc is created. Dispatching from inside build()
      // re-fetched the whole subject list from the network on every rebuild —
      // including every keystroke in the search field, since that rebuilds
      // this subtree.
      create: (_) =>
          ProfileBloc(ProfileRepository())..add(LoadProfiles(widget.clinicName)),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: Text(
                "Subjects",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.80,
                ),
              ),
            ),
            // Light background so the subject cards read as cards.
            backgroundColor: const Color(0xFFF5F7FA),
            body: InternetConnectivityHandler(
              isBody: true,
              onConnectivityChanged: (hasInternet) {
                if (hasInternet) {
                  context.read<ProfileBloc>().add(
                    LoadProfiles(widget.clinicName),
                  );
                }
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF252525),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFFA1A1A1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          hintText: 'Search by name or ID',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFFA1A1A1),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        onChanged: (query) => _onSearchChanged(context, query),
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        if (state is ProfileLoading) {
                          return const ListShimmer(rows: 7, rowHeight: 76);
                        } else if (state is ProfileLoaded) {
                          if (state.profiles.isEmpty) {
                            return _emptyState();
                          }
                          // Auto-load the next page when scrolled near the end.
                          return NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.pixels >=
                                      n.metrics.maxScrollExtent - 400 &&
                                  state.hasMore &&
                                  !state.isLoadingMore) {
                                context.read<ProfileBloc>().add(
                                  LoadMoreProfiles(),
                                );
                              }
                              return false;
                            },
                            // +1 row for the loading spinner footer.
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 90),
                              itemCount: state.profiles.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index >= state.profiles.length) {
                                  return _listFooter(state);
                                }
                                return ProfileListTile(
                                  profile: state.profiles[index],
                                  isCreateAccountButtonShow:
                                      widget.isCreateAccountButtonShow,
                                  onRegionUpdated: () {
                                    context.read<ProfileBloc>().add(
                                      LoadProfiles(widget.clinicName),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        } else if (state is ProfileError) {
                          return Center(
                            child: Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF535359),
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton:
                widget.isCreateAccountButtonShow
                    ? FloatingActionButton.extended(
                      onPressed: () async {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateProfile(loginId: widget.clinicName),
                          ),
                        );
                      },
                      label: Text(
                        "Create new profile",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.20,
                        ),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      // Primary Blue, not Colors.blue — the latter is off-palette.
                      backgroundColor: const Color(0xFF308BF9),
                    )
                    : SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
