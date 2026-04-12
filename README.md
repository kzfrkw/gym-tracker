# Gym Tracker

個人用のウェイトトレーニング記録アプリです。Flutter + Firebase で構築しています。

## 機能

- **トレーニングパターン管理** — 種目・セット数・目標回数をパターンとして登録
- **セッション記録** — セットごとに回数・重量を入力し、完了チェックで管理
- **前回記録の表示** — 各セットに前回の回数・重量を表示、重量は自動プリフィル
- **履歴カレンダー** — カレンダーでトレーニング日を確認、セッション詳細を閲覧
- **重量推移グラフ** — 種目ごとの推定1RM推移を折れ線グラフで表示
- **Google ログイン** — Google アカウントでサインイン、データはユーザーごとに分離

## 技術スタック

- Flutter 3.x
- Firebase (Firestore, Authentication)
- flutter_riverpod（状態管理）
- google_sign_in
- table_calendar
- fl_chart

## セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/gym_tracker.git
cd gym_tracker
flutter pub get
```

### 2. Firebase プロジェクトを作成

1. [Firebase Console](https://console.firebase.google.com/) でプロジェクトを作成
2. iOS / Android アプリを追加
3. Firestore Database を有効化（セキュリティルールを設定）
4. Authentication → Google サインインを有効化

### 3. Firebase 設定ファイルを配置

[FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) を使って設定ファイルを生成するのが最も簡単です。

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

または、各 `.example` ファイルをコピーして値を埋めることもできます。

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
cp android/app/google-services.json.example android/app/google-services.json
```

### 4. iOS: URL Scheme の設定

Google Sign-In に必要な URL Scheme を `ios/Runner/Info.plist` に追加します。

`GoogleService-Info.plist` 内の `REVERSED_CLIENT_ID` の値を確認し、`Info.plist` に以下を追記してください。

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### 5. ビルド・実行

```bash
flutter run
```

## Firestore セキュリティルール

データはユーザーごとに `/users/{userId}/...` に保存されます。以下のルールを推奨します。

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
