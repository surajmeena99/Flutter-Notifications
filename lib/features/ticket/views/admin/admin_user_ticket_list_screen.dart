import 'package:flutter/material.dart';
import 'package:flutter_notification/features/ticket/models/ticket_model.dart';
import 'package:flutter_notification/features/ticket/services/ticket_service.dart';
import 'package:flutter_notification/features/ticket/widgets/ticket_card.dart';
import 'admin_chat_screen.dart';

class AdminUserTicketListScreen extends StatelessWidget {
  final String userId;
  const AdminUserTicketListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tickets for User: $userId")),
      body: StreamBuilder<List<TicketModel>>(
        stream: TicketService().getTicketsByUser(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tickets = snapshot.data!;
          if (tickets.isEmpty) return const Center(child: Text("No tickets found."));

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return TicketCard(
                ticket: ticket,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminChatScreen(ticket: ticket),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
