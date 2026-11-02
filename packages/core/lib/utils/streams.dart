import 'dart:async';

/// Gộp nhiều stream: phát lại danh sách giá trị mới nhất khi mọi stream đã có ít nhất một giá trị.
Stream<List<Object?>> combineLatest(List<Stream<Object?>> streams) {
  late StreamController<List<Object?>> ctrl;
  final subs = <StreamSubscription<Object?>>[];
  final values = List<Object?>.filled(streams.length, null);
  final has = List<bool>.filled(streams.length, false);
  ctrl = StreamController<List<Object?>>(
    onListen: () {
      for (var i = 0; i < streams.length; i++) {
        subs.add(streams[i].listen(
          (v) {
            values[i] = v;
            has[i] = true;
            if (has.every((h) => h)) ctrl.add(List<Object?>.of(values));
          },
          onError: ctrl.addError,
        ));
      }
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
    },
  );
  return ctrl.stream;
}
