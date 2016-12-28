var aws = require('aws-sdk');
var ec2 = new aws.EC2();
var route53 = new aws.Route53();
var s3 = new aws.S3();

exports.handler = function(event, context) {
    ourname_domain = process.env.route53_hosted_zone_name;
    if(event.detail["instance-id"] === undefined) {
        context.fail(new Error("No instance_id, halp: " + JSON.stringify(event)));
    }
    instance_id = event.detail["instance-id"];
    var describe_instances_params = { InstanceIds: [ instance_id ], };
    ec2.describeInstances(describe_instances_params, function(err, data) {
        if (err) {
            context.fail(new Error("DescribeInstances failed: " + err));
        } else {
            // there should be exactly one instance returned
            if (data.Reservations[0] && data.Reservations[0].Instances[0]) {
                var ip = data.Reservations[0].Instances[0].PublicIpAddress;
                console.log(instance_id + " => " + ip);
                var fqdn = instance_id + "." + ourname_domain;
                var route53_change_rrs_params = {
                    ChangeBatch: {
                        Changes: [ {
                            Action: 'UPSERT',
                            ResourceRecordSet: {
                                Name: fqdn,
                                Type: 'A',
                                ResourceRecords: [ { Value: ip }, ],
                                TTL: 300,
                            }
                        }, ],
                    },
                    HostedZoneId: process.env.route53_hosted_zone_id
                };
                route53.changeResourceRecordSets(route53_change_rrs_params, function(err, data) {
                    if (err) {
                        console.log(err + "\n" + route53_change_rrs_params, err.stack);
                    } else {
                        context.succeed("upserted DNS record: " + fqdn + " => " + ip);
                    }
                });
            } else {
                context.fail(new Error("no instance info present: " + data));
            }
        }
    });
};
