#
# Description: Displays usage information for AWS resources
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "-?" ]]; then
	cat <<EOT
check-aws-usage: displays usage information for AWS resources
Usage: check-aws-usage
EOT
	exit 0
fi

default_region=$(aws configure get region)

regions_list=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text | tr '\t' '\n' | sort)
region_options="default ($default_region)"$'\n'"$regions_list"

if command -v gum >/dev/null 2>&1; then
	height=$(( LINES / 3 ))
	region="$(echo "$region_options" | gum choose --height=$height --header="Select a region:")"
else
	echo "Select a region"
	region="$(echo "$region_options" | fzf --no-sort -0 --height 33% --layout=reverse)"
fi

[[ -z "$region" ]] && exit 0

# Handle the selection
if [[ "$region" == "default"* ]]; then
	region="$default_region"
fi

echo -e "\nResources for $region:\n"
echo "EC2 Instances (non-terminated):"
aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[?State.Name!=`terminated`].[InstanceId,InstanceType,State.Name]' --output text

echo
echo "EBS Volumes (active):"
aws ec2 describe-volumes --region $region --query 'Volumes[?State!=`deleted`].[VolumeId,State,Size,VolumeType]' --output text

echo
echo "Elastic IPs:"
aws ec2 describe-addresses --region $region --query 'Addresses[].[PublicIp,InstanceId,AllocationId]' --output text

echo
echo "NAT Gateways (active):"
aws ec2 describe-nat-gateways --region $region --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State,VpcId]' --output text

echo
echo "Load Balancers:"
aws elbv2 describe-load-balancers --region $region --query 'LoadBalancers[].[LoadBalancerName,Type,State.Code]' --output text

echo
echo "RDS Instances:"
aws rds describe-db-instances --region $region --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' --output text