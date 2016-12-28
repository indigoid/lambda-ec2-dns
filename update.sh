#!/bin/sh

# invocation: ./update.sh stack_name [ParameterKey=NewParameter,ParameterValue=NewParameterValue]

# requires: jq, mktemp, AWS CLI
# optional: cfn-tail

tmpfile="$(mktemp -t "$(basename $0)")"

cleanup() {
  rm -f "$tmpfile"
}

die() {
  cleanup
  echo "$0: fatal: $*"
  exit 1
}

trap cleanup 1 15 EXIT

stack_name="$1"

test -x "$(which jq)"  || die "'jq' not found in \$PATH"
test -x "$(which aws)" || die "'aws' not found in \$PATH"
test -z "$stack_name"  && die "no CloudFormation stack name supplied"

shift

aws cloudformation describe-stacks --stack-name "$stack_name" > "$tmpfile"
parameters="$(jq -r '.Stacks[0].Parameters[] | "ParameterKey=" + .ParameterKey + ",UsePreviousValue=true"' "$tmpfile")"
capabilities="$(jq -r '.Stacks[0].Capabilities | join(",")' "$tmpfile")"

aws cloudformation update-stack \
  --stack-name $stack_name \
  --template-body file://asoe-autodns.json \
  --capabilities "$capabilities" \
  --parameters $parameters \
  $@

if [ "$?" == "0" ] && [ -x "$(which cfn-tail)" ] ; then
  cfn-tail $stack_name
fi
