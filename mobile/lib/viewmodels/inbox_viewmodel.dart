import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendo_core/models/models.dart';
import 'package:attendo_core/models/view_state.dart';
import 'package:attendo_core/utils/app_exception.dart';
import 'package:attendo_core/utils/streams.dart';

import '../providers.dart';

/// Gộp thông báo chung và tin riêng, mới nhất trước (hàm thuần, có test).
List<InboxItem> mergeInbox(List<Announcement> announcements, List<InboxItem> personal) {
  final items = [
    ...personal,
    for (final a in announcements)
      InboxItem(id: a.id, title: a.title, body: a.body, at: a.publishedAt ?? DateTime.now()),
  ];
  items.sort((a, b) => b.at.compareTo(a.at));
  return items;
}

int unreadCount(List<InboxItem> items, DateTime? lastRead) =>
    lastRead == null ? items.length : items.where((i) => i.at.isAfter(lastRead)).length;

final _inboxItemsProvider = StreamProvider<List<InboxItem>>((ref) {
  final user = ref.watch(currentUserProvider.select((u) => u.value == null ? null : (u.value!.uid, u.value!.role)));
  if (user == null) return const Stream<List<InboxItem>>.empty();
  final repo = ref.watch(announcementRepositoryProvider);
  return combineLatest([repo.watchFor(user.$2), repo.watchPersonal(user.$1)])
      .map((v) => mergeInbox(v[0]! as List<Announcement>, v[1]! as List<InboxItem>));
});

/// Số tin chưa đọc: chấm trên nút hộp thư ở Tổng quan.
final inboxUnreadProvider = Provider<int>((ref) {
  final items = ref.watch(_inboxItemsProvider).value ?? const <InboxItem>[];
  return unreadCount(items, ref.watch(currentUserProvider).value?.lastInboxReadAt);
});

final inboxViewModelProvider = NotifierProvider.autoDispose<InboxViewModel, ViewState<List<InboxItem>>>(InboxViewModel.new);

class InboxViewModel extends Notifier<ViewState<List<InboxItem>>> {
  @override
  ViewState<List<InboxItem>> build() {
    final v = ref.watch(_inboxItemsProvider);
    return v.when(
      data: (d) => d.isEmpty ? const Empty() : Ready(d),
      error: (e, _) => Failure(e is AppException ? e.message : 'Có lỗi, hãy thử lại'),
      loading: () => const Loading(),
    );
  }

  /// Ghi nhận đã mở; lỗi mạng không chặn màn vì Firestore tự gửi lại khi có mạng.
  Future<void> markRead() async {
    final uid = ref.read(currentUserProvider).value?.uid;
    if (uid == null) return;
    await ref.read(analyticsServiceProvider).inboxOpen(unread: ref.read(inboxUnreadProvider));
    try {
      await ref.read(userRepositoryProvider).markInboxRead(uid);
    } on AppException {
      // Chấm chưa đọc còn lại tới lần mở sau.
    }
  }

  void retry() => ref.invalidate(_inboxItemsProvider);
}
