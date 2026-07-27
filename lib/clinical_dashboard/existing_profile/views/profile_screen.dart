import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/colors.dart';
import 'package:respyr_clinical/widgets/internet_connectivity_check.dart';
import '../../create_profile/create_profile.dart';
import '../bloc/profile_bloc.dart';
import '../repositories/profile_repository.dart';
import '../widgets/profile_list_tile.dart';

class ExistingProfilesListScreen extends StatelessWidget {
  final String clinicName;
  final bool isCreateAccountButtonShow;
  const ExistingProfilesListScreen({
    required this.clinicName,
    required this.isCreateAccountButtonShow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(ProfileRepository()),
      child: Builder(
        builder: (context) {
          // Load profiles AFTER the BlocProvider is fully in the widget tree
          context.read<ProfileBloc>().add(LoadProfiles(clinicName));

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: Text(
                "Subjects",
                style: GoogleFonts.poppins(
                  color: const Color(0xFF5A5A5A),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.80,
                ),
              ),
            ),
            backgroundColor: Colors.white,
            body: InternetConnectivityHandler(
              isBody: true,
              onConnectivityChanged: (hasInternet) {
                if (hasInternet) {
                  context.read<ProfileBloc>().add(LoadProfiles(clinicName));
                }
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 25,
                    ),
                    child: Container(
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF5F7FA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF86BDFF),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                          hintText: 'Search ‘abc’',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF86BDFF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.60,
                          ),
                        ),
                        onChanged: (query) {
                          context.read<ProfileBloc>().add(
                            SearchProfiles(query),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        if (state is ProfileLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColor.primaryBlueColor,
                            ),
                          );
                        } else if (state is ProfileLoaded) {
                          if (state.filteredProfiles.isEmpty) {
                            return const Center(
                              child: Text('No profiles found.'),
                            );
                          }
                          return ListView.builder(
                            itemCount: state.filteredProfiles.length,
                            itemBuilder: (context, index) {
                              return ProfileListTile(
                                profile: state.filteredProfiles[index],
                                isCreateAccountButtonShow:
                                    isCreateAccountButtonShow,
                                onRegionUpdated: () {
                                  context.read<ProfileBloc>().add(
                                    LoadProfiles(clinicName),
                                  );
                                },
                              );
                            },
                          );
                        } else if (state is ProfileError) {
                          return Center(child: Text(state.message));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton:
                isCreateAccountButtonShow
                    ? FloatingActionButton.extended(
                      onPressed: () async {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateProfile(loginId: clinicName),
                          ),
                        );
                      },
                      label: Text(
                        "Create new profile",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.10,
                          letterSpacing: -0.48,
                        ),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      backgroundColor: Colors.blue,
                    )
                    : SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
