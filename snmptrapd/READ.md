---
## snmptrapd/Dockerfile:1
### Debian slim + snmptrapd snmp をインストール
- LISTEN_ADDRESSES（既定: udp:0.0.0.0:162）、TRAP_COMMUNITY（既定: public）、TRAP_SOURCE、DISABLE_AUTH 環境変数をサポート
- /etc/snmp/snmptrapd.conf を同梱し、エントリポイントで必要に応じて生成/上書き
- EXPOSE 162/udp
- 実行は snmptrapd -f -Lo（フォアグラウンド＋STDOUTへログ）
### デフォルト設定（認可チェック有効＋public のトラップをログ）
### agentAddress udp:0.0.0.0:162

## snmptrapd/docker-entrypoint.sh:1
### 既存の /etc/snmp/snmptrapd.conf がある場合は尊重（上書きしない）。強制生成は -e OVERRIDE_CONFIG=true
### 生成時は下記を出力:
- agentAddress <LISTEN_ADDRESSES>
- disableAuthorization yes|no（DISABLE_AUTH=yes なら全許可）
- authCommunity log <TRAP_COMMUNITY> [<TRAP_SOURCE>]（DISABLE_AUTH=no の場合）
- Windows由来の Net-SNMP 環境変数を unset して混入対策
