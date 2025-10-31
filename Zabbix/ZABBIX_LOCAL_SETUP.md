# Zabbix Web/Manager 用 Dockerfile 分離と疎通確認手順

このリポジトリには Zabbix Web 用と Zabbix Manager(Server) 用の 2 つの Dockerfile を用意しています。

- `Dockerfile.manager` … Zabbix Server (PostgreSQL 版)
- `Dockerfile.web` … Zabbix Web (nginx + PHP + PostgreSQL 版)

以下は Windows PowerShell 想定の手順です（Linux/Mac でもコマンドはほぼ同じ）。

## 0) 事前準備

- Docker Desktop をインストール・起動
- PowerShell を管理者で実行推奨

## 1) イメージのビルド

```powershell
# 作業ディレクトリはリポジトリのルート
docker build -f Dockerfile.manager -t zbx-manager:local .
docker build -f Dockerfile.web     -t zbx-web:local     .
```

## 2) ネットワークとデータ永続化ボリュームの作成

```powershell
docker network create zbx-net
docker volume create zbx_db
```

## 3) データベース(PostgreSQL) の起動

```powershell
docker run -d --name zbx-postgres `
  --network zbx-net `
  -e POSTGRES_USER=zabbix `
  -e POSTGRES_PASSWORD=zabbix `
  -e POSTGRES_DB=zabbix `
  -e TZ=Asia/Tokyo `
  -v zbx_db:/var/lib/postgresql/data `
  postgres:13-alpine
```

## 4) Zabbix Manager(Server) の起動

```powershell
docker run -d --name zbx-manager `
  --network zbx-net `
  -p 10051:10051 `
  -e DB_SERVER_HOST=zbx-postgres `
  -e POSTGRES_USER=zabbix `
  -e POSTGRES_PASSWORD=zabbix `
  -e POSTGRES_DB=zabbix `
  -e TZ=Asia/Tokyo `
  zbx-manager:local
```

## 5) Zabbix Web の起動

```powershell
docker run -d --name zbx-web `
  --network zbx-net `
  -p 8080:8080 `
  -e DB_SERVER_HOST=zbx-postgres `
  -e POSTGRES_USER=zabbix `
  -e POSTGRES_PASSWORD=zabbix `
  -e POSTGRES_DB=zabbix `
  -e PHP_TZ=Asia/Tokyo `
  -e ZBX_SERVER_HOST=zbx-manager `
  zbx-web:local
```

## 6) 疎通確認

- Zabbix Server のポート確認 (10051/TCP):

```powershell
Test-NetConnection -ComputerName localhost -Port 10051
```

- Zabbix Web の HTTP 応答確認 (200 などが返れば OK):

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/ | Select-Object StatusCode
```

- ログ確認（起動時のエラー調査に有用）:

```powershell
docker logs zbx-postgres --tail 100
docker logs zbx-manager  --tail 100
docker logs zbx-web      --tail 100
```

## 7) Web へアクセス

- ブラウザで `http://localhost:8080/` を開く
- 初期ログイン: ユーザー `Admin` / パスワード `zabbix`

## 8) クリーンアップ

```powershell
docker rm -f zbx-web zbx-manager zbx-postgres
docker volume rm zbx_db
docker network rm zbx-net
```

## 補足

- `Dockerfile.manager` / `Dockerfile.web` で設定している環境変数はデフォルト値です。実運用では `docker run -e ...` で上書きしてください。
- 既存の `docker-compose.yml` でも同等構成を一括起動できます。単体の Dockerfile 運用が必要な場面向けに上記手順を用意しています。

