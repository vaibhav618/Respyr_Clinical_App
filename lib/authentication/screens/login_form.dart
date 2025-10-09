import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/authentication/screens/terms_privacy_widget.dart';

import '../services/forgot_password.dart';


class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final VoidCallback onLoginPressed;
  final String? adminIdError;
  final String? passwordError;
  final bool isLoading;

  const LoginForm({
    required this.formKey,
    required this.nameController,
    required this.passwordController,
    required this.onLoginPressed,
    required this.adminIdError,
    required this.passwordError,
    required this.isLoading,
    super.key,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Text(
                  "Login with password",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -2.04,
                  ),
                ),
              ),
              SizedBox(height: height * 0.025),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: widget.nameController,
                  style: GoogleFonts.poppins(fontSize: 15, color: Colors.black),
                  decoration: _inputDecoration(
                    "Enter admin id or phone no *",
                    SvgPicture.asset("assets/admin_icon.svg", width: 24, height: 24,),
                    widget.adminIdError,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Admin ID is required'
                      : null,
                ),
              ),
              SizedBox(height: height * 0.025),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: widget.passwordController,
                  obscureText: _obscureText,
                  style: GoogleFonts.poppins(fontSize: 15, color: Colors.black),
                  decoration: _inputDecoration(
                    "Enter password *",
                    SvgPicture.asset("assets/password_icon.svg", width: 24,height: 24,),
                    widget.passwordError,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF737373),
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Password is required'
                      : null,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: height * 0.025),
        GestureDetector(
            onTap: (){
              // Navigate using GetX
              Get.to(
                    () => ForgotPassword(
                ),
              )?.then((_) => ());
            },

            child: Text("Forgot password?",

              style: GoogleFonts.poppins(
                  color: const Color(0xFF308BF9),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.30,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF308BF9)
              ),
            )
        ),
        const Spacer(),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: buildPrivacyText(context),
            ),
            SizedBox(height: height * 0.030),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        backgroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.all(9),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_left_sharp,
                        size: 24,
                        color: Color(0xFF535359),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: (){
                       if(!widget.isLoading){
                         widget.onLoginPressed();
                       }
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF308BF9),
                        padding: const EdgeInsets.all(9),
                      ),
                      child: widget.isLoading ? CircularProgressIndicator(color: Colors.white,) : Icon(
                        Icons.keyboard_arrow_right_sharp,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, SvgPicture icon, String? errorText) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Container(
        padding: const EdgeInsets.all(12), // Adjust padding to control visual size
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: icon,
        ),
      ),
      errorText: errorText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF0F0F0), width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF0F0F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF809BF9), width: 1),
      ),
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFF737373),
        fontSize: 15,
        fontWeight: FontWeight.w300,
        height: 1.10,
        letterSpacing: -0.30,
      ),
      errorStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.red,
      ),
    );
  }

}
