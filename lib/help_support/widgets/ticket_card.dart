import 'package:flutter/material.dart';
import '../models/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;

  const TicketCard({required this.ticket, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 2,
      child: ListTile(
        title: Text(ticket.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket.description),
            Text("Status: ${ticket.status}"),
            const SizedBox(height: 8),
            ticket.image1 != "Not Available"
                ? Image.network(ticket.image1, height: 100)
                : const Text("Image 1: Not Available"),
            ticket.image2 != "Not Available"
                ? Image.network(ticket.image2, height: 100)
                : const Text("Image 2: Not Available"),
          ],
        ),
      ),
    );
  }
}
