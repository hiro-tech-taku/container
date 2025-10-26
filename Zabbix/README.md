# Zabbix Manager (Docker)

Zabbix をすぐ試せるように、公式のオールインワンイメージ（Zabbix Appliance）をベースにした Dockerfile を用意しています。Zabbix Server、Web UI（NGINX + PHP-FPM）、組み込み DB が 1 つのコンテナで動作します。

## 前提条件
- Docker がインストール済み
- ポート `80`（Web UI）、`10051`（Zabbix server）が空いていること

## ビルド
```bash
docker build -t zabbix-manager .
```

## 実行（最小構成）
```bash
# Web UI: http://localhost:8080
# Zabbix server port: 10051

docker run -d --name zabbix-manager \
  -p 8080:80 \
  -p 10051:10051 \
  -e TZ=Asia/Tokyo \
  zabbix-manager
```

- 初期ログイン（初期値）: ユーザー `Admin` / パスワード `zabbix`
- 初回アクセス時にウィザードが実行されます。

## データ永続化（任意）
アプライアンスは組み込み DB を利用します。データを保持したい場合は以下のようにボリュームをマウントしてください（MySQL データなど）。

```bash
docker volume create zbx_mysql

docker run -d --name zabbix-manager \
  -p 8080:80 \
  -p 10051:10051 \
  -e TZ=Asia/Tokyo \
  -v zbx_mysql:/var/lib/mysql \
  zabbix-manager
```

主なディレクトリ（参考）:
- `/var/lib/mysql` … DB データ
- `/etc/zabbix` … Zabbix 設定
- `/usr/share/zabbix` … Web UI ファイル

## タイムゾーン
Dockerfile では OS と PHP のタイムゾーンを `Asia/Tokyo` に設定しています。変更したい場合は環境変数で上書き可能です。

```bash
-e TZ=UTC
```

## 注意事項
- 単一コンテナにすべてを同居させるため、負荷が高い本番用途には向きません。本番は DB を外出しにする公式構成（Server + Web + DB の分割）をご検討ください。
- より細かなチューニング（`zabbix_server.conf` など）はコンテナ起動後にファイルを上書きするか、独自イメージを拡張してください。

---
詳細な Dockerfile の説明は `READ.md` を参照してください。

## docker-compose 版（Server/Web/Postgres 分割）
本番に近い形で Server・Web・DB を分割したテンプレートを `docker-compose.yml` として用意しています（PostgreSQL）。

### 起動
```bash
docker compose up -d
```

- Web UI: `http://localhost:8080`
- Server ポート: `10051`
- 初期ログイン: ユーザー `Admin` / パスワード `zabbix`

### 停止/削除
```bash
docker compose down         # 停止
docker compose down -v      # 停止 + ボリューム削除（DB データ消去）
```

### 構成概要（抜粋）
- `db`: `postgres:13-alpine` を使用。永続化はボリューム `zbx_db` に保存。
- `zabbix-server`: `zabbix/zabbix-server-pgsql:alpine-latest` を使用。DB 接続情報は環境変数で指定。
- `zabbix-web`: `zabbix/zabbix-web-nginx-pgsql:alpine-latest` を使用。`8080:8080` を公開。

環境変数（デフォルト値）:
- DB ユーザー/DB 名/パスワード: `zabbix / zabbix / zabbix`
- TZ/PHP_TZ: `Asia/Tokyo`

必要に応じて `docker-compose.yml` の環境変数を変更してください。パスワードは本番では必ず強固なものに更新してください。
