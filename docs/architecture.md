# Kiến trúc · Quick Attend

MVVM với **Riverpod 3**, ba package dùng chung một Firestore. Phụ thuộc chỉ đi xuống: `screens/` và `widgets/` → `viewmodels/` → `services/`, `firebase/` → SDK. `models/` không phụ thuộc lớp nào. Không có server riêng: logic chạy ở client, Security Rules và App Check quyết định client được làm gì (đề Final mục 4).

## 1. Cấu trúc thư mục

```
packages/core/lib/       phần dùng chung của cả hai client
├── config/              cấu hình build: portal, client ID Google
├── theme/               token Lab 2 → ColorScheme, TextTheme, AppSpace, AppRadius, StatusColors
├── models/              lớp dữ liệu thuần Dart + ViewState (loading, empty, error, data)
├── utils/               hàm thuần: kỳ học, định dạng ngày, ngưỡng vắng, AppException
├── services/            interface + bản Firestore/Auth: auth, user, class, slot, request, reminder,
│                        student attendance, subject, announcement, report, dashboard
├── firebase/            analytics, remote config, App Check
├── widgets/             component Lab 2: AppButton, QaCard, SlotCard, StatusChip, …
└── providers.dart       DI cho service dùng chung; test ghi đè ở đây
mobile/lib/              app giảng viên (Android) và cổng sinh viên (build web)
├── main.dart, app.dart, router.dart
├── providers.dart       thêm service riêng của app, export lại phần core
├── services/            import file (parse), report PDF, lưu và chia sẻ file, chọn file
├── firebase/            crashlytics, messaging, storage, thông báo cục bộ, Gemini (AI Logic)
├── viewmodels/          một Notifier mỗi màn; giữ state, gọi service, ghi analytics
└── screens/             auth/, lecturer/, student/, demo/, inbox/
web/lib/                 web admin cho giáo vụ và quản trị (Flutter Web)
├── main.dart, app.dart, router.dart
├── viewmodels/          auth, dashboard, review, subjects, announcements, users
├── screens/             một file mỗi màn
└── widgets/             khung màn rộng AdminShell, biểu đồ RateBars
firebase/                firebase.json, firestore.rules, indexes, remote-config-defaults, tests/
e2e_test/                bộ test ARTEMIS (pytest)
tool/                    build_hosting.sh, patch_android.py
```

Web admin không có service riêng: mọi truy cập dữ liệu đi qua `packages/core`. Đây là lý do `Crashlytics`, `Storage`, `Messaging` nằm ở `mobile/`: đề chỉ yêu cầu chúng trên mobile.

## 2. Sơ đồ lớp

```mermaid
flowchart TB
    subgraph View["View · screens/, widgets/"]
        S["Screen (ConsumerWidget)"]
        W["Widget Lab 2"]
    end
    subgraph VM["ViewModel · viewmodels/ (Riverpod Notifier)"]
        V["XxxViewModel<br/>state: ViewState&lt;T&gt; + cờ hành động"]
    end
    subgraph SVC["Services · services/, firebase/"]
        A["AuthService"]
        R["Repositories: User, Class, Slot,<br/>Request, Reminder, StudentAttendance"]
        I["ImportService · ReportService · FilePickerService"]
        F["AnalyticsService · CrashService · ConfigService<br/>MessagingService · StorageService · LocalNotificationService"]
    end
    subgraph SDK["Firebase"]
        FA["Auth"]
        FS["Cloud Firestore"]
        FB["Storage · FCM · Analytics<br/>Crashlytics · Remote Config"]
    end
    M["models/ (dùng chung)"]
    S -->|"sự kiện người dùng"| V
    V -->|"state thay đổi"| S
    S --> W
    V -->|"gọi async"| A & R & I & F
    A --> FA
    R --> FS
    F --> FB
    M -.- V
    M -.- R
```

