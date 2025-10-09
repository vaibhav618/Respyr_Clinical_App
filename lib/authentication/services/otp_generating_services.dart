import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:respyr_clinical/shared/urls.dart';
import '../../log_manager/log_manager.dart';

// GENERATING OTP API CODE
class OtpGeneratingServices {
  // Generates a random 4-digit OTP
  String generateOtp() {
    final random = Random();
    final otp = (random.nextInt(9000) + 1000).toString();

    // Log OTP generation (never log the actual OTP for production PHI apps!)
    LogManager().logEvent(
      event: 'OTP_GENERATED',
      status: 'ATTEMPT',
      details: 'OTP generated for sending.',
    );
    return otp;
  }

  Future<bool> requestOtp(String mobileNumber, String otp) async {
    final url = Uri.parse(
      '${Urls.sendOtp}?phone_no=$mobileNumber&country_code=91&otp=$otp',
    );

    // Log OTP request attempt
    LogManager().logEvent(
      event: 'OTP_REQUEST_ATTEMPT',
      apiUrl: url.toString(),
      status: 'ATTEMPT',
      details: 'Attempting to send OTP to $mobileNumber',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'otp_sent') {
          // Log OTP sent successfully
          LogManager().logEvent(
            event: 'OTP_SENT_SUCCESS',
            apiUrl: url.toString(),
            status: 'SUCCESS',
            details: 'OTP sent to $mobileNumber',
          );
          return true;
        } else {
          // Log OTP sending failed
          LogManager().logEvent(
            event: 'OTP_SENT_FAILED',
            apiUrl: url.toString(),
            status: 'FAILED',
            details: 'OTP not sent to $mobileNumber. Response: ${result['status']}',
          );
          return false;
        }
      } else {
        // Log HTTP error
        LogManager().logEvent(
          event: 'OTP_SENT_FAILED',
          apiUrl: url.toString(),
          status: 'FAILED',
          details: 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'} while sending OTP to $mobileNumber',
        );
        return false;
      }
    } catch (e) {
      // Log exception
      LogManager().logEvent(
        event: 'OTP_SENT_EXCEPTION',
        apiUrl: url.toString(),
        status: 'EXCEPTION',
        details: 'Exception: $e while sending OTP to $mobileNumber',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String enteredOtp, String generatedOtp) async {
    // Log OTP verification attempt
    LogManager().logEvent(
      event: 'OTP_VERIFY_ATTEMPT',
      status: 'ATTEMPT',
      details: 'OTP verification attempt',
    );

    final isValid = enteredOtp == generatedOtp;

    // Log result
    LogManager().logEvent(
      event: isValid ? 'OTP_VERIFY_SUCCESS' : 'OTP_VERIFY_FAILED',
      status: isValid ? 'SUCCESS' : 'FAILED',
      details: 'OTP verification result: ${isValid ? 'Matched' : 'Not matched'}',
    );

    return isValid;
  }

  Future<bool> resendOtp(String mobileNumber) async {
    // Log resend attempt
    LogManager().logEvent(
      event: 'OTP_RESEND_ATTEMPT',
      status: 'ATTEMPT',
      details: 'Resend OTP attempt for $mobileNumber',
    );

    final otp = generateOtp();
    final bool isSuccess = await requestOtp(mobileNumber, otp);

    // Log resend result
    LogManager().logEvent(
      event: isSuccess ? 'OTP_RESEND_SUCCESS' : 'OTP_RESEND_FAILED',
      status: isSuccess ? 'SUCCESS' : 'FAILED',
      details: 'Resend OTP result for $mobileNumber: ${isSuccess ? 'Sent' : 'Failed'}',
    );

    return isSuccess;
  }
}
