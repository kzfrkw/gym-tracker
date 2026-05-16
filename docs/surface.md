# Surface（表層層） - Gym Tracker

## 現状のビジュアル方針

- **デザインシステム**: Flutter Material Design 3（デフォルト）
- **テーマ**: 未定義（システムデフォルト。ダークモード対応未実装）
- **フォント**: システムフォント（SF Pro / Roboto）

## UI コンポーネントの使用状況

| 用途 | 現在の実装 |
|------|-----------|
| セット入力カード | Card + TextFormField |
| 完了チェック | タップで緑ボーダー + 背景色変化 |
| カレンダー | table_calendar パッケージ |
| グラフ | fl_chart パッケージ（折れ線） |
| パターン選択 | GridView |
| セッション一覧 | ListView + ListTile |

## 未整備の領域（今後検討）

- カラーテーマ（ブランドカラーの定義）
- アイコンの統一（現状は Material Icons のまま）
- ダークモード対応
- アニメーション・トランジション
- エラー・空状態のデザイン
- ローディング UI（現状はデフォルトの CircularProgressIndicator）