Luật được kiểm:
- Không screen hay widget nào import `firebase_*`, `cloud_firestore` hay gọi `FirebaseX.instance`. Chỉ file trong `services/` và `firebase/` được import SDK (kiểm bằng `grep` trong `docs/code-review.md`).
- Lọc, đếm, xếp hạng, kiểm tra hợp lệ nằm trong ViewModel hoặc service (ví dụ `AttendanceMath`, `ImportService`), không nằm trong `build()`.
- Mỗi màn tải dữ liệu có `ViewState<T>` (sealed: `Loading`, `Empty`, `Failure`, `Ready`) do ViewModel giữ.
- Service được tạo trong `providers.dart` và đọc qua `ref`, nên test ghi đè bằng `ProviderContainer(overrides: [...])`.

## 3. Sơ đồ tuần tự · FL-1 Điểm danh một slot (có sinh viên quét)

```mermaid
sequenceDiagram
    actor GV as Giảng viên
    participant SS as SessionScreen
    participant VM as SessionViewModel
    participant SR as SlotRepository
    participant FS as Cloud Firestore
    actor SV as Sinh viên (ScanScreen)
    participant SVM as ScanViewModel
    GV->>SS: mở /session/:slotId
    SS->>VM: build(slotId)
    VM->>SR: openSession(slotId, token)
    SR->>FS: update slots/{id} qrOpen, qrToken, qrExpiresAt
    VM->>SR: watchAttendance(slotId)
    SR-->>VM: Stream<List<AttendanceRecord>>
    loop mỗi N giây (Remote Config qr_rotate_seconds)
        VM->>SR: rotateToken(slotId)
        SR->>FS: update qrToken, qrExpiresAt
    end
    SV->>SVM: camera đọc "qa2|slotId|token|…thông tin slot"
    SVM->>FS: set slots/{id}/attendance/{MSSV} (token)
    Note over FS: Rules so token, hạn mã, MSSV trong lớp và các trường với slots/{id} (sinh viên không đọc được slot)
    FS-->>SR: snapshot mới
    SR-->>VM: danh sách đã quét
    VM-->>SS: state 33/35
    GV->>SS: Chốt (lần 1: đóng mã → .D2; lần 2: OV1 → Chốt)
    SS->>VM: close()
    VM->>SR: closeSession(slot, roster, present)
    SR->>FS: batch: attendance cho cả lớp (final), slots/{id}.closed
    alt mạng tốt
        FS-->>VM: ack → state .S, toast Hoàn tác
        VM->>VM: analytics attendance_close
    else quá 8 giây
        VM-->>SS: state .X (GV-OV2) "đã lưu trên máy"
        VM->>VM: Crashlytics recordError (non-fatal)
    end
```

## 4. ViewModel và service dùng

| ViewModel | Màn | Service |
|---|---|---|
| `AuthGate` (Provider) | router | AuthService, UserRepository |
| `LoginViewModel` | GV-090, SV-090 | AuthService, UserRepository, AnalyticsService, CrashService |
| `SignUpViewModel` | GV-091, SV-091 | AuthService, UserRepository, AnalyticsService |
| `VerifyEmailViewModel` | GV-092 | AuthService |
| `ForgotPasswordViewModel` | GV-094 | AuthService |
| `OverviewViewModel` | GV-001 | ClassRepository, SlotRepository, RequestRepository, ConfigService |
| `ScheduleViewModel` | GV-002 | SlotRepository |
| `ClassesViewModel` | GV-003 | ClassRepository, SlotRepository, ConfigService |
| `AccountViewModel` | GV-004, tài khoản SV | AuthService, UserRepository, LocalNotificationService, AnalyticsService |
| `ImportViewModel` | GV-100 | FilePickerService, ImportService, ClassRepository, UserRepository, AnalyticsService, CrashService |
| `SlotDetailViewModel` | GV-101 | SlotRepository, ClassRepository |
| `SessionViewModel` | GV-102 | SlotRepository, ClassRepository, ConfigService, AnalyticsService, CrashService |
| `ClassDetailViewModel` | GV-103 | ClassRepository, SlotRepository, ReportService, StorageService, ConfigService, AnalyticsService |
| `AttentionViewModel` | GV-104 | ClassRepository, SlotRepository, ConfigService |
| `RequestsViewModel` | GV-105 | RequestRepository, AnalyticsService |
| `StudentProfileViewModel` | GV-201 | SlotRepository, ClassRepository, ReminderRepository, ConfigService, AnalyticsService |
| `MyAttendanceViewModel` | SV-001, SV-002 | StudentAttendanceRepository, UserRepository, ConfigService |
| `ScanViewModel` | SV-101 | StudentAttendanceRepository, AnalyticsService, CrashService |
| `ReportViewModel` | SV-102 | RequestRepository, StudentAttendanceRepository, AnalyticsService |
| `FirebaseDemoViewModel` | demo | ReportService, StorageService, ConfigService, CrashService, MessagingService, ClassRepository |
| `NotificationsViewModel` | trung tâm thông báo | MessagingService |

