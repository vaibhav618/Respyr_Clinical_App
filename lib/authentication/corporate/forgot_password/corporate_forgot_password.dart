import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';
import 'dart:convert';

class CorporateForgotPassword extends StatefulWidget {
  const CorporateForgotPassword({super.key});

  @override
  _CorporateForgotPasswordState createState() => _CorporateForgotPasswordState();
}

class _CorporateForgotPasswordState extends State<CorporateForgotPassword> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSuccess = false;

  final String apiEndpoint = Urls.corporateForgotPassword;

  Future<void> handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiEndpoint));
      request.fields['email'] = _emailController.text.trim();

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() => _isSuccess = true);
      } else {
        _showSnackBar(data['message'] ?? "Error occurred", Colors.black);
      }
    } catch (e) {
      _showSnackBar("Check your internet connection", Colors.black);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                _isSuccess ? "Email Sent" : "Forgot\nPassword",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                )
              ),
              const SizedBox(height: 15),
              Text(
                _isSuccess
                    ? "We have sent your password to ${_emailController.text}. Please check your inbox."
                    : "Please enter your corporate email address to receive your password.",
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontSize: 16, height: 1.5
                ),
              ),
              const SizedBox(height: 50),

              if (!_isSuccess) ...[
                // Minimal Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Corporate Email",
                    labelStyle: const TextStyle(color: Colors.black54),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  validator: (value) => (value == null || !value.contains('@')) ? "Enter a valid email" : null,
                ),
                const SizedBox(height: 60),

                // Solid Black Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        :  Text("Send Password", style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600
                    )),
                  ),
                ),
              ] else ...[
                // Success State Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child:  Text(
                      "Back to Login",
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600
                      )
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}