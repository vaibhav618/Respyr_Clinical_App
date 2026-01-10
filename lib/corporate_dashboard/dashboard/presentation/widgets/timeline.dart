import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../authentication/corporate/corporate_login/data/response/corporate_login_response.dart';
import '../../data/model/corporate_profile_tests_response.dart';
import 'timeline_item.dart';

class Timeline extends StatelessWidget {
  final List<CorporateProfileTestItem> list;
  final CorporateUserData corporateUserData;
  const Timeline({super.key, required this.list, required this.corporateUserData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: ShapeDecoration(
          color: const Color(0xFFF5F7FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 30,
          children: [
            Text("Timeline",
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.10,
              ),
            ),
            ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index){
                  return TimelineItem(corporateProfileTestItem: list[index], corporateUserData: corporateUserData,);
                }
            )
          ],
        ),
      ),
    );
  }
}
