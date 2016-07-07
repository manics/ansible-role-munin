#!/bin/bash

# Slack notification script for Munin
# Mark Matienzo (@anarchivist)
#
# To use:
# 1) Create a new incoming webhook for Slack
# 2) Edit the configuration variables that start with "SLACK_" below
# 3) Add the following to your munin configuration:
#
# # -- Slack contact configuration
# contact.slack.command MUNIN_SERVICESTATE="${var:worst}" MUNIN_HOST="${var:host}" MUNIN_SERVICE="${var:graph_title}" MUNIN_GROUP=${var:group} /usr/local/bin/notify_slack_munin
# contact.slack.always_send warning critical
# # note: This has to be on one line for munin to parse properly
# contact.slack.text ${if:cfields \u000A* CRITICALs:${loop<,>:cfields  ${var:label} is ${var:value} (outside range [${var:crange}])${if:extinfo : ${var:extinfo}}}.}${if:wfields \u000A* WARNINGs:${loop<,>:wfields  ${var:label} is ${var:value} (outside range [${var:wrange}])${if:extinfo : ${var:extinfo}}}.}${if:ufields \u000A* UNKNOWNs:${loop<,>:ufields  ${var:label} is ${var:value}${if:extinfo : ${var:extinfo}}}.}${if:fofields \u000A* OKs:${loop<,>:fofields  ${var:label} is ${var:value}${if:extinfo : ${var:extinfo}}}.}


if [ -z "$SLACK_TOKEN" ]; then
    echo "SLACK_TOKEN required"
    exit 2
fi
SLACK_CHANNEL="${SLACK_CHANNEL:-#general}"
SLACK_USERNAME="${SLACK_USERNAME:-munin}"
SLACK_ICON_EMOJI="${SLACK_ICON_EMOJI:-:computer:}"
SLACK_NOTIFICATION="${SLACK_NOTIFICATION:-}"
SLACK_MUNIN_URL="${SLACK_MUNIN_URL:-http://localhost/munin/problems.html}"

input=`cat`

#Set the message icon based on service state
if [ "$MUNIN_SERVICESTATE" = "CRITICAL" ]
then
    ICON=":exclamation:"
    COLOR="danger"
elif [ "$MUNIN_SERVICESTATE" = "WARNING" ]
then
    ICON=":warning:"
    COLOR="warning"
elif [ "$MUNIN_SERVICESTATE" = "ok" ]
then
    ICON=":white_check_mark:"
    COLOR="good"
elif [ "$MUNIN_SERVICESTATE" = "OK" ]
then
    ICON=":white_check_mark:"
    COLOR="good"
elif [ "$MUNIN_SERVICESTATE" = "UNKNOWN" ]
then
    ICON=":question:"
    COLOR="#00CCCC"
else
    ICON=":white_medium_square:"
    COLOR="#CCCCCC"
fi

# Generate the JSON attachment
ATTACHMENT="{\"color\": \"${COLOR}\", \"fallback\": \"Munin alert - ${MUNIN_SERVICESTATE}: ${MUNIN_SERVICE} on ${MUNIN_HOST}\", \"pretext\": \"${ICON} Munin alert ${SLACK_NOTIFICATION} - ${MUNIN_SERVICESTATE}: ${MUNIN_SERVICE} on ${MUNIN_HOST} in ${MUNIN_GROUP} - <${SLACK_MUNIN_URL}|View Munin>\", \"fields\": [{\"title\": \"Severity\", \"value\": \"${MUNIN_SERVICESTATE}\", \"short\": \"true\"}, {\"title\": \"Service\", \"value\": \"${MUNIN_SERVICE}\", \"short\": \"true\"}, {\"title\": \"Host\", \"value\": \"${MUNIN_HOST}\", \"short\": \"true\"}, {\"title\": \"Current Values\", \"value\": \"${input}\", \"short\": \"false\"}]}"

# Send message to Slack
# --data-urlencode "parse=full" \
curl -s -o /dev/null \
    --data-urlencode "token=$SLACK_TOKEN" \
    --data-urlencode "channel=$SLACK_CHANNEL" \
    --data-urlencode "attachments=[$ATTACHMENT]" \
    https://slack.com/api/chat.postMessage 2>&1
