import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket_model.dart';

class TicketRepository {
  Future<List<Ticket>> fetchTickets(String loginId) async {
    final url = Uri.parse(
      'https://humorstech.com/humors_app/app_final/clinical/api/fetch/fetch_issues2.php',
    );

    final response = await http.post(url, body: {'login_id': loginId});

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'success' && jsonData['tickets'] != null) {
        final tickets = (jsonData['tickets'] as List)
            .map((e) => Ticket.fromJson(e))
            .toList();
        return tickets;
      } else {
        throw Exception('No tickets found');
      }
    } else {
      throw Exception('Failed to fetch tickets');
    }
  }
}
