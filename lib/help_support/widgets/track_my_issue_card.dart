import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/issue_cat_list.dart';
import '../models/ticket_model.dart';
import 'issue_tag_fill.dart';

class TrackMyIssueCard{
  Widget card(
      {
        required String ticketNumber,
        required String ticketDate,
        required String tags,
        required List<TicketStatus> statusList
      }
      ){



    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: const Color(0xFFC7C6CE),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20,vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
                text: TextSpan(
                    children: [
                      TextSpan(text: "Ticket number: ",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.10,
                            letterSpacing: -0.24,
                          )
                      ),
                      TextSpan(text: ticketNumber,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.10,
                            letterSpacing: -0.24,
                          )
                      ),
                    ]
                )
            ),
            SizedBox(height: 9,),
            RichText(
                text: TextSpan(
                    children: [
                      TextSpan(text: "Date of issue raised: ",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.10,
                            letterSpacing: -0.24,
                          )
                      ),
                      TextSpan(text: ticketDate,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.10,
                            letterSpacing: -0.24,
                          )
                      ),
                    ]
                )
            ),
            SizedBox(height: 9,),
            Text("Tags: ",style: GoogleFonts.poppins(
              color: const Color(0xFF252525),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.10,
              letterSpacing: -0.24,
            ),),
            SizedBox(height: 10,),
            issuePillContainer(getMatchingIssues(tags), false),
            SizedBox(height: 19,),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFC7C6CE),
                  ),
                ),
                SizedBox(width: 10,),
                Text("Status",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                    letterSpacing: -0.24,
                  ),
                ),
                SizedBox(width: 10,),
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFC7C6CE),
                  ),
                ),
              ],
            ),
            SizedBox(height: 27,),
            Row(
              children: statusList.map((status) {
                return statusItem(status.statusName, status.isCompleted, status.dateTime);
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget statusItem(String statusType, bool isCompleted, String dateTime){
    return Expanded(
        flex: statusType=="contacted" ? 2:1,
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: statusType =="contacted" ? CrossAxisAlignment.center :statusType =="pending" ? CrossAxisAlignment.start : CrossAxisAlignment.end ,
            children: [
              Text(dateTime=="not_available" ? "\n" :dateTime,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF535359),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  height: 1.10,
                  letterSpacing: -0.20,
                ),
              ),
              SizedBox(height: 5,),
              Row(
                children: [
                  statusType=="contacted"? Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Color(0xFF3EAF58) : Color(0xFFC7C6CE),
                    ),
                  ) : SizedBox.shrink(),

                  statusType=="resolved"? Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Color(0xFF3EAF58) : Color(0xFFC7C6CE),
                    ),
                  ) : SizedBox.shrink(),

                  Container(
                    width: 10,
                    height: 10,
                    decoration: ShapeDecoration(
                      color: isCompleted ? Color(0xFF3EAF58) : Color(0xFFC7C6CE),
                      shape: OvalBorder(),
                    ),
                  ),
                  statusType=="contacted" ? Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Color(0xFF3EAF58) : Color(0xFFC7C6CE),
                    ),
                  ) : SizedBox.shrink(),
                  statusType=="pending"? Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Color(0xFF3EAF58) : Color(0xFFC7C6CE),
                    ),
                  ) : SizedBox.shrink(),

                ],
              ),
              SizedBox(height: 10,),
              Text(
                statusType=="pending" ? "Issue\nraised" :
                statusType=="contacted" ? "Representative\ncontacted" : "Resolved\n",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF252525),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  height: 1.10,
                  letterSpacing: -0.20,
                ),
              )
            ],
          ),
        )
    );
  }
}