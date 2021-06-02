/**
 * Heavily inspired by gulp-handlebars-render
 * modified version without extension changes
 */
const through = require('through2')
const Handlebars = require('handlebars')
const PluginError = require('plugin-error')
const fs = require('fs')
const path = require('path')
const yaml = require('js-yaml')
const deepmerge = require('deepmerge')
const globby = require('globby')
const Vinyl = require('vinyl')


Handlebars.registerHelper('padding', require('./handlebars-helper-padding'));
Handlebars.registerHelper('infoField', require('./handlebars-helper-info-field'));
Handlebars.registerHelper('exportField', require('./handlebars-helper-export-field'));
Handlebars.registerHelper('eq', require('./handlebars-helper-eq'));

function loadPartials(file) {
  const partialsGlob = ['**/*', '!.gitignore', '!README.md'];

  const registerPartial = (partialsDir) => (fileName) => {
    const basePartialName = path.basename(fileName, path.extname(fileName));
    const partialName = path.join(path.dirname(fileName), basePartialName);
    const content = fs.readFileSync(path.join(partialsDir, fileName), 'utf8');
    Handlebars.registerPartial(partialName, content);
  }

  // Remove all partials, we will load them from the current context.
  Handlebars.partials = {}

  // Load global patials.
  const globalPartialsDir = path.join(process.cwd(), 'partials');
  globby
    .sync(partialsGlob, { cwd: globalPartialsDir, onlyFiles: true })
    .forEach(registerPartial(globalPartialsDir));

  // Load project-specific partials.  In case of duplicate partials,
  // these will replace the globally defined ones.
  const partialsDir = path.dirname(file.path) + '/partials';
  globby
    .sync(partialsGlob, { cwd: partialsDir, onlyFiles: true })
    .forEach(registerPartial(partialsDir));
}

module.exports = function (context, contextCli) {
  return through.obj(function (file, enc, cb) {
    if (file.isNull()) {
      this.push(file)
      return cb()
    }

    if (file.isStream()) {
      this.emit('error', new PluginError('gulp-handlebars-render', 'streaming not supported.'))
    }

    Handlebars.registerHelper('helperMissing', function() {
      var options = arguments[arguments.length - 1];
      throw new Error(`Unknown field '${options.name}' while processing '${file.path}'`);
    });

    loadPartials(file);

    var contexts = {}
    try {
      let varFiles = globby.sync('variables*.yaml', { cwd: path.dirname(file.path), onlyFiles: true })
      contexts = varFiles.reduce((acc, varFile) => ({
        ...acc,
        [
          [
            path.basename(path.dirname(file.path)),
            varFile.replace('variables.', '').replace(/\.?yaml$/, '')
          ].filter(Boolean).join('-')
        ]: yaml.safeLoad(fs.readFileSync(path.dirname(file.path) + '/' + varFile, 'utf8'))
      }), {})
    } catch (e) {
      console.error(e)
    }

    const template = Handlebars.compile(file.contents.toString())

    for (var k in contexts) {
      var f = new Vinyl({
        base: file.base,
        cwd: file.cwd,
        path: path.dirname(path.dirname(file.path)) + '/' + k  + '/' + file.basename,
        contents: new Buffer(template(deepmerge.all([context, contexts[k], contextCli])))
      })
      this.push(f)
    }

    cb()
  })
}
