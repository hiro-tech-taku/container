snmptrapd → Zabbix 連携コンテナ

概要
- snmptrapd で受信した SNMP Trap を zabbix_sender で Zabbix server/proxy に転送します。
- シンプルな traphandle スクリプトで全文を 1 行化し、Zabbix トラッパーアイテムに投入します。

含まれるもの
- snmptrapd（UDP/162 で待ち受け）
- zabbix-sender（Zabbix trapper 10051 へ送信）
- 自動生成 snmptrapd.conf（環境変数に応じて生成/上書き）
- traphandle: /usr/local/bin/zbx-trap-forwarder.sh

主要な環境変数
- `LISTEN_ADDRESSES` 既定: `udp:0.0.0.0:162`
- `TRAP_COMMUNITY` 既定: `public`
- `DISABLE_AUTH` 既定: `no`（yes で認可無効）
- `ZBX_SERVER` 必須: 送信先 Zabbix server/proxy の FQDN/IP
- `ZBX_PORT` 既定: `10051`
- `ZBX_HOST` 任意: Zabbix 上のホスト名（未設定時は送信元 IP を推測）
- `ZBX_KEY`  既定: `snmptrap`（Zabbix 側に Trapper アイテムを作成）
- `ZBX_FORWARD` 既定: `auto`（`ZBX_SERVER` 指定時に traphandle を有効化。`yes` で強制）

ビルド
```
docker build -t snmptrapd-zbx .
```

実行例
```
docker run -d --name snmptrapd \
  -p 162:162/udp \
  -e ZBX_SERVER=192.168.1.10 \
  -e ZBX_HOST=switch-01 \
  -e ZBX_KEY=snmptrap \
  snmptrapd-zbx
```

Zabbix 側の準備
- 対象ホストにアイテムを作成: 種別「Zabbix トラッパー」、キー `snmptrap`（変更した場合は `ZBX_KEY` と一致させる）
- 必要に応じてトリガーや正規表現で Trap 内容からアラート条件を作成します。

注意
- 本構成は Trap の全文を 1 行化して送信します。詳細なマッピングや正規化が必要な場合はスクリプトを拡張してください。
- UDP/162 は特権ポートです。Docker で公開するホスト側ポートも 162 を割り当てる場合、管理者権限が必要になることがあります。

Zabbix Manager（同一マシンでの簡易起動）
- 目的: ローカル検証のため、Zabbix server + Web + DB をオールインワンで起動します。
- ファイル: `Dockerfile.zabbix`
- ビルド:
  - `docker build -f Dockerfile.zabbix -t zabbix-manager .`
- 起動:
  - `docker run -d --name zabbix-manager -p 8080:80 -p 10051:10051 zabbix-manager`
  - Web UI: http://localhost:8080 （初期ログイン: Admin / zabbix）
- 初期設定（UIで実施）
  - ホスト作成: 例) ホスト名 `snmptrap-source`、任意のグループ（例: Linux servers）
  - アイテム追加: 種別「Zabbix トラッパー」、キー `snmptrap`、情報の型「テキスト」
  - 上記ホスト名とキーは、下記 snmptrapd 実行時の `ZBX_HOST` と `ZBX_KEY` に一致させてください。

snmptrapd と接続してテスト
1) snmptrapd イメージをビルド
   - `docker build -t snmptrapd-zbx .`
2) snmptrapd を起動（Zabbix Manager へ送信）
   - `docker run -d --name snmptrapd -p 162:162/udp -e ZBX_SERVER=host.docker.internal -e ZBX_PORT=10051 -e ZBX_HOST=snmptrap-source -e ZBX_KEY=snmptrap snmptrapd-zbx`
   - 備考: Linux の場合は `host.docker.internal` の代わりに Zabbix コンテナのブリッジIPや同一ネットワークを利用してください。
3) コンテナ内からテスト Trap 送信
   - `docker exec -i snmptrapd sh -c "snmptrap -v 2c -c public 127.0.0.1:162 '' .1.3.6.1.4.1.8072.2.3.0.1 sysUpTimeInstance t 0 sysName.0 s 'test-host' .1.3.6.1.4.1.8072.2.3.2.1 s 'Test trap from container'"`
4) フォワーダーログ確認
   - `docker logs --tail 200 snmptrapd` に `[zbx-trap-forwarder] sent trap to ... host=snmptrap-source key=snmptrap` が出力されること
5) Zabbix 側確認
   - Web の「監視データ > 最新データ」でホスト `snmptrap-source`、アイテム `snmptrap` に値が入ること
