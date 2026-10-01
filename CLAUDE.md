# Gym Tracker - Claude Code Rules

## 技術スタック

- Flutter 3.41.6
- Firebase（Firestore + Authentication）
- flutter_riverpod v3（状態管理）
- iOS最小バージョン: 15.0

## アーキテクチャ

```
lib/
├── models/              # データ構造
├── repositories/        # Firestore通信層
├── providers/           # Riverpod 状態管理・ビジネスロジック
├── screens/             # 画面（薄く保つ）
│   └── */widgets/       # その画面専用の UI 部品
├── widgets/             # 複数画面で共有する UI 部品
├── services/            # 副作用を伴う処理（ドラフト保存等）
└── utils/               # 純粋な計算ロジック（1RM計算・グラフ計算等）
```

## コード設計原則

### 「Screen は薄く」

| レイヤー | 役割 | 目安行数 |
|---------|------|---------|
| `screens/` | ナビゲーション起点・ウィジェットの組み合わせ | 〜150行 |
| `screens/*/widgets/` | その画面専用の UI 部品 | 〜100行/ファイル |
| `widgets/` | 複数画面で共有する UI 部品 | 〜100行/ファイル |
| `providers/` | 状態管理・ビジネスロジック | 〜100行/ファイル |

### ウィジェット分割の判断基準

同じファイルに置いてよい：50行以下 かつ そのファイル内でしか使わない

別ファイルに切り出す：他の画面でも使う可能性がある / 複雑な状態・Props を持つ

### utils/ に切り出す基準

副作用のない純粋な計算ロジックは `utils/` へ（1RM計算、グラフ軸計算、日付フォーマット等）

## Riverpod ルール（v3）

- `StateProvider` は廃止 → `Notifier` / `AsyncNotifier` を使う
- 複数画面でデータを共有する場合は必ず Provider を経由する
- ビジネスロジック（保存・計算・判定）は画面ではなく Provider / Service に置く

## データモデル設計のポイント

- `SetRecord` は `exerciseId` に直接紐づく（パターン変更後も過去データが壊れない）
- `PatternExercise` は中間テーブル（パターンの柔軟な組み替え対応）
- Firestore パス: `users/{userId}/exercises|workoutPatterns|setRecords|workoutSessions`
