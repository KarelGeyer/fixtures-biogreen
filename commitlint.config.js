const fg = require('fast-glob')

module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': () => fg(['*'], {
      onlyDirectories: true, cwd: 'src', deep: 1
    }).then(scopes => [2, 'always', scopes])
  }
};
