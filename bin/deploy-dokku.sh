#!/bin/bash

branch="$1"
project_id="$2"
module="$3"

if [[ -z $branch ]]; then
  echo "branch is not specified..."
  exit 1
fi

if [[ -z $project_id ]]; then
  echo "project id is missing"
  exit 1
fi

if [[ -z $module ]]; then
  module=list
fi

# task=$(docker service ps sc_prod_app --filter desired-state=running --format "{{.ID}}" | head -1)
task=saleschamp.web.1

if [[ -z $task ]]; then
    echo "Could not find container.."
  exit 1
fi

#container=$(docker inspect "$task"  -f "{{.Status.ContainerStatus.ContainerID}}")
container=$(docker inspect "$task"  -f "{{.ID}}")

if [[ -z $container ]]; then
    echo "Could not find container.."
  exit 1
fi

tmpid=$(uuidgen)
curdate=$(date "+%Y%m%d%H%M%S")

yarn
rm -rf out/
yarn build
cd "out/$branch"

cname=$(git rev-parse --short HEAD)
IFS=$'\n' pdata=($(docker exec "$container" ./simon a:p:l --json | jq -r ".[] | select ( .projectId == $project_id ) | .account,.project"))

pname="${pdata[1]}"
paccount="${pdata[0]}"

if [[ -z $pname ]]; then
  echo "Unkown project $project_id"
  exit 1
fi

echo "Project: $project_id - $pname ($paccount)"
echo "Name: $branch-$cname-$curdate"
echo "Module: $module"

read -p "Are you sure? " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]
then
  docker cp ./ "$container":/tmp/"$tmpid"/
  docker cp "../../bin/campaign-import.sh" "$container":/tmp/"$tmpid"/
  docker exec "$container" /tmp/"$tmpid"/campaign-import.sh "$project_id" "$branch-$cname-$curdate" /tmp/"$tmpid"/ "$module"
  echo "Regenerate database renderers"
  docker exec "$container" ./simon a:r:d:p -u 1
else
  echo "Cancelled.."
  exit 1
fi
