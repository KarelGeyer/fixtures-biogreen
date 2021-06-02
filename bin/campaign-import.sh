#!/bin/bash
#
# Script for importing Campaign Fixtures Files into SalesChamp Application
# https://google.github.io/styleguide/shellguide.html

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

RUN=./simon

PROJECTID=$1
CAMPAIGNNAME=$2
PROJECTDIR=${3%/}
MODULE=${4:-list}
ACTIVATE=0

if [[ $5 == "--activate" ]]; then
  ACTIVATE=1
fi

if [[ $4 == "--activate" ]]; then
  ACTIVATE=1
  MODULE="list"
fi

if [[ ! -f $PROJECTDIR/fields.neon && ! -f $PROJECTDIR/fields.yaml ]]; then
  err no fields.neon/yaml file
  exit 1
fi

if [[ ! -f $PROJECTDIR/interactions.neon ]]; then
  err no interactions.neon file
  exit 1
fi

if [[ ! -f $PROJECTDIR/mailing.neon ]]; then
  err no mailing.neon file
  exit 1
fi

if [[ ! -f $PROJECTDIR/renderers.neon && ! -f $PROJECTDIR/renderers.yaml ]]; then
  err no renderers.neon/yaml file
  exit 1
fi

# for sed see https://github.com/moby/moby/issues/8513
USERID=$($RUN dbal:run "select id from users u where role = 'admin' and account_id = (select a.id from accounts a left join projects p on p.account_id = a.id where p.id = $PROJECTID) and is_active = 1 limit 1" | grep -Po '"\K[0-9][^"]*' | sed -e "s/\r//")
if [[ -z $USERID ]]; then
  USERID=1
  echo "User with Admin Role not found defaulting to User with ID 1"
else
  echo "Found Admin User with ID $USERID in Project with ID $PROJECTID"
fi

# for sed see https://github.com/moby/moby/issues/8513
if [[ ! -f $PROJECTDIR/campaign.yaml ]]; then
  CAMPAIGNID=$($RUN app:campaign:create "$PROJECTID" "$CAMPAIGNNAME" "$MODULE" --no-ansi | sed -e "s/\r//")
else
  echo "Import Campaign from File:" "$PROJECTDIR/campaign.yaml"
  CAMPAIGNID=$($RUN app:fixtures:campaign:import "$PROJECTDIR/campaign.yaml" --name "$CAMPAIGNNAME" --projectId "$PROJECTID" --no-ansi | sed -e "s/\r//")
fi

if [[ -z $CAMPAIGNID || $? -ne 0 ]]; then
  err "Could not create Campaign for Project with ID $PROJECTID"
  exit 1
fi

echo "Created Campaign $CAMPAIGNNAME with ID $CAMPAIGNID"

if [[ -f $PROJECTDIR/fields.neon ]]; then
  echo "Import Fields from File:" "$PROJECTDIR/fields.neon"
  $RUN app:fixtures:fields:import -c "$CAMPAIGNID" "$PROJECTDIR/fields.neon" || exit 1
else
  echo "Import Fields from File:" "$PROJECTDIR/fields.yaml"
  $RUN app:fixtures:fields:import -c "$CAMPAIGNID" "$PROJECTDIR/fields.yaml" --input-format=yaml || exit 1
fi

echo "Import Intercation Categories from File:" "$PROJECTDIR/interactions.neon"
$RUN app:fixtures:interactions:import "$PROJECTDIR/interactions.neon" "$CAMPAIGNID" || exit 1

echo "Import Mailing Module from File:" "$PROJECTDIR/mailing.neon"
$RUN app:fixtures:modules:mailing:import "$PROJECTDIR/mailing.neon" "$CAMPAIGNID" --multi || exit 1

if [[ -f $PROJECTDIR/renderers.neon ]]; then
  echo "Import Renderers from File:" "$PROJECTDIR/renderers.neon"
  $RUN app:fixtures:renderer:import -c "$CAMPAIGNID" -u "$USERID" "$PROJECTDIR/renderers.neon" --multi || exit 1
else
  echo "Import Renderers from File:" "$PROJECTDIR/renderers.yaml"
  $RUN app:fixtures:renderer:import -c "$CAMPAIGNID" -u "$USERID" "$PROJECTDIR/renderers.yaml" --input-format=yaml --multi || exit 1
fi

if [[ $ACTIVATE -eq 1 ]]; then
  echo "Activating Campaign ID $CAMPAIGNID with User ID $USERID"
  $RUN a:c:a "$CAMPAIGNID" "$USERID" || exit 1
else
  echo "To activate Campaign run"
  echo "  ./simon a:c:a" "$CAMPAIGNID" "$USERID"
fi

echo "Done."
exit 0
