"""Sửa thư mục android/ sau `flutter create` (chạy lại nhiều lần không sao).

    python tool/patch_android.py

- minSdk 23 (Firebase Auth), bật core library desugaring (flutter_local_notifications)
- Quyền: CAMERA (quét mã), POST_NOTIFICATIONS (Android 13+), RECEIVE_BOOT_COMPLETED
- Receiver của flutter_local_notifications để nhắc slot vẫn chạy sau khi khởi động lại máy
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GRADLE = ROOT / "android" / "app" / "build.gradle.kts"
MANIFEST = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"


def patch_gradle() -> None:
    if not GRADLE.exists():
        sys.exit(f"Không thấy {GRADLE}. Chạy trước: flutter create . --org vn.edu.fpt --platforms=android,web")
    g = GRADLE.read_text(encoding="utf-8")
    g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23", g)
    if "isCoreLibraryDesugaringEnabled" not in g:
        g = re.sub(r"(compileOptions\s*\{)", r"\1\n        isCoreLibraryDesugaringEnabled = true", g, count=1)
    if "desugar_jdk_libs" not in g:
        if re.search(r"^dependencies\s*\{", g, re.M):
            g = re.sub(r"^(dependencies\s*\{)", r'\1\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")', g, count=1, flags=re.M)
        else:
            g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    GRADLE.write_text(g, encoding="utf-8")
    print("build.gradle.kts: minSdk 23, desugaring")


PERMS = [
    "android.permission.CAMERA",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
]

RECEIVERS = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
        <meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="quick_attend" />
"""


def patch_manifest() -> None:
    m = MANIFEST.read_text(encoding="utf-8")
    for p in PERMS:
        if p not in m:
            m = re.sub(r"(<manifest[^>]*>)", rf'\1\n    <uses-permission android:name="{p}" />', m, count=1)
    if "ScheduledNotificationReceiver" not in m:
        m = m.replace("</application>", RECEIVERS + "    </application>", 1)
    m = m.replace('android:label="quick_attend"', 'android:label="Quick Attend"')
    MANIFEST.write_text(m, encoding="utf-8")
    print("AndroidManifest.xml: quyền camera, thông báo, receiver nhắc slot")


if __name__ == "__main__":
    patch_gradle()
    patch_manifest()
