# Gym Tracker - Claude Code Rules

## 設計判断の基準

**重要原則：複数画面に渡るデータ共有の場合、必ずProviderベースの状態管理を選択する**

- 複数の画面でデータを共有する必要がある場合 → Riverpod/Provider使用
- ローカル画面内のみの状態 → StatefulWidgetでOK
- **このアプリ（gym_tracker）は複数画面（セッション→完了→履歴）に渡るため、Riverpodが必須**
- 「今のエラーを避ける最小限の修正」ではなく「後続機能につながる設計」を優先する

## 技術スタック

- Flutter 3.41.6
- Firebase（Firestore + Authentication）
- flutter_riverpod（状態管理）
- iOS最小バージョン: 15.0

## アーキテクチャ

```
lib/
├── models/              # Exercise、WorkoutPattern、SetRecord等
├── repositories/        # Firestore通信層（CRUD基本実装）
├── providers/           # Riverpod State管理
├── screens/             # UI画面
│   ├── home/            # ホーム画面
│   ├── session/         # セッション画面（メイン）
│   ├── history/         # 履歴画面
│   └── settings/        # 設定画面
└── widgets/             # 再利用可能なUI部品
```

## データモデル設計のポイント

- `SetRecord` は `exerciseId` に直接紐づく
  - パターン変更後も過去データが壊れない
  - 「前回の記録」は`exerciseId`で検索すれば取得可能
- `PatternExercise` は中間テーブル
  - パターンの柔軽に組み替え対応

## 画面構成（MVP）

| 画面 | 概要 | 状態管理 |
|------|------|---------|
| ホーム | パターン選択 | FutureProvider（Firestore読み込み） |
| セッション | ステップ形式でセット入力（タイル配置） | StatefulWidget + 局所的状態 |
| セッション完了 | 今日のまとめ表示 | Props経由で受け取り |
| 履歴 | 日付指定でセッション確認 | 別途実装 |
| 設定 | CSVインポート/エクスポート | 別途実装 |

## 実装進行状況

- [x] Firebase初期化 + Riverpod統合
- [x] データモデル作成（5つ）
- [x] Repository層実装（4つ）
- [x] ホーム画面（パターン表示）
- [x] セッション画面基本UI（ステップ形式）
- [ ] Riverpod StateProvider でセッション状態を画面間で共有
- [ ] セッション完了画面実装・データ受け渡し
- [ ] Firestore保存機能実装
- [ ] 履歴画面実装
- [ ] 設定画面実装
