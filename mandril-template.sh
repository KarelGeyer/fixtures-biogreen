#!/bin/bash

# This script requires MANDRILL_API_KEY environment variable with a Mandrill API Key.
#
# ./mandrill-template.sh template-slug download
# ./mandrill-template.sh template-slug update out/xxxx/template.hbs
# ./mandrill-template.sh template-slug add out/xxxx/template.hbs

slug=$1
action=$2
file=$3

if [[ -z $MANDRILL_API_KEY ]]; then
  echo "Set MANDRILL_API_KEY environment variable"
  exit 1
fi

if [[ -z $slug ]]; then
  echo "cound not find brand $slug"
  exit 1
fi

if [[ $action == "download" ]]; then
  jq --arg slug "$slug" --arg key "$MANDRILL_API_KEY" -n '{name: $slug, key: $key}' | curl -XPOST https://mandrillapp.com/api/1.0/templates/info.json -s -d @- | jq -r '.publish_code'
  exit 1
fi

if [[ $action == "update" ]]; then
  colordiff "$file" <(jq --arg slug "$slug" --arg key "$MANDRILL_API_KEY" -n '{name: $slug, key: $key}' | curl -XPOST https://mandrillapp.com/api/1.0/templates/info.json -s -d @- | jq -r '.publish_code')

  if [[ $? -eq 1 ]]; then
    echo "template differs from current template"
  fi

  read -p "Do you want to update the template in Mandrill? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    jq --arg slug "$slug" --arg key "$MANDRILL_API_KEY" \
      -R --slurp '{name: $slug, key: $key, code: ., labels: ["autoupload"]}' < "$file" | curl -XPOST https://mandrillapp.com/api/1.0/templates/update.json -d @-
    exit 0
  fi
  echo "Abort."
fi

if [[ $action == "add" ]]; then

  read -p "Do you want to add template to Mandrill? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    jq --arg slug "$slug" --arg key "$MANDRILL_API_KEY" \
      -R --slurp '{name: $slug, key: $key, code: ., labels: ["autoupload"]}' < "$file" | curl -XPOST https://mandrillapp.com/api/1.0/templates/add.json -d @-
    exit 0
  fi
  echo "Abort."
fi
