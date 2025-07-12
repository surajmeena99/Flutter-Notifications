import 'package:flutter/material.dart';
import 'package:flutter_notification/features/ticket/models/ticket_model.dart';
import 'package:flutter_notification/features/ticket/services/ticket_service.dart';
import 'package:flutter_notification/features/ticket/views/user/ticket_form_screen.dart';
import 'package:flutter_notification/features/ticket/widgets/ticket_card.dart';
import '../user/ticket_chat_screen.dart';

class TicketDashboardScreen extends StatelessWidget {
  final String userId;
  const TicketDashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Tickets")),
      body: StreamBuilder<List<TicketModel>>(
        stream: TicketService().getUserTickets(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(child: Text("No tickets yet."));
          }
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return TicketCard(
                ticket: ticket,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketChatScreen(ticket: ticket, userId: userId),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketFormScreen(userId: userId),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