## 5. Mô hình dữ liệu Firestore

| Đường dẫn | Trường chính | Ai ghi |
|---|---|---|
| `users/{uid}` | `role` (lecturer, student), `displayName`, `email`, `studentCode?`, `reminderBeforeSlot`, `reminderUnclosed`, `lastImportAt` | chính người đó (không đổi `role` sau khi tạo) |
| `classes/{classId}` | `lecturerId`, `term`, `subject`, `code`, `studentCount`, `totalSlots` | giảng viên chủ lớp |
| `classes/{classId}/students/{mssv}` | `name`, `studentCode`, `email` | giảng viên chủ lớp |
| `slots/{slotId}` | `lecturerId`, `classId`, `subject`, `classCode`, `term`, `start`, `end`, `slotNo`, `room`, `studentCount`, `closed`, `presentCount`, `absentCount`, `qrOpen`, `qrToken`, `qrExpiresAt` | giảng viên chủ slot |
| `slots/{slotId}/attendance/{mssv}` | `studentCode`, `studentName`, `present`, `source` (scan, manual, auto, correction), `final`, `token?` + trường sao chép của slot | giảng viên; sinh viên chỉ tạo bản ghi của mình khi mã còn hạn |
| `requests/{id}` | `studentUid`, `studentCode`, `lecturerId`, `slotId`, `classId`, `reason`, `note`, `status` (pending, approved, rejected), `rejectReason` | sinh viên tạo; giảng viên duyệt |
| `reminders/{id}` | `lecturerId`, `classId`, `studentCode`, `message`, `day` | giảng viên |

Ảnh và file: `reports/{uid}/{classId}-{yyyyMMdd-HHmm}.pdf` trên Cloud Storage. Luật ở `firebase/firestore.rules` và `firebase/storage.rules`.

## Final: ViewModel và service của phần mới

| ViewModel | Client | Trạng thái | Service dùng |
|---|---|---|---|
| `InboxViewModel` | mobile | `ViewState<List<InboxItem>>` | `AnnouncementRepository`, `UserRepository`, `AnalyticsService` |
| `StudentProfileViewModel` (thêm AI) | mobile | `StudentProfileState` có `aiBusy`, `aiDraft` | `AiService`, `ConfigService`, `ReminderRepository`, `AnalyticsService`, `CrashService` |
| `ImportViewModel` (thêm kiểm môn) | mobile | `ImportState` | `SubjectRepository`, `ClassRepository`, `ImportService` |
| `AdminAuthViewModel` | web | `AdminAuthState` | `AuthService`, `UserRepository`, `AnalyticsService` |
| `DashboardViewModel` | web | `ViewState<DashboardData>` | `DashboardRepository`, `SubjectRepository`, `ConfigService` |
| `ReviewViewModel` | web | `ReviewState` | `ClassRepository`, `SubjectRepository`, `AnalyticsService` |
| `SubjectsViewModel` | web | `SubjectsState` | `SubjectRepository`, `AnalyticsService` |
| `AnnouncementsViewModel` | web | `AnnouncementsState` | `AnnouncementRepository`, `AnalyticsService` |
| `UsersViewModel` | web | `UsersState` | `UserRepository`, `AnalyticsService` |

Sơ đồ tuần tự luồng liên vai trò: [`cross-role-flow.md`](cross-role-flow.md). Luồng AI: [`ai-feature.md`](ai-feature.md).
