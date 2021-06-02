#!/bin/bash
# Script finds non-defined fields or values used in renderers definition
# Currently checks method sources, representsField and dependsOnValue
# usage:
#   ./check-references.sh out/xxx/
# or
#   find out/ -mindepth 1 -type d | xargs -n1 --no-run-if-empty -P4 ./check-references.sh

if [[ -z $1 ]]; then
  cat <<EOF
Usage: ./check-references.sh out/xxx/

Find non-defined fields or values used in renderers definition.

Currently checks method sources, representsField and dependsOnValue
EOF
  exit 1
fi

project=$1
projectName=$(basename "$project")

if [[ ! -f $project/fields.yaml ]] && [[ ! -f $project/fields.neon ]]; then
  echo "::[ERROR] no fields yaml in $project"
  exit 1
fi

fieldsExt=yaml
if [[ ! -f $project/fields.yaml ]]; then
  fieldsExt=neon
fi

fields_and_values=$(yaml2json "$project"/fields.$fieldsExt | jq -e '
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
')

if [[ $? -ne 0 ]]; then
  echo "could not normalize $project"/fields.$fieldsExt
  exit
fi

fields="$(echo -e "$fields_and_values" | jq -sc 'map(select(split(":")|length|.%2==1))')"
values="$(echo -e "$fields_and_values" | jq -sc 'map(select(split(":")|length|.%2==0))')"

echo -e "$fields" | jq --arg project "$projectName" -r 'length | @text "\($project) fields count: \(.)"'
echo -e "$values" | jq --arg project "$projectName" -r 'length | @text "\($project) values count: \(.)"'

renderers="$(node patch-renderers.js < "$project"/renderers.neon | yaml2json -)"

echo -e "$renderers" | jq  --arg project "$projectName" -r 'map([.type, (.rows|length)]) | map("\(.[0])(\(.[1]))") | join(", ") | @text "\($project) defined renderers: \(.)"'

echo -e "$renderers" | jq --exit-status --argjson fields "$fields" --argjson values "$values" --arg project "$projectName" -r \
  '.[] | .rows | map(if type == "array" then ({items: .}) else . end) | .. | .sources? // empty | .[] | . as $f | $fields | select(contains([$f]) == false) | $project + " " + $f'
hasInvalidSources=$?

# TODO: check dependency graph
#echo -e "$renderers" | jq --exit-status --argjson fields "$fields" --argjson values "$values" --arg project "$projectName" -r \
# '[.[] | .rows | map(if type == "array" then ({items: .}) else . end) | .. | {f: (.representsField? // empty), d: (.dependsOnValue? // empty)}] | group_by(.f) | .[] | {f: .[0].f, d: [.[] | .d]} | select(.d|unique|length > 1) | ($project + " ") + .f + (" has different depends on: ") + (.d|join(", "))'

echo -e "$renderers" | jq --exit-status --argjson fields "$fields" --argjson values "$values" --arg project "$projectName" -r \
  '.[] | .rows | map(if type == "array" then ({items: .}) else . end) | .. | .representsField? // empty | . as $f | $fields | select(contains([$f]) == false) | $project + " " + $f'
hasInvalidFields=$?

echo -e "$renderers" | jq --exit-status --argjson fields "$fields" --argjson values "$values" --arg project "$projectName" -r \
  '.[] | .rows | map(if type == "array" then ({items: .}) else . end) | .. | .dependsOnValue? // empty | . as $v | $values | select(contains([$v]) == false) | $project + " " + $v'
hasInvalidValues=$?

if [[ $hasInvalidValues -eq 4 && $hasInvalidFields -eq 4 && $hasInvalidSources -eq 4 ]]; then
  exit 0
fi

echo "::error $projectName sources=$hasInvalidSources values=$hasInvalidValues fields=$hasInvalidFields"
exit 1
