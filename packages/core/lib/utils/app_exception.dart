/// Lỗi ứng dụng: service đổi mọi exception của SDK thành loại này
/// để ViewModel hiện một câu ngắn (DESIGN.md T6: nguyên nhân ≤ 6 từ).
enum AppErrorKind { network, permission, notFound, cancelled, invalid, auth, quota, unknown }

class AppException implements Exception {
  const AppException(this.kind, this.message, {this.cause});

  final AppErrorKind kind;
  final String message;
  final Object? cause;

  static const network = AppException(AppErrorKind.network, 'Mất kết nối mạng');
  static const permission = AppException(AppErrorKind.permission, 'Không có quyền truy cập');
  static const cancelled = AppException(AppErrorKind.cancelled, 'Đã hủy');

  @override
  String toString() => 'AppException($kind, $message, cause: $cause)';
}
