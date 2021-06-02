## deploy-dokku.sh
Special script for deploying fixtures to application running on dokku platform. This script will also install all dependencies and runs `yarn build` for you.

### Usage
```
bin/deploy-dokku.sh fixtures-folder PROJECTID MODULE

# example
bin/deploy-dokku.sh f2f-red-promo-ls 1 location
```


# Limitations
Creating new project has to be currently done manually by copying the files over to the docker container using docker cp. Best place to store these files is under `/tmp` and then continue with `dokku enter` and `./simon a:f:p:i /tmp/xxxx/project.neon`.

## FAQ

### The jobs don't run because the token expired

Go to https://rundeck.staging-apps.saleschamp.io/user/profile and under `User API Tokens` generate a new token.  Use this data:

- username: simon
- roles: read_only

Then go to the Gitlab project ci/cd settings https://gitlab.do.saleschamp.io/SalesChamp/fixtures-budgetenergie-mediamarkt/settings/ci_cd and edit the `RUNDECK_AUTH_TOKEN` to the value generated in rundeck.  Save variables.
