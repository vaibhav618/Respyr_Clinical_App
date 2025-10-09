class Ticket {
  final String ticketId;
  final String loginId;
  final String title;
  final String description;
  final String image1;
  final String image2;
  final String response;
  final String dateTime;
  final List<TicketStatus> status; // updated

  Ticket({
    required this.ticketId,
    required this.loginId,
    required this.title,
    required this.description,
    required this.image1,
    required this.image2,
    required this.response,
    required this.dateTime,
    required this.status,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'].toString(),
      loginId: json['login_id'],
      title: json['issue_title'] ?? '',
      description: json['issue_description'],
      image1: json['issue_image_1'],
      image2: json['issue_image_2'],
      response: json['response_message'],
      dateTime: json['dttm'],
      status: (json['status'] as List)
          .map((e) => TicketStatus.fromJson(e))
          .toList(),
    );
  }
}

class TicketStatus {
  final String statusName;
  final bool isCompleted;
  final String dateTime;

  TicketStatus({
    required this.statusName,
    required this.isCompleted,
    required this.dateTime,
  });

  factory TicketStatus.fromJson(Map<String, dynamic> json) {
    return TicketStatus(
      statusName: json['status_name'],
      isCompleted: json['is_completed'],
      dateTime: json['date_time'],
    );
  }
}
