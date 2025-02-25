#!/usr/bin/env bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <date in YYYY-MM-DD format>"
    exit 1
fi

DATE=$1

# Substitute DATE_PLACEHOLDER in the template with the user-supplied date
sed "s/DATE_PLACEHOLDER/$DATE/g" ~/chile-smartmet/mars/ec-ens_request_template.mars > ~/chile-smartmet/mars/ec-ens_request.mars

cd /home/users/smartmet/data

# Now run the MARS command using the modified file
cat ~/chile-smartmet/mars/ec-ens_request.mars | mars

