# READ.md（Dockerfile の説明）

このファイルでは、本リポジトリの `Dockerfile` が何をしているかを簡潔に説明します。

## ベースイメージ
```
FROM zabbix/zabbix-appliance:alpine-latest
```
- 公式の Zabbix Appliance（Alpine ベース）を利用します。
- Appliance は Zabbix Server、Web（NGINX + PHP-FPM）、DB を 1 つのコンテナに含んだ「お試し・検証向け」イメージです。
- 本番運用では DB を外出しして Server/Web を分ける構成が推奨ですが、学習や PoC では Appliance が手軽です。

## タイムゾーン設定
```
ENV TZ=Asia/Tokyo \
    PHP_TZ=Asia/Tokyo
```
- コンテナ内 OS と PHP（Zabbix Web UI）のタイムゾーンを `Asia/Tokyo` に設定します。
- 必要に応じて起動時に `-e TZ=UTC` のように上書き可能です。

## ポート公開
```
EXPOSE 80 10051
```
- `80`: Zabbix Web UI（ブラウザでアクセスするポート）
- `10051`: Zabbix server の受信ポート

## エントリポイント / 起動
- ベースイメージが `supervisor` などで各サービスを起動する仕組みを持っているため、Dockerfile 側で CMD/ENTRYPOINT の上書きは不要です。

## 使い方の要点
- ビルド: `docker build -t zabbix-manager .`
- 実行（例）:
  ```bash
  docker run -d --name zabbix-manager \
    -p 8080:80 \
    -p 10051:10051 \
    -e TZ=Asia/Tokyo \
    zabbix-manager
  ```
- Web UI: `http://localhost:8080`
- 初期ログイン: ユーザー `Admin` / パスワード `zabbix`
- データ永続化したい場合は、少なくとも `/var/lib/mysql` をボリュームにマウントします。

## カスタマイズの方向性
- 設定を細かく変更したい場合は、`/etc/zabbix/zabbix_server.conf` 等をコンテナへマウント、またはベースイメージを拡張してファイルを差し替えます。
- Appliance ではなく、公式の分割イメージ（`zabbix-server-*`, `zabbix-web-*`, `postgres`/`mysql` 等）と `docker compose` を使うと本番寄りの構成に発展できます。
