import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/ticket_model.dart';
import '../repository/ticket_repository.dart';

abstract class TicketState {}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketLoaded extends TicketState {
  final List<Ticket> tickets;

  TicketLoaded({required this.tickets});
}

class TicketError extends TicketState {
  final String message;
  TicketError(this.message);
}

class TicketCubit extends Cubit<TicketState> {
  final TicketRepository repo;

  TicketCubit(this.repo) : super(TicketInitial());

  void loadTickets(String loginId) async {
    try {
      emit(TicketLoading());
      final tickets = await repo.fetchTickets(loginId);
      emit(TicketLoaded(tickets: tickets));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }
}
