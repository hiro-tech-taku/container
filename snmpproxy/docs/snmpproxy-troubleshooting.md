# SNMP Trap プロキシの原因と対処まとめ

## 原因まとめ
- PowerShell の解釈: `FORWARD_LIST` 内の `|` がパイプ扱いになり、値が正しく渡せていなかった。
- アクセス制御未設定: `snmptrapd` が有効な `snmptrapd.conf` を読み込めず、「no access control…」でトラップを拒否。
- 冗長な MIB 警告: 既定で多数の MIB を読むため「Cannot adopt OID …」が大量出力。

## 実施した対処
- 引用ルール案内: PowerShell では `-e "FORWARD_LIST=10.0.0.10,zabbix.local|public2"` のように必ず引用する運用に修正。
- イメージ修正: `Dockerfile` に `bash` を追加し、エントリポイントを確実に実行。
- 設定生成の堅牢化: `docker-entrypoint.sh` を刷新し毎回設定を生成・使用、採用した設定をログに出力。`OVERWRITE_CONFIG` でマウント優先も可能。
- MIB 警告抑止: `Dockerfile` に `ENV MIBS=""` を追加（必要時は `-e "MIBS=IF-MIB:SNMPv2-MIB"` 等で上書き）。

## いま正常に見える理由
ログに採用設定が表示され、かつ以下が含まれているため受信・転送が有効化されている:
- `authCommunity log,execute,net public`
- `forward 10.0.0.10` と `forward zabbix.local public2`
- `agentAddress udp:0.0.0.0:162`
- `Created directory: /var/lib/snmp/cert_indexes` は Net-SNMP の証明書ディレクトリ作成メッセージで問題なし。

## 再発防止の要点
- PowerShell では `|` を含む環境変数値は必ず引用する。
- 設定をマウントする場合は必要に応じて `-e OVERWRITE_CONFIG=no` を併用し、ログで採用設定を確認する。
- MIB 出力が不要な運用では `MIBS=""` を維持してログを静かに保つ。

## 参考コマンド
- 再ビルド: `docker build -t snmpproxy:latest .`
- 再起動 (PowerShell):
  - `docker rm -f snmpproxy`
  - `docker run -d --name snmpproxy -p 162:162/udp -e "SNMP_COMMUNITIES=public" -e "FORWARD_LIST=10.0.0.10,zabbix.local|public2" snmpproxy:latest`
- ログ確認: `docker logs --tail 50 snmpproxy`
