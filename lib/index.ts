import { App, Stack, StackProps, RemovalPolicy, CfnOutput } from "aws-cdk-lib";
import { aws_s3 as s3 } from "aws-cdk-lib";

export interface AppStackProps extends StackProps {
  customProp?: string;
}
export class AppStack extends Stack {
  constructor(scope: App, id: string, props: AppStackProps = {}) {
    super(scope, id, props);
    const { customProp } = props;
    const defaultBucketProps = {
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    };
    const bucket = new s3.Bucket(this, "Bucket", {
      ...defaultBucketProps,
      versioned: true,
    });
    const makeBucketOutputs = (bkt: s3.Bucket, logicalId: string) => {
      new CfnOutput(this, `${logicalId}Name`, {
        value: bkt.bucketName
      });
      new CfnOutput(this, `${logicalId}DomainName`, {
        value: bkt.bucketDomainName
      })
    }
    makeBucketOutputs(bucket, "Bucket");

    const publicInsecureBucket = new s3.Bucket(this, "PublicInsecureBucket", {
      ...defaultBucketProps,
      versioned: true,
      publicReadAccess: true
    })
    makeBucketOutputs(publicInsecureBucket, "PublicInsecureBucket");

    const publicSecureBucket = new s3.Bucket(this, "PublicSecureBucket", {
      ...defaultBucketProps,
      versioned: true,
      publicReadAccess: true,
      enforceSSL: true
    })
    makeBucketOutputs(publicSecureBucket, "PublicSecureBucket")
  }
}
