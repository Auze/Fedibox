#!/bin/zsh

IAM_AKID="{{ backup_akid }}"
IAM_SAK="{{ backup_sak }}"
IAM_REGION="eu-west-3"
IAM_ROLE="{{ backup_iam_role }}"
DOCKER_NAME="databases-postgresql-1"
DB_USER="{{ database_name }}"
DB_PWD="{{ database_password }}"
DB_NAME=("grafana" "fediland")
BACKUP_FOLDER="/data/backups/databases/"
BUCKET_NAME="fediland"
DATE=$(date +%d-%m-%y-%H:%M)

function help() {
    echo "Simple Backup PSQL on S3"
}

function configure() {
  if [ ! -f "~/.aws/credentials" ]; then
    aws configure set profile.backup.aws_access_key_id $IAM_AKID && \
    aws configure set profile.backup.aws_secret_access_key $IAM_SAK && \
    aws configure set profile.backup.region $IAM_REGION
  else  
    if grep -q "\[backup\]" ~/.aws/credentials; then
    else
      aws configure set profile.backup.aws_access_key_id $IAM_AKID && \
      aws configure set profile.backup.aws_secret_access_key $IAM_SAK && \
      aws configure set profile.backup.region $IAM_REGION
    fi
  fi
}

function backup() {
  for base in $DB_NAME[@]; do
    docker exec $DOCKER_NAME /bin/bash \
      -c "export PGPASSWORD="$DB_PWD" \
      && /usr/bin/pg_dump -U $DB_USER $base" \
      | gzip -9 > $BACKUP_FOLDER/$base-$DATE.sql.gz
  done
}

function upload() {
  aws sts assume-role --profile backup \
    --role-arn "$IAM_ROLE" \
    --role-session-name "Backup" > assume-role-output.txt
  export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' assume-role-output.txt)
  export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' assume-role-output.txt)
  export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' assume-role-output.txt)

  for base in $DB_NAME[@]; do
    aws s3 cp $BACKUP_FOLDER/$base-$DATE.sql.gz s3://$BUCKET_NAME/backups/databases/
  done
  rm assume-role-output.txt
}

function rotate() {
  for base in $DB_NAME[@]; do
    cd "$BACKUP_FOLDER" && ls -t $base*.sql.gz | tail -n +2 | xargs -I {} rm -- {}
  done

  for base in $DB_NAME[@]; do
    aws s3 ls s3://$BUCKET_NAME/backups/databases/ --recursive | grep -E "$base.*\gz" | sort -k1,2r | awk '{print $4}' >> ./tmp.txt
    tail -n +7 tmp.txt | while read -r line; do
      echo "Suppression de $line..."
      aws s3 rm s3://$BUCKET_NAME/$line
    done
    rm ./tmp.txt
  done
}

configure
backup
upload
rotate