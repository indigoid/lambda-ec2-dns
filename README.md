# lambda-ec2-dns

[ ![Codeship Status for fairfax/oh-kiwiops-lambda-akamai-ccu](https://codeship.com/projects/c20816a0-ddc8-0133-ba29-6a683e002de2/status?branch=master)](https://codeship.com/projects/144511)

Designed to be integrated with Codeship.

## Event flow

CloudWatch Rule -> Lambda -> Route53


## CloudFormation

Because plugging all the moving parts together by hand is painful, lets
just do some small manual steps at the end. This assumes you already
have an IAM user for Codeship integration. It then creates:

- Codeship IAM policy (and attaches it to the specified user)
- IAM role for the Lambda function
- IAM policy for the Lambda function allowing it to do the things
- Lambda function
- CloudWatch Events Rule to trigger the Lambda function
- Production and Development aliases for the function

### Stack Creation

    export AWS_DEFAULT_REGION=appropriate_region
    aws cloudformation create-stack \
      --stack-name asoe-autodns \
      --template-body file://asoe-autodns.json \
      --capabilities CAPABILITY_IAM \
      --parameters \
        ParameterKey=HostedZoneId,ParameterValue=YOUR_HOSTED_ZONE_ID \
        ParameterKey=CodeshipIAMUser,ParameterValue=svc_codeship

### Stack Update

    export AWS_DEFAULT_REGION=appropriate_region
    aws cloudformation update-stack \
      --stack-name asoe-autodns \
      --template-body file://asoe-autodns.json \
      --capabilities CAPABILITY_IAM \
      --parameters \
        ParameterKey=HostedZoneId,ParameterValue=YOUR_HOSTED_ZONE_ID \
        ParameterKey=CodeshipIAMUser,ParameterValue=svc_codeship

## Codeship Integration

More information on this can be found here:

https://blog.codeship.com/integrating-aws-lambda-with-codeship/

## Notes

Codeship/structure based on the work of my awesome colleague, Nathan
Humphreys.  Thanks!
