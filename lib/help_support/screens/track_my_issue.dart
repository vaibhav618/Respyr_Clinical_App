import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:respyr_clinical/shared/colors.dart';

import '../bloc/ticket_bloc.dart';
import '../repository/ticket_repository.dart';
import '../widgets/track_my_issue_card.dart';

class TrackMyIssue extends StatefulWidget {
  final String loginId;
  const TrackMyIssue({super.key, required this.loginId});

  @override
  State<TrackMyIssue> createState() => _TrackMyIssueState();
}

class _TrackMyIssueState extends State<TrackMyIssue> {
  late TicketCubit ticketCubit;

  @override
  void initState() {
    super.initState();
    ticketCubit = TicketCubit(TicketRepository());
    ticketCubit.loadTickets(widget.loginId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ticketCubit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
        child: BlocBuilder<TicketCubit, TicketState>(
          builder: (context, state) {
            if (state is TicketLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColor.primaryBlueColor,
                ),
              );
            } else if (state is TicketLoaded) {
              return ListView(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search by ticket number",
                      hintStyle: GoogleFonts.poppins(
                        color: Color(0xFF535359),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.10,
                        letterSpacing: -0.30,
                      ),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: const Color(0xFFC9E1FF),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: const Color(0xFFC9E1FF),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: const Color(0xFFC9E1FF),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  ListView.builder(
                    itemCount: state.tickets.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final ticket = state.tickets[index];
                      return TrackMyIssueCard().card(
                        ticketNumber: ticket.ticketId,
                        ticketDate: ticket.dateTime,
                        tags: ticket.title,
                        statusList: ticket.status,
                      );
                    },
                  ),
                ],
              );
            } else if (state is TicketError) {
              return Center(child: Text("Error: ${state.message}"));
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }
}

// Card(
// margin: const EdgeInsets.symmetric(vertical: 8),
// child: Padding(
// padding: const EdgeInsets.all(12),
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Text(
// ticket.title,
// style: const TextStyle(
// fontSize: 16, fontWeight: FontWeight.bold),
// ),
// const SizedBox(height: 4),
// Text(ticket.description),
// const SizedBox(height: 8),
// Text("Date: ${ticket.dateTime}"),
// const SizedBox(height: 8),
// const Text(
// "Status Progress:",
// style: TextStyle(fontWeight: FontWeight.bold),
// ),
// Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: ticket.status.map((s) {
// return Row(
// children: [
// Icon(
// s.isCompleted
// ? Icons.check_circle
//     : Icons.radio_button_unchecked,
// color: s.isCompleted
// ? Colors.green
//     : Colors.grey,
// ),
// const SizedBox(width: 6),
// Text("${s.statusName} (${s.dateTime})"),
// ],
// );
// }).toList(),
// ),
// ],
// ),
// ),
// )
