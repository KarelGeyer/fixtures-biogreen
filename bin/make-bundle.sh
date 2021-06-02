#!/bin/bash

if [[ -z $1 ]]; then
  echo
fi

project=$1

if [[ ! -f $project/fields.yaml && ! -f $project/fields.neon ]]; then
  echo "no fields.{yaml,neon} found"
  exit 1
fi

fieldsExt="yaml"
if [[ ! -f $project/fields.yaml ]]; then
  fieldsExt="neon"
fi

set -e

jq -s 'reduce .[] as $item ({}; . * $item)' <(yaml2json "$project"/campaign.yaml | jq '{campaign: .}') \
  <(yaml2json "$project"/fields."$fieldsExt" | jq '
    # normalize value definition into { key, value } pair
    # supports array<string>, {[key]: value}
    def v: if type == "object" then to_entries elif (.[0]? | type == "string") then to_entries else . end;

    # normalize path
    def n($path; $val): if $path == "" then "" else $path + ":" end + ($val|tostring);

    # this method adds path property to every field or value
    def resolve_paths($path; prop):
      reduce .[] as $item ([]; . + [$item + {
          path: n($path; if prop == "values" then $item.name else $item.key end)
        } + 
        if prop == "values" then {
          values: ($item.values? // []) | v | resolve_paths(n($path; $item.name); "fields")
        } else {
          fields: ($item.fields? // []) | resolve_paths(n($path; $item.key); "values")
        }
        end
      ]);

    resolve_paths(""; "values") | .. | .path? // empty
  ' | jq '{campaign: {fields: .}}') \
  <(basename "$project" | jq -R '{path: .}') \
  <(node patch-renderers.js < "$project"/renderers.neon | yaml2json - | jq '{campaign: { renderers: . }}') \
  <(yaml2json "$project"/interactions.neon | jq '{campaign: {interactions: .}}') \
  <(yaml2json "$project"/project.neon | jq '{project: .}') \
  <(yaml2json "$project"/mailing.neon | jq '{campaign: {modules: {mailing: .}}}') \
  <(find "$project"/ -name '*.hbs' -exec jq -R '.' {} \; | jq -s '{templates: {mailing: .}}')
