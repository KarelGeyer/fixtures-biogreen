/**
 * this script is for making .neon renderers files compatible with yaml,
 * it adds `items` key to rows where additional attributes are defined
 * and where object map cannot be used together with a list
 *
 * usage: node patch-renderers.js < out/xxx/renderers.neon | yaml2json | jq '.'
 */

const fs = require('fs')
const data = fs.readFileSync(0)

const lines = data.toString('utf8').split('\n')

// Find next non empty line
function nextLine(index) {
  return lines.slice(index).filter(line => !/^\s*$/.test(line))[0]
}

let state = 0
lines.forEach((line, i) => {
  if (/^      [a-z]/.test(line) && state === 0) {
    state = 1
  }
  else if (/^      \-/.test(line) && state === 1) {
    state = 2
    console.log('      items:')
  }
  else if (!/^      /.test(nextLine(i)) && state === 2) {
    state = 0
  }

  if (state === 2) line = '  ' + line

  console.log(line)
})
