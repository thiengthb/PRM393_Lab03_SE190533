/// Trạng thái tải dữ liệu của một màn (đề Lab 3 mục 5: mỗi màn có state model rõ ràng).
/// Tương ứng hậu tố Lab 2: .L Loading, .E Empty, .X Failure, .D Ready.
sealed class ViewState<T> {
  const ViewState();

  bool get isLoading => this is Loading<T>;
  T? get dataOrNull => switch (this) {
        Ready<T>(:final data) => data,
        _ => null,
      };
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

final class Empty<T> extends ViewState<T> {
  const Empty([this.kind = EmptyKind.none]);
  final EmptyKind kind;
}

/// .E (không có gì hôm nay) khác .E2 (kỳ chưa có lớp): màn hiện nút Nhập.
enum EmptyKind { none, noClasses }

final class Failure<T> extends ViewState<T> {
  const Failure(this.message, {this.canRetry = true});
  final String message;
  final bool canRetry;
}

final class Ready<T> extends ViewState<T> {
  const Ready(this.data);
  final T data;
}
