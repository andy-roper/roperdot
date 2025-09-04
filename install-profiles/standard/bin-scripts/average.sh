#
# Description: Prints the average of several values
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
values=$#
sum=0
while [[ $# -gt 0 ]]; do
    sum=$(echo "scale=4;$1+$sum" | bc)
    shift
done
echo | awk -v sum=$sum -v values=$values '{ printf "%.2f", (sum / values) }'