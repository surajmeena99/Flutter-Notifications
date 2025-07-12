import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order List"),
        backgroundColor: Colors.blue,
        actions: [
          ElevatedButton(
            onPressed: addOrder,
            child: Text('Add'),
          )

        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              print("OrderData: $data");
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(data['name'] ?? 'Unnamed Order'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${data['status'] ?? 'Unknown'}'),
                      Text('Order ID: ${doc.id}'),
                    ],
                  ),
                  trailing: Icon(Icons.local_shipping),
                ),
              );
            },
          );
        },
      ),
    );
  }


  Future<void> addOrder() async {
    await FirebaseFirestore.instance.collection('orders').add({
      'name': 'Service 1',
      'status': 'Pending',
      'userId': 'UserId_102',
      'createdAt': FieldValue.serverTimestamp(), // optional for sorting
    });
  }

}
