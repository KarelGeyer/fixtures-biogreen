const through = require('through2')
const PluginError = require('plugin-error')
const fs = require('fs')
const path = require('path')

module.exports = function (context, contextCli) {
  return through.obj(function (file, enc, cb) {
    if (file.isNull()) {
      this.push(file)
      return cb()
    }

    if (file.isStream()) {
      this.emit('error', new PluginError('gulp-handlebars-render', 'streaming not supported.'))
    }

    file.path = path.relative(path.resolve(__dirname + '/..', context.cwd || './'), file.path)

    this.push(file)
    cb()
  })
}
