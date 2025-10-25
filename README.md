---

## Docker作成手順(作成例)
1. Docker が起動しているか確認
   ``` docker --version ```
2. Dockerイメージのビルド
   ``` docker build -t myapp . ```
3. ビルドされたイメージの確認
    ``` docker images ```
4. コンテナの起動
   ``` docker run -d -p 8080:80 --name hirose myapp:latest ```
5. コンテナの確認
   ``` docker ps (-a) ```
6. コンテナの削除
   ``` docker container rm hirose ```
7. コンテナイメージの削除
   ``` docker rmi myapp ```
8. コンテナ内での実行コマンド
   ``` docker exec -it snmp-proxy sh -lc '実行したいコマンド' ```
