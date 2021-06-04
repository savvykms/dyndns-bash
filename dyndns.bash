#!/bin/bash

#------------------------------------------------------------------------------#
#
#   Created by savvykms; https://github.com/savvykms
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#------------------------------------------------------------------------------#

HOSTED_ZONE_ID="$1"
RECORD_NAME="$2"
RECORD_TTL="${3:-300}"

RECORD_TYPE="A"
RECORD_NAME="${RECORD_NAME}."

#------------------------------------------------------------------------------#

function error_msg()
{
  >&2 echo "$@"
}

function valid_ip()
{
IP=$1
  if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    return 0;
  else
    return 1;
  fi
}

function ip_aws()
{
  curl -s "https://checkip.amazonaws.com/"
}
function ip_ipify()
{
  curl -s "https://api.ipify.org?format=text"
}
function ip_myipio()
{
  curl -s "https://api.my-ip.io/ip.txt"
}

declare -a IP_FUNCS
IP_FUNCS[1]="ip_aws"
IP_FUNCS[2]="ip_ipify"
IP_FUNCS[3]="ip_myipio"

#------------------------------------------------------------------------------#

if [[ -z "${HOSTED_ZONE_ID}" ]]; then
  error_msg "Error: no zone specified!"
  exit 1
fi

if [[ -z "${RECORD_NAME}" ]]; then
  error_msg "Error: no record name specified!"
  exit 1
fi

#Screw validating record names and TTLs
#Edge cases such as:
# - specifying the proper name format of "test.example.com." with trailing period
# - non-integer ttl values
# - invalid zone IDs
# - random keyboard mashing
#are not validated

#------------------------------------------------------------------------------#

MY_IP=

for FUNC_IND in "${!IP_FUNCS[@]}";
do
  ip=$(${IP_FUNCS[$FUNC_IND]})
  if valid_ip $ip;
  then
    MY_IP=$ip
    break;
  else
    error_msg "Error obtaining ip using ${IP_FUNCS[$FUNC_IND]}"
    error_msg "response: $ip"
  fi
done

UPDATE_RECORD="N"
CACHEFILE="/tmp/$0-${HOSTED_ZONE_ID}-${RECORD_NAME}-cache"

if [[ ! -f "$CACHEFILE" ]];
then
  echo "No cache filed detected; running"
  UPDATE_RECORD="Y"
elif [[ "$(cat "$CACHEFILE")" != "${MY_IP}" ]];
then
  echo "New IP detected ($(cat $CACHEFILE) -> ${MY_IP})"
  UPDATE_RECORD="Y"
else
  echo "No change to record detected"
fi


if [[ "x${UPDATE_RECORD}" == "xY" ]];
then
  echo "Attempting to set record"
  aws route53 change-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" --change-batch "$(cat <<-EEOOFF
{
  "Comment":"Updated by $0 at $(date --utc +"%s")",
  "Changes":[
    {
      "Action":"UPSERT",
      "ResourceRecordSet":{
        "ResourceRecords":[
          {
            "Value":"${MY_IP}"
          }
        ],
        "Name":"${RECORD_NAME}",
        "Type":"${RECORD_TYPE}",
        "TTL":${RECORD_TTL}
      }
    }
  ]
}
EEOOFF
  )" && ( echo -n "${MY_IP}" > "$CACHEFILE" )
fi
