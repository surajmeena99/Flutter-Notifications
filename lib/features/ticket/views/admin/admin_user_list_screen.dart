import 'package:flutter/material.dart';
import 'package:flutter_notification/features/ticket/services/ticket_service.dart';
import 'admin_user_ticket_list_screen.dart';

class AdminUserListScreen extends StatelessWidget {
  const AdminUserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users With Tickets")),
      body: FutureBuilder<List<String>>(
        future: TicketService().getAllTicketUserIds(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userIds = snapshot.data!;
          if (userIds.isEmpty) return const Center(child: Text("No users found."));

          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              final userId = userIds[index];
              return ListTile(
                title: Text("User ID: $userId"),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUserTicketListScreen(userId: userId),
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
