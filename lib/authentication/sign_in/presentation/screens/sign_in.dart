import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/authentication/sign_in/presentation/widgets/sign_in_option_button.dart';

import '../../../../router/app_routers.dart';
import '../../bloc/sign_in_bloc.dart';
import '../../bloc/sign_in_event.dart';
import '../../bloc/sign_in_state.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignInBloc(),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) async {
        if (state.status == SignInStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? "Something went wrong"),
            ),
          );
          return;
        }

        if (state.status == SignInStatus.success) {
          if (!context.mounted) return;

          if (state.selectedType == "clinical") {
            Navigator.pushNamed(context, AppRoutes.clinicalLogin);
          } else if (state.selectedType == "corporate") {
            Navigator.pushNamed(context, AppRoutes.corporateLogin);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: SvgPicture.asset("assets/respyr_logo.svg"),
        ),
        body: BlocBuilder<SignInBloc, SignInState>(
          buildWhen:
              (p, c) =>
                  p.status != c.status || p.selectedType != c.selectedType,
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Text(
                    "Sign in",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 34,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -2.04,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: signInOptionButton(
                      state: state,
                      title: "Clinical",
                      onClick:
                          () => context.read<SignInBloc>().add(
                            const SignInClinicalPressed(),
                          ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "or",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF5A5A5A),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: signInOptionButton(
                      state: state,
                      title: "Corporate",
                      onClick:
                          () => context.read<SignInBloc>().add(
                            const SignInCorporatePressed(),
                          ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
