#!/bin/bash
set -euo pipefail

if [[ -z $1 ]]; then
  echo "Usage: 
    $0 'out/all-in-one*'
    $0 'out/'
  "
  exit 1
fi

echo "found $(find ""$1"" -name 'mailing.neon' | wc -l) definition files"

jq -n -R --slurp -c --arg key "$MANDRILL_API_KEY" '{
    key: $key
  }' | curl --fail -XPOST https://mandrillapp.com/api/1.0/templates/list.json -d @- \
    | jq -r -s '.[1] - (.[0] | map(.slug)) | .[] | "template missing " + .' \
      - <(find "$1" -name 'mailing.neon' | xargs -n1 yaml2json | jq '.[] | .template' | jq -s 'unique')
