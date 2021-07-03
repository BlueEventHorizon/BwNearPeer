#!/bin/sh

swiftformat --exclude Carthage,Pods --stripunusedargs closure-only --extensionacl on-declarations --indentcase true --disable redundanttype,redundantRawValues,redundantSelf,trailingCommas,wrapMultilineStatementBraces,blankLinesAroundMark $1

# --stripunusedargs closure-only 使われていない引数名の省略はクロージャに限る
#  --extensionacl on-declarations extensionのpublic宣言などを、extensionの接頭ではなく、関数等の接頭につける（on-declarationsをon-extensionにすると逆）

# 【disable】
# redundanttype 型推論できる不必要な型などを削除する
# redundantRawValues enum の不必要な raw string value を削除する。
# redundantSelf self を挿入または削除する。
# trailingCommas コレクションリテラルの最後の項目の末尾のコンマを追加または削除する。
# wrapMultilineStatementBraces 複数行のステートメントの開始括弧の位置を一段下げる。(if / guard / while / func)
# blankLinesAroundMark Insert blank line before and after MARK: comments.

# 参考：https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md