Replicated Ship Starter (Airgap Edition)
==================

Starter project for managing a [Ship](https://ship.replicated.com) application in a GitHub repo.
This is a minimal version of the [core starter repo](https://github.com/replicatedhq/replicated-starter-ship), stripped down to highlight the usage of Ship
for deploying a [COTS](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/declarative-application-management.md)
application to an **Airgapped** Kubernetes cluster.

### Prequisites

- `make`
- `node` is optional, but adds linting to your app
- `ship` installed. On macOS, you can use `brew install ship` to install with Homebrew

**Note:** While Ship supports any git repository, this example leverages features that are GitHub-only (for now). The repo you create can be private or public.

### Project overview

This project contains an example application that can be deployed with ship. The main pieces are

- `base` -- Kubernetes YAML that defines the application
- `ship.yaml` -- ties these pieces together into a deployable application
- `Makefile` -- Workflows for testing the application installation experience
- [CI integration](#integrate-with-ci) starters for testing changes to your application.

### Get started

First, clone the repo and re-initialize it

```
export MY_APP_NAME=my-cool-app

git clone https://github.com/replicatedhq/replicated-starter-ship.git ${MY_APP_NAME}
cd ${MY_APP_NAME}
rm -rf .git
git init
git add .
git commit -m "initial commit"
git remote add origin <your git repo>
```

### Hello, World!

You can test this out by launching ship with

    make run-local

This will open a browser and walk you through configuring the application defined in `ship.yaml`. 
The test application creates a small Kubernetes Deployment to run Nginx, but it's a good way to get a sense of how ship works.

You can inspect the YAML at `tmp/rendered.yaml`, and deploy the app using kubectl by running

    make deploy-ship

or

    kubectl apply -f tmp/rendered.yaml


### Iterate on your App

From here, you can add messaging and configuration options in the [config](https://ship.replicated.com/reference/config/items/) and [lifecycle](https://ship.replicated.com/reference/lifecycle/overview/) sections of `ship.yaml`, and modify YAML in `base` to match your kubernetes YAML.

The above

    make run-local

task can be run again to see the new changes. To iterate without using the UI, you can use

    make run-local-headless

to regenerate assets. State will be stored in `tmp/.ship/state.json` between runs, and will persist any changes to config options or Kustomize patches. To deploy it after running, you can

    make run-local-headless deploy

### License

MIT


## Troubleshooting

#### `make run-local` fails with `github asset returned no files`

1. Double check the `assets.v1.github` entries in your ship.yaml match the `--set-github-contents` flags in your `Makefile`.

2. Note that the `make run-local` and `make run-local-headless` tasks don't handle symlinks well. If you have symlinks in your repo, or you've symlinked the repo root, this can cause issues. To determine if this is the cause, you can temporarily replace symlinks with the content they point to.
