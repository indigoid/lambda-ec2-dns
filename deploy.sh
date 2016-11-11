# npm deploy.js
set -e

#
# ASSUMES RUNNING ON CODESHIP
#
# will break locally unless you set
#   CI, CI_BRANCH and CI_COMMIT_ID
#

if [ -z ${CI+x} ]; then
  echo "ENV is not CI"
  exit 1
fi

pip install awscli

cd src/
npm install
zip -r ${HOME}/dist.zip .
cd

# the alias used on lambda is production|develop, but the branches we
# have are master|develop
case $CI_BRANCH in
  *develop*)
    ALIAS="develop"
    ;;
  *master*)
    ALIAS="production"
    ;;
  *)
    echo "Unknown branch ${BRANCH}"
    exit 1
    ;;
esac

# Preparing and deploying the function to Lambda
aws lambda update-function-code \
  --function-name $LAMBDA_FUNCTION \
  --zip-file "fileb://${HOME}/dist.zip"
# Publishing a new version of the Lambda function
version="$(aws lambda publish-version \
  --function-name $LAMBDA_FUNCTION \
  | jq -r .Version \
)"
echo "new version: $version"
# Updating the production Lambda Alias so it points to the new function
aws lambda update-alias \
  --function-name $LAMBDA_FUNCTION \
  --function-version "${version}" \
  --name $ALIAS \
  --description "${CI_COMMIT_ID} - ${CI_MESSAGE:0:212}"
