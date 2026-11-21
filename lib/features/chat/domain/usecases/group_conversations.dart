import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';

/// Groups [inquiries] into conversations — one per other party, however many
/// inquiries (one per medicine) they have — each with its inquiries newest
/// first, and the most recently active conversation first.
///
/// What an inquiry is differs per side (a patient's inquiry to a pharmacy, a
/// pharmacy's inquiry from a patient), so each says how to read one: its
/// [groupKey] (who the other party is), [id], [createdAt] and [unreadCount],
/// and from a conversation's latest inquiry its [title] and [lastText].
List<ChatConversation> groupConversations<T>(
  List<T> inquiries, {
  required Object Function(T inquiry) groupKey,
  required int Function(T inquiry) id,
  required DateTime Function(T inquiry) createdAt,
  required int Function(T inquiry) unreadCount,
  required String Function(T latest) title,
  required String Function(T latest) lastText,
}) {
  final byParty = <Object, List<T>>{};
  for (final inquiry in inquiries) {
    byParty.putIfAbsent(groupKey(inquiry), () => []).add(inquiry);
  }

  final groups = [
    for (final list in byParty.values) [...list]..sort((a, b) => createdAt(b).compareTo(createdAt(a))),
  ]..sort((a, b) => createdAt(b.first).compareTo(createdAt(a.first)));

  return [
    for (final group in groups)
      ChatConversation(
        title: title(group.first),
        lastText: chatPreviewText(lastText(group.first)),
        unreadCount: group.fold(0, (sum, inquiry) => sum + unreadCount(inquiry)),
        inquiryIds: [for (final inquiry in group) id(inquiry)],
        lastActivity: createdAt(group.first),
      ),
  ];
}
