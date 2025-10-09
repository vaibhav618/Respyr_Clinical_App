import 'package:get/get.dart';

class ClinicalController extends GetxController {
  var clinicName = ''.obs;
  var phoneNumber = ''.obs;
  var isLoggedIn = false.obs;

  void setClinicData({required String name, required String number}) {
    clinicName.value = name;
    phoneNumber.value = number;
    isLoggedIn.value = true;
  }

  void clearData() {
    clinicName = ''.obs;
    phoneNumber = ''.obs;
    isLoggedIn = false.obs;
  }
}
