import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';
import '../models/message_model.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _ticketCollection =
  FirebaseFirestore.instance.collection('tickets');

  /// Create a new ticket
  Future<void> createTicket(TicketModel ticket) async {
    final docRef = _ticketCollection.doc();
    await docRef.set(ticket.toMap());
  }

  /// Get all tickets of a user
  Stream<List<TicketModel>> getUserTickets(String userId) {
    return _ticketCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Get all users who have raised tickets (distinct userIds)
  Future<List<String>> getAllTicketUserIds() async {
    final snapshot = await _ticketCollection.get();
    final userIds = snapshot.docs.map((doc) => doc['userId'].toString()).toSet().toList();
    return userIds;
  }

  /// Get all tickets of a specific user (admin view)
  Stream<List<TicketModel>> getTicketsByUser(String userId) {
    return _ticketCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Get real-time messages for a ticket
  Stream<List<MessageModel>> getMessages(String ticketId) {
    return _ticketCollection
        .doc(ticketId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Send message to a ticket
  Future<void> sendMessage(String ticketId, MessageModel message) async {
    final messageRef = _ticketCollection.doc(ticketId).collection('messages').doc();
    await messageRef.set(message.toMap());

    // Also update ticket updatedAt field
    await _ticketCollection.doc(ticketId).update({
      'updatedAt': message.sentAt,
    });
  }

  /// Close a ticket
  Future<void> closeTicket(String ticketId) async {
    await _ticketCollection.doc(ticketId).update({'status': 'closed'});
  }

  /// Re-open a ticket
  Future<void> reopenTicket(String ticketId) async {
    await _ticketCollection.doc(ticketId).update({'status': 'open'});
  }

  /// Get a single ticket by ID
  Future<TicketModel?> getTicketById(String ticketId) async {
    final doc = await _ticketCollection.doc(ticketId).get();
    if (doc.exists) {
      return TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
