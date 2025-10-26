# READ2.md（CloudFormation 版：EC2 で Dockerfile を起動し Zabbix Web/Server と Aurora を構築）

Windows PC 上で Terraform を実行せず、CloudFormation テンプレート内で EC2 起動時に Dockerfile をビルド・実行する方法です。リポジトリには `cloudformation.yml` を同梱しています。

構成:
- EC2 (Zabbix Server/Manager)
- EC2 (Zabbix Web)
- Aurora (PostgreSQL)
- VPC, パブリックサブネット2つ, セキュリティグループ

両方の EC2 は UserData で Docker をインストールし、ローカルに Dockerfile を生成して `docker build` でイメージを作成後、コンテナを起動します。

## 使い方（Windows, AWS CLI）
前提: AWS CLI がセットアップ済みで、適切な権限（VPC/EC2/RDS/SG）を持つプロファイルが設定されていること。

1) パラメータを決める
- `KeyName`（既存の EC2 キーペア名）
- `DBPassword`（12文字以上・本番は強固に）

2) デプロイ
```powershell
$StackName = "zbx-cfn"
$Region    = "ap-northeast-1"  # 適宜変更

aws cloudformation deploy `
  --template-file cloudformation.yml `
  --stack-name $StackName `
  --capabilities CAPABILITY_NAMED_IAM `
  --parameter-overrides `
    KeyName=<YourKeyPairName> `
    DBPassword=<StrongPassword123!> `
    DBName=zabbix `
    DBUsername=zabbix `
    InstanceType=t3.small
```

3) 出力の確認（パブリック IP と Aurora エンドポイント）
```powershell
aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].Outputs" --output table
```

アクセス:
- Web UI: `http://<WebPublicIP>/`
- 初期ログイン: ユーザー `Admin` / パスワード `zabbix`

## テンプレートのポイント（cloudformation.yml）
- EC2 UserData で以下を実施
  - Docker インストールと起動
  - `/opt/zabbix/server/Dockerfile`（ベース: `zabbix/zabbix-server-pgsql`）を作成し `docker build -t zbx-server`、Aurora 接続情報を環境変数に渡して起動
  - `/opt/zabbix/web/Dockerfile`（ベース: `zabbix/zabbix-web-nginx-pgsql`）を作成し `docker build -t zbx-web`、Aurora 接続情報と `ZBX_SERVER_HOST` を渡して起動
- Aurora（PostgreSQL）クラスターとインスタンスを作成し、DB SG は Web/Server の SG からのみ 5432/TCP を許可
- VPC/IGW/ルート/パブリックサブネット2つ、各種 SG を同梱

## 注意事項（本番向け）
- 現在は検証向けにパブリックサブネット+PubliclyAccessible を使用。実運用はプライベートサブネット/踏み台/SSM Session Manager などを利用してください。
- セキュリティグループの許可範囲は最小化してください（`CIDRForSSH` を自宅/会社の固定 IP に限定）。
- `DBPassword` は Secrets Manager/SSM パラメータストア+KMS 連携などで安全に管理を。
- EC2 での Docker 常駐は手軽ですが、将来は ECS/EKS、または Systemd によるコンテナ管理も検討してください。

## トラブルシュート
- EC2 の初期化ログ: `/var/log/cloud-init-output.log` を確認
- コンテナの状態: `docker ps -a`、`docker logs zabbix-server` / `zabbix-web`
- DB 接続に時間がかかることがあります。数分待っても Web が起動しない場合は Aurora のステータスと SG を確認。
