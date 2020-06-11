# Genomics Secondary Analysis Using AWS Step Functions and AWS Batch
This solution provides a Next Generation Sequencing (NGS) genomics secondary-analysis pipeline using AWS Step Functions and AWS Batch. We demonstrate how to monitor workflow status, fail-over to on-demand, handle errors, optimize for cost, secure data with least-privileges, monitor pipeline performance and respond to issues using AWS CloudWatch.

## Running unit tests for customization
* Clone the repository, then make the desired code changes
* Next, run unit tests to make sure added customization passes the tests
```
cd ./deployment
chmod +x ./run-unit-tests.sh
./run-unit-tests.sh
```

## Building distributable for customization
* Configure the bucket name of your target Amazon S3 distribution bucket
```
export DIST_OUTPUT_BUCKET=my-bucket-name # bucket where customized code will reside
export SOLUTION_NAME=my-solution-name
export VERSION=my-version # version number for the customized code
```
_Note:_ You would have to create an S3 bucket with the prefix 'my-bucket-name-<aws_region>'; aws_region is where you are testing the customized solution. Also, the assets in bucket should be publicly accessible.

* Now build the distributable:
```
chmod +x ./build-s3-dist.sh
./build-s3-dist.sh $DIST_OUTPUT_BUCKET $SOLUTION_NAME $VERSION
```

* Deploy the distributable to an Amazon S3 bucket in your account. _Note:_ you must have the AWS Command Line Interface installed.
```
aws s3 cp ./dist/ s3://$DIST_OUTPUT_BUCKET-$AWS_REGION/$SOLUTION_NAME/$VERSION/ --recursive --acl bucket-owner-full-control
```

* Get the link of the solution template uploaded to your Amazon S3 bucket.
* Deploy the solution to your account by launching a new AWS CloudFormation stack using the link of the solution template in Amazon S3.

*** 

## File Structure

```
.
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE.txt
├── NOTICE.txt
├── README.md
├── buildspec.yml                                         [ Solution validation pipeline buildspec ]
├── deployment
│   ├── build-open-source-dist.sh
│   ├── build-s3-dist.sh                                  [ shell script for packaging distribution assets ]
│   ├── global-s3-assets
│   ├── open-source
│   ├── regional-s3-assets
│   └── run-unit-tests.sh                                 [ shell script for executing unit tests ]
├── solution-build.cfn.yml
└── source
    ├── code
    │   ├── buildspec.yml
    │   ├── cfn
    │   │   ├── cloudwatch-dashboard.cfn.yaml
    │   │   ├── core
    │   │   │   ├── batch.cfn.yaml
    │   │   │   ├── iam.cfn.yaml
    │   │   │   └── networking.cfn.yaml
    │   │   └── workflow-variantcalling-simple.cfn.yaml
    │   ├── containers
    │   │   ├── _common
    │   │   │   ├── README.md
    │   │   │   ├── aws.dockerfile
    │   │   │   ├── build.sh
    │   │   │   ├── entrypoint.aws.sh
    │   │   │   └── push.sh
    │   │   ├── bcftools
    │   │   │   └── Dockerfile
    │   │   ├── buildspec.yml
    │   │   ├── bwa
    │   │   │   └── Dockerfile
    │   │   └── samtools
    │   │       └── Dockerfile
    │   └── main.cfn.yml
    ├── pipe
    │   ├── README.md
    │   ├── buildspec.yml
    │   ├── cfn
    │   │   ├── container-buildproject.cfn.yaml
    │   │   └── iam.cfn.yaml
    │   └── main.cfn.yml
    ├── setup
    │   ├── lambda
    │   │   ├── lambda.py
    │   │   └── requirements.txt
    │   ├── setup.sh
    │   ├── teardown.sh
    │   └── test.sh
    ├── setup.cfn.yaml
    └── zone
        ├── README.md
        └── main.cfn.yml

```

***


Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.

Licensed under the Apache License Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at

    http://www.apache.org/licenses/

or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and limitations under the License.
