# Fixtures

To setup new project add a new directory into `./src` and put all the
fixtures there.  Assets (images) are in the top-level `assets`
directory, you can reference them with relative paths
`./../../assets/file.png` from project definitions (usually
`project.neon`).

## Layout

Every project has its own directory inside `./src` where all the setup
files are stored.

Actual deployment is done from the same directory mirrored in `./out`,
these are the files which were pre-processed in the `build` step (see
[templating](#templating)).

## Development

Simple howtos for getting started.

### Import project
[![asciicast](https://asciinema.org/a/DyB7OJQre5uhJ9niXjbutZrKI.svg)](https://asciinema.org/a/DyB7OJQre5uhJ9niXjbutZrKI)

### Import campaign
[![asciicast](https://asciinema.org/a/sJOrz4mumZzhlkaGmyIcyAbj7.svg)](https://asciinema.org/a/sJOrz4mumZzhlkaGmyIcyAbj7)

## Automatic copy of project folder

When additional `variables.yaml` file is defined in `src/x/variables.y.yaml`, new folder will be created in `out/` directory - `out/x-y`. This is exact copy of project x, but compiled with different variable file. For now there is no variables merging, so all custom defined variables have to be defined in additonal config as well.

## Automatic reimport of renderers on source file changes

First, you need to add a local mapping from the project to the
`projectId` of your local installation of SalesChamp.

Go to the project directory, for example `src/mm/` for MediaMarkt, and
add a file called `mapping.override.toml` with the following content:

``` toml
[local]
project_id = 17
```

where `17` needs to be replaced by the ID of the project on your computer.

To get the `projectId` you can use `./simon app:project:list` from the
application directory.

The last step is to configure the path to the application.  Go to the
root of the fixtures directory and add a file `config.js` with the
following content:

``` javascript
module.exports = {
  appPath: '/home/matus/dev/application',
}
```

Then go back to the fixtures directory and run `yarn gulp watch
--project <PROJECT>`, where `<PROJECT>` is the name of the directory
of the project in the `./src` hierarchy.

Now after every change the fixtures will be reimported to SalesChamp
and the application will reload.

## Scripts

Run `yarn` and `composer install` to install all the dev tools.  This
requires [node.js](https://github.com/creationix/nvm) and php7 with
[composer](https://getcomposer.org/download/).

### Linters

To run the tests use `yarn test` to print the errors or `yarn fix` to
apply `.editorconfig` fixes automatically.

### Templating

All the input files support [handlebars](https://handlebarsjs.com/)
syntax for templating.

This does mean that all *fixture* files (those in `src/` folder renderers, fields, mailing, 
email-templates, etc.) are run first trough the Handlebars where context
of Handlebars is populated from variables.yaml files (top level variables
can be overriden with project specific). In general, files inside `src/` folder
are all Handlebars templates, that can have differ content (YAML, html, neon, json, etc..),
but only files in `out/` should be valid YAML, html, neon, json files. Handlebars is derived from
[Mustache](https://mustache.github.io/), and although is built mainly for HTML it is not
strictly bound to it, and you can use whatever text based source file you want.

This whole process was inspired by [Kubernetes Helm Charts](https://helm.sh/), that also [supports templating](https://helm.sh/docs/chart_template_guide/values_files/), but trough the [Go
templates](https://golang.org/pkg/html/template/#hdr-Introduction).

In practice it can look like this:

File `src/my-project/fields.yaml`
``` handlebars
# This is YAML comment with {{ Handlebars }}
# {{! This is Handlebars comment not shown in output file }}
- type: status
  values: [ NT, DEMO ]
```

Please note the example above uses Handlebars syntax, instead of YAML, with YAML syntax it would look like
``` yaml
# This is YAML comment with {{ Handlebars }}
# {{! This is Handlebars comment not shown in output file }}
- type: status
  values: [ NT, DEMO ]
```

Difference is only in colors shown, with Handlebars syntax you see the Handlebars variable highlighted (`{{ Handlebars }}`), with YAML
you see YAML syntax highlighted (`type, values, status, list of NT, DEMO`).

The file after compilation (`yarn build -d Handlebars=Handlebars`) would end up in `out/my-project/fields.yaml` like:
```yaml
# This is YAML comment with Handlebars
# 
- type: status
  values: [ NT, DEMO ]
```

You should see that file does not contain Handlebars content (such as Variable expression and comment) as it was renderered trough the build process. You can also view this particular example in the [Handlebars Playground](https://handlebarsjs.com/playground.html#format=1&currentExample=%7B%22template%22%3A%22%23%20This%20is%20YAML%20comment%20with%20%7B%7B%20Handlebars%20%7D%7D%5Cn%23%20%7B%7B!%20This%20is%20Handlebars%20comment%20not%20shown%20in%20output%20file%20%7D%7D%5Cn-%20type%3A%20status%5Cn%20%20values%3A%20%5B%20NT%2C%20DEMO%20%5D%22%2C%22partials%22%3A%5B%5D%2C%22input%22%3A%22%7B%5Cn%20%20Handlebars%3A%20%5C%22Handlebars%5C%22%5Cn%7D%5Cn%22%2C%22output%22%3A%22%23%20This%20is%20YAML%20comment%20with%20Handlebars%5Cn%23%20%5Cn-%20type%3A%20status%5Cn%20%20values%3A%20%5B%20NT%2C%20DEMO%20%5D%22%2C%22preparationScript%22%3A%22%22%2C%22handlebarsVersion%22%3A%224.7.7%22%7D).

Run `yarn build` to generate the final fixtures, they are placed in
`./out` directory.  Do not commit this directory.

Run `yarn gulp watch` to automatically rebuild changed files.  Useful
while developing.

The context is computed from multiple hierarchical sources, currently:

1. global
2. project specific
3. cli

All the settings are recursively merged and the order of preference is
as listed above with the higher numbers having higher precedence.

The global context for all the projects is stored in `variables.yaml`
in the project root.

We can update this context with project specific settings by placing a
`variables.yaml` file with project specific values file into the
project directory.

Context can also be edited from command line by using `-d` flag with
an argument `path=value`.  Path should be supplied in the format that
lodash's [set](https://lodash.com/docs/#set) can understand.  The `-d`
flag can be used multiple times to supply more values.  Make sure the
whole expression is quoted if there are spaces so that it is taken in
as a single argument!

``` shell
yarn build -d no.need.to.quote=value -d 'should.quote = value-with-spaces-around-equal' -d 'should.also.quote = value with spaces in body'
```

**NOTE**: remember to check the resulting files for whitespace issues, see
[whitespace control](https://handlebarsjs.com/guide/expressions.html#whitespace-control).
Run the linters to see if the files are readable.

