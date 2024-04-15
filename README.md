# practice_rds_to_bigquery_by_datastream

AWS上のMySQLを、Google CloudのDatasreamを利用してBigQueryにレプリケーションする仕組みを検証するリポジトリです。

MySQL(AWS RDS) -> Datasream(Google Cloud) -> BigQuery(Google Cloud)

参考: https://cloud.google.com/datastream/docs/configure-amazon-rds-mysql?hl=ja

リソースに名前をつけやすくするために、アプリケーション名は`orion` としています。名前に深い意味はありません。

terraformを使用してインフラを構築しています。Dockerさえあれば再現可能です。

使い終わったらすぐ破棄することが前提のため、セキュアではない箇所が多々あります。

**重要**

Sandbox環境を立ち上げた場合は多少のコストがかかりますが、
内容やサンプルに基づくいかなる運用結果に関しても一切の責任を負いません。

## 再現手順

### 1. envファイルの用意

```
AWS_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=XXXXX
AWS_SECRET_ACCESS_KEY=XXXX
GOOGLE_CREDENTIALS='{ "type": "service_account", "project_id": XXXX, ...}'
```

**補足**

AWSとGCPのアカウントキーを発行して設定してください。

GCPのサービスアカウントキーに関しては、キーファイルダウンロードした後、下記のコマンドを実行して値を整形した上で`GOOGLE_CREDENTIALS`に設定してください。

```sh
cat key.json | tr -s '\n' ' '
```

### 2. dockerイメージのビルド

```sh
docker-compose build
```

### 3. dockerコンテナ内に入る

```sh
docker-compose run --rm app bash
```

### 4. terraformコマンドを実行

dockerコンテナ内で実行してください。

```sh
cd terraform/sandbox

terraform init

terraform plan

terraform apply
```

**補足**

- initは`terraform/sandbox`ディレクトリで行ってください
- DBを作成するため、applyには10分ほどかかります

### 5. リソースが作られたか確認

AWSとGCP上で各種リソースが作られたかを確認してください。

この時点で下記の構成は整っています。後はストリームを開始し、DBにデータを流し込むだけです。

MySQL(AWS RDS) -> Datasream(Google Cloud) -> BigQuery(Google Cloud)

### 6. ストリームを開始

GCPのDatastreamのコンソール上で作成したストリームを開始してください。

terraformではリソースを作成するだけのため、手動で開始する必要があります。

なお、ストリームが開始されるまでに5分ほど時間がかかります。

### 7. DBのセットアップとレコードの挿入

dockerコンテナ内で実行してください。

```
db-setup-table-and-insert-records -e sandbox -t foos
```

**補足**

- スクリプトは`bin`ディレクトリ内に配置されており、パスが通っています
- `-e`オプションには`sandbox`しか指定できません
- `-t`オプションには用意したいテーブル名を指定します。任意の値を指定可能です

下記コマンドで作成したDBに簡単に接続することができます。これもdockerコンテナ内で実行してください。

```
db-console -e sandbox
```

### 8. BigQueryにレプリケーションされたか確認

BigQueryのコンソール上でデータセットやテーブルを確認してください。

```
SELECT * FROM `<project-id>.orion_sandbox_db.orion_foos`;
```

### 9. データを更に挿入し、BigQueryにレプリケーションされるか確認

dockerコンテナ内で実行してください。

```
-- 既存のテーブルにインサート
db-setup-table-and-insert-records -e sandbox -t foos

-- テーブルを新規作成してインサート
db-setup-table-and-insert-records -e sandbox -t bars
```

**補足**

- 手順7と同じコマンドです。テーブルが存在する場合はレコードの挿入のみが行われます

### 10. BigQueryにレプリケーションされたか確認

BigQueryのコンソール上でデータセットやテーブルを確認してください。

### 11. リソースの削除

dockerコンテナ内で実行してください。

```
terraform destroy
```

**補足**

- DBの削除に10分ほど時間がかかります


## その他補足

### パーティション分割やクラスリングの設定について

新規に作成されるテーブルは、プライマリキーでクラスリングされます。

Datasreamの設定でパーティション分割やクラスリングの設定を変更する方法は、現時点ではなさそうです。

テーブル設定を変更する場合は、Datasreamを一時停止した後で作り直す必要があります。

下記のようなクエリでテーブルのDDL取得できるため、パーティション分割とクラスタリングの設定を書き換えればOKです。

```
SELECT ddl
FROM `<project>.<dataset>.INFORMATION_SCHEMA.TABLES`
WHERE table_name = <table-name}>
```

作業後はDatastreamを再開し、対象テーブルに対してバックフィルをかけることで、そのテーブルだけ全件ロードしなおすことができます。

また、一時的なテーブルにコピーした後にテーブルを作り直し、一時的なテーブルからINSERTすることで全件ロードすることなくDatastreamを再開させることもできると思います。

### レプリケーションの間隔について

投入したデータをすぐに反映させて動作確認したいため、今回の設定では反映の間隔を0秒にしています。

1時間や24時間といった間隔にも設定できるため、要件やコストに応じて柔軟な設定がすることができそうです。
