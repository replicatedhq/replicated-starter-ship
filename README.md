Replicated Ship Starter (Combining upstreams)
==================

Starter project for managing a [Ship](https://ship.replicated.com) application in a GitHub repo.
This is a minimal version of the [core starter repo](https://github.com/replicatedhq/replicated-starter-ship), stripped down to highlight the usage of Ship
Cloud for deploying a [COTS](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/declarative-application-management.md) application that requires upstream components like databases to be deployed across multiple namespaces.

With this layout, you can use services like [Ship Cloud](https://ship.replicated.com) or `kotsadm` to manage your upstream components, while customizing their namespaces and bundling them together for delivery.

### Project overview

```
base
├── kustomization.yaml         # ties everything together
├── myapp-api
│   ├── config.yaml
│   ├── deployment.yaml
│   ├── kustomization.yaml     # bundles api components and sets namespace
│   ├── namespace.yaml
│   └── service.yaml
├── myapp-worker
│   ├── config.yaml
│   ├── deployment.yaml
│   ├── kustomization.yaml     # bundles worker components and sets namespace
│   ├── namespace.yaml
│   └── service.yaml
├── postgres-authdb
│   ├── kustomization.yaml     # references single rendered.yaml, sets namespace to "authdb"
│   └── rendered.yaml
├── postgres-main
│   ├── kustomization.yaml     # references single rendered.yaml, sets namespace to "maindb"
│   └── rendered.yaml
└── redis
    ├── kustomization.yaml     # references single rendered.yaml, sets namespace to "redis"
    └── rendered.yaml
```
