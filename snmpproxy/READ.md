---
## snmptrapd/Dockerfile:1
1. FROM debian:bookworm-slim
- ベースイメージに軽量な Debian 12（bookworm-slim）を指定します。
2. RUN apt-get update \
- パッケージリストを更新します。
3. && apt-get install -y --no-install-recommends snmpd snmp \
- snmpd（SNMPデーモン）と snmp（ツール類）を推奨パッケージなしで非対話的にインストールします。&& は前コマンド成功時のみ続行
4. && rm -rf /var/lib/apt/lists/*
- 取得したAPTのリストを削除してレイヤサイズを削減します。
5. ENV REMOTE_HOST= \
- 上流SNMPエージェントのホスト名/IP。空がデフォルトで、実運用時は必ず指定が必要です（未指定だとプロキシは機能しません）。
6. REMOTE_PORT=161 \
- 上流SNMPエージェントのポート番号（既定は SNMP の UDP/161）。
7. REMOTE_COMMUNITY=public \
- 上流SNMPへアクセスする際に使うコミュニティ文字列（v2c）。
8. PROXY_OID=.1.3.6.1.2.1 \
- プロキシ転送するOIDサブツリー（例は MIB-2 直下）。
9. RO_COMMUNITY=public \
- このプロキシに対してクライアントが参照時に使う読み取りコミュニティ。
10. RO_SOURCE=0.0.0.0/0 \
- 読み取りを許可する送信元（クライアント）範囲。0.0.0.0/0 は全許可でセキュリティ的に緩い設定です。
11. SYS_LOCATION="Docker SNMP Proxy" \
- sysLocation（機器の設置場所などの情報）に入る表示用文字列。
12. SYS_CONTACT="admin@example.com" \
- sysContact（管理者連絡先）に入る表示用文字列。
14. LISTEN_ADDRESSES="udp:0.0.0.0:161"
- snmpd が待ち受けるアドレス/ポート指定（全インターフェイスの UDP/161）。実行時に -e で上書き可能です。