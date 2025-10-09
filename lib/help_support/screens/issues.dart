import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/help_support/screens/track_my_issue.dart';
import 'package:tab_container/tab_container.dart';
import 'raise_ticket.dart';

class Issues extends StatefulWidget {
  final String loginId;
  const Issues({super.key, required this.loginId});

  @override
  State<Issues> createState() => _IssuesState();
}

class _IssuesState extends State<Issues> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    Map<String, Color> tabs = {
      'New issue': Colors.white,
      'Track my issues': Colors.white,
    };
    return Scaffold(
      backgroundColor:const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:const Color(0xFFF5F7FA),
        surfaceTintColor:const Color(0xFFF5F7FA),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Text("Report An Issue",
              style: GoogleFonts.poppins(
                color: const Color(0xFF252525),
                fontSize: 34,
                fontWeight: FontWeight.w400,
                letterSpacing: -2.04,
              ),
            ),
          ),
          SizedBox(height: 19,),
          Expanded(
            child: TabContainer(
              selectedTextStyle:GoogleFonts.poppins(
                color: const Color(0xFF308BF9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.10,
                letterSpacing: -0.30,
              ),
              unselectedTextStyle: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.10,
                letterSpacing: -0.30,
              ),
              borderRadius: BorderRadius.circular(20),
              curve: Curves.easeIn,
              tabEdge: TabEdge.top,
              transitionBuilder: (Widget child, Animation<double> animation) {
                animation = CurvedAnimation(
                  curve: Curves.easeIn,
                  parent: animation,
                );
            
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(0.2, 0.0),
                    end: const Offset(0.0, 0.0),
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              colors: List.generate(
                tabs.length,
                    (int index) => tabs.values.elementAt(index),
              ),
              tabs: List.generate(
                tabs.length,
                    (int index) => Text(tabs.keys.elementAt(index)),
              ),
              children: List.generate(
                tabs.length,
                    (int index) => SizedBox(// or a fixed height like 400
                  child: index ==0 ? RaiseTicket(loginId: widget.loginId,) : TrackMyIssue(loginId: widget.loginId,),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



