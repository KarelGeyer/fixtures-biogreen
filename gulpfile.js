const execSync = require('child_process').execSync;
const gulp = require('gulp')
const render = require('./lib/gulp-handlebars-render')
const relativePath = require('./lib/gulp-relative-path')
const yaml = require('js-yaml')
const toml = require('gulp-toml')
const merge = require('gulp-merge-json')
const fs = require('fs')
const debug = require('gulp-debug')
const argv = require('yargs').argv
const Path = require('path')
const _ = require('lodash')
const shell = require('gulp-shell')
const eol = require('gulp-eol')
const rename = require('gulp-rename')

const paths = {
  fixtures: {
    src: ['src/**/*.{neon,yaml,yml,hbs}', '!src/**/variables*.yaml'],
    dest: 'out/'
  },
  mappings: {
    src: 'src/**/{mapping,mapping.override,mapping.*,mapping.*.override}.toml',
    dest: 'out/'
  }
}

var config = {projects: {}}
try {
  config = require('./config')
} catch (e) {}

var contextCli = {}

// Update the context from command line
// -d foo=bar -d nested.foo=baz
if (argv.d) {
  let flags = argv.d

  if (!_.isArray(flags)) {
    flags = [flags]
  }

  flags.forEach(update => {
    const [path, value] = _.map(update.split('='), String.trim)
    _.set(contextCli, path, value)
  })
}

function fixtures() {
  let {fixtures: path} = paths
  let context = yaml.safeLoad(fs.readFileSync('variables.yaml', 'utf8'))

  return gulp.src(path.src, {base: 'src', since: gulp.lastRun(fixtures)})
    .pipe(debug())
    .pipe(render(context, contextCli))
    .pipe(gulp.dest(path.dest))
}

function mappings() {
  let {mappings: path} = paths
  const debugOpts = {
    title: 'mappings:'
  }

  return gulp.src(path.src, {base: 'src', since: gulp.lastRun(mappings)})
    .pipe(debug(debugOpts))
    .pipe(rename(path => {
      const branch = path.basename.split('.')
      if (branch.length < 2 || branch[1] === 'override') return
      path.dirname += '-' + branch[1]
      path.basename = path.basename.replace('.' + branch[1], '')
    }))
    .pipe(toml({to: JSON.stringify, ext: '.json'}))
    .pipe(eol())
    .pipe(gulp.dest(path.dest))
    .pipe(debug(debugOpts))
    .pipe(merge({
      fileName: 'mapping.json',
      jsonSpace: '  ',
      edit(parsedJson, file) {
        let branch = Path.basename(Path.dirname(file.path))

        return {
          [branch]: parsedJson
        }
      }
    }))
    .pipe(eol())
    .pipe(gulp.dest(path.dest))
    .pipe(debug(debugOpts))
}

function watch() {
  gulp.watch(paths.fixtures.src, gulp.series('default'))

  const project = argv.project
  if (project) {
    gulp.watch(`out/${project}/renderers.neon`, gulp.series(
      removeRenderers(),
      importRenderers
    ))
  }
}

// automatically reimport renderers and reload app
let simonOptions = {
  cwd: config.appPath,
  verbose: true,
}

function getProjectId(project) {
  let rawdata = fs.readFileSync('./out/mapping.json')
  let mapping = JSON.parse(rawdata)

  return mapping[project].local.project_id
}

function importRenderers() {
  const project = argv.project
  const projectId = getProjectId(project)

  const output = JSON.parse(execSync(`./simon a:p:l --json`, simonOptions))
  const baseUrl = output.filter((project) => {
    return project.projectId === projectId
  })[0].baseUrl

  return gulp.src(`out/${project}/renderers.neon`)
    .pipe(relativePath({
      cwd: config.appPath
    }))
    .pipe(shell([`./simon app:fixtures:renderer:import --multi -u 4 -p ${projectId} <%= file.path %>`], simonOptions))
    .pipe(shell([`curl -k ${baseUrl}__reload`], simonOptions))
}

function removeRenderers() {
  const projectId = getProjectId(argv.project)
  return shell.task(`./simon app:fixtures:renderer:remove -p ${projectId} --all`, simonOptions)
}

gulp.task('default', gulp.series(fixtures, mappings))

exports.fixtures = fixtures
exports.mappings = mappings
exports.watch = gulp.series('default', watch)
