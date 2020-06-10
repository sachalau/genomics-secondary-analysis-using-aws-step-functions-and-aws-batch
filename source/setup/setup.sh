#!/usr/bin/env bash

# Expected environment variables
# PROJECT_NAME
#   Name of the parent solution stack created.
#
# ARTIFACT_BUCKET
#   S3 bucket for solution artifacts
#
# ARTIFACT_KEY_PREFIX
#   Prefix for specific version of solution artifacts
#
# SMOKE_TEST
#   Optional flag to run smoke test once solution is installed

set -e
set -x

function get-repo-url() {
  local stack_name=$1
  local url=$(\
    aws cloudformation \
      describe-stacks \
      --stack-name $stack_name \
      --query 'Stacks[].Outputs[?OutputKey==`RepoCloneUrl`].OutputValue' \
      --output text
  )
  
  echo $url
}

function wait-for-stack() {
  local stack_name=$1
  local exists_attempts=${2:-6}  # default is six attempts
  local status=0

  set +e

  echo "Creating stack: $stack_name"
  for ((attempt=1;attempt<=$exists_attempts;attempt++)); do
    echo "Waiting for stack creation - attempt: $attempt"
    aws cloudformation \
      wait stack-exists \
      --stack-name $stack_name
    # checks every 5s, up to 20 checks -> timeout = 100s per attempt

    status=$?
    if [ "$status" -eq 0 ]; then
      break
    fi
  done

  if [ ! "$status" -eq 0 ]; then
    echo "[ERROR] Stack creation could not be started."
  else
    aws cloudformation \
      wait stack-create-complete \
      --stack-name $stack_name
    # checks every 30s, up to 120 checks -> timout = 3600s
    
    status=$?
    if [ ! "$status" -eq 0 ]; then
      echo "[ERROR] Stack creation could not be completed"
    fi
  fi

  return $status
}

BASEDIR=`pwd`
PROJECT_NAME=${PROJECT_NAME:-GenomicsWorkflow}
PROJECT_NAME_LOWER_CASE=`echo "$PROJECT_NAME" | awk '{print tolower($0)}'`

STACKNAME_ZONE=${PROJECT_NAME}Zone
STACKNAME_PIPE=${PROJECT_NAME}Pipe
STACKNAME_CODE=${PROJECT_NAME}Code

# Create Stack for GenomicsWorkflowZone

cd $BASEDIR/zone

aws cloudformation \
  create-stack \
  --stack-name $STACKNAME_ZONE \
  --template-body file://main.cfn.yml \
  --parameters \
      ParameterKey=Project,ParameterValue=${PROJECT_NAME} \
      ParameterKey=ProjectLowerCase,ParameterValue=${PROJECT_NAME_LOWER_CASE} \
  --capabilities CAPABILITY_IAM \
  --enable-termination-protection \
  --output text

aws cloudformation \
  wait stack-create-complete \
  --stack-name $STACKNAME_ZONE

ZONE_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACKNAME_ZONE --query 'Stacks[].Outputs[?OutputKey==`ZoneBucket`].OutputValue' --output text)
echo ${ZONE_BUCKET}


# Download reference genome and copy into bucket, to be indexed and run into kraken
python download_references.py
mkdir fastas/ taxdump/
mv *.fna fastas/
wget -q ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
wget -q ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
tar xf taxdump.tar.gz --directory taxdump/

aws s3 cp --quiet --recursive fastas/ s3://$ZONE_BUCKET/references/mycobacterium/library/added/
aws s3 cp --quiet nucl_gb.accession2taxid.gz s3://$ZONE_BUCKET/references/mycobacterium/taxonomy/
aws s3 cp --quiet --recursive taxdump/ s3://$ZONE_BUCKET/references/mycobacterium/taxonomy/



git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

# Create Stack for GenomicsWorkflowPipe
# This is triggered when code is pushed to the CodeCommit repository created by Zone
cd $BASEDIR/pipe

git init
git add .
git commit -m "first commit"
git remote add origin $(get-repo-url $STACKNAME_ZONE)
git push -u origin master

wait-for-stack $STACKNAME_PIPE
status=$?
set -e
if [ ! "$status" -eq 0 ]; then
  echo "[ERROR] $STACKNAME_PIPE Stack FAILED"
  exit 255
fi

aws cloudformation update-termination-protection --enable-termination-protection --stack-name $STACKNAME_PIPE

# Create Stack and initial build for GenomicsWorkflowCode
# This is triggered when code is pushed to the CodeCommit repository created by Pipe
cd $BASEDIR/code

git init
git add .
git commit -m "first commit"
git remote add origin $(get-repo-url $STACKNAME_PIPE)
git push -u origin master
    

wait-for-stack $STACKNAME_CODE
status=$?
set -e
if [ ! "$status" -eq 0 ]; then
  echo "[ERROR] $STACKNAME_CODE Stack FAILED"
  exit 255
fi

set +e

RESULTS_BUCKET=$(aws cloudformation describe-stacks --stack-name $STACKNAME_CODE --query 'Stacks[].Outputs[?OutputKey==`JobResultsBucket`].OutputValue' --output text)

echo $RESULTS_BUCKET

aws batch \
  submit-job \
    --job-name BuildKrakenDatabase \
    --job-queue ${PROJECT_NAME}LowPriority \
    --job-definition ${PROJECT_NAME_LOWER_CASE}-kraken \
    --container-overrides 'memory=24000,command=[gzip,-d,mycobacterium/taxonomy/nucl_gb.accession2taxid.gz,&&,kraken-build,--build,-db,mycobacterium],environment=[{name=JOB_INPUTS,value=s3://'"$ZONE_BUCKET"'/references/*},{name=JOB_OUTPUT_PREFIX,value=s3://'"$RESULTS_BUCKET"'/references/mycobacterium/},{name=JOB_OUTPUTS,value=mycobacterium/database.idx mycobacterium/database.kdb}]'

aws batch \
  submit-job \
  --job-name IndexReferenceBwa \
  --job-queue ${PROJECT_NAME}LowPriority \
  --job-definition ${PROJECT_NAME_LOWER_CASE}-bwa \
  --container-overrides 'command=[bwa,index,GCF_000195955.2_ASM19595v2.fna],environment=[{name=JOB_INPUTS,value=s3://'"$ZONE_BUCKET"'/references/mycobacterium/library/added/GCF_000195955.2_ASM19595v2.fna},{name=JOB_OUTPUT_PREFIX,value=s3://'"$RESULTS_BUCKET"'/references/mycobacterium/library/added},{name=JOB_OUTPUTS,value=GCF_000195955.2_ASM19595v2.fna.bwt}]'



# SMOKE TEST HERE
if [[ $SMOKE_TEST && $SMOKE_TEST == 1 ]]; then
  cd $BASEDIR
  . ./setup/test.sh
fi
