# Dictum State Machine
## Introduction
The Dictum State Machine is a framework and extensible program for managing declarative configurations. 

## Components
### - Environment Definition:  
An initialized workspace organized with adherence to modular design and code reuse principals. Uses git submodules to import common or generalized components that are applied by the State Machine.
### - State Machine:  
A program that reads an Environment Definition and applies the defined configuration. The State Machine combines the sequential application of declarative configuration patterns with imperative task execution for things like health checking and secrets management.
### - Resources: 
Any files that are referenced by the State Machine while applying the defined state of the environment. Resources must adhere to certain design patterns when being called in the execution of State Machine tasks.

## Process
When the State Machine is run, it first locates the `.state` file in the workspace root and attempts to retrieve an existing state ConfigMap with the current kubectl context. If an existing State is found, the existing state is compared to the incoming state. Resources present in the existing state that are missing from the incoming state are deleted from the environment. If no existing state is found, the incoming state is then applied to the environment. Resources in the incoming state are applied sequentially (from top to bottom). Resources are listed in `.state` as key/value pairs with the following syntax: `name-descriptor-res_type: file/path/to/resource`

**Note:** For now, the name and descriptor of the key are mostly arbitrary and used for the administrator to identify resources, but if the key changes, the resource will be deleted from the environment before being applied by the State Machine.  

The res_type identifies the executor with which the resource will be managed.  For example, the State machine processing `nexus-deployment-kubectlk: nexus/nexus-deploy/` would result in either `kubectl apply -k /literal/path/nexus/nexus-deploy/` or `kubectl delete -k /literal/path/nexus/nexus-deploy/`

Every environment must be managed by an order of operations. Resources will inevitably rely on dependencies. The State machine addresses an Environment's order of operations by applying configurations sequentially, but this is not enough for complex environment provisioning, management, and updating. The State Machine also executes process helpers between resource application that allow administrators to dynamically configure things like health checking and resource availability checks. This enables the State Machine to pause, wait, or fail between configuration applications as needed.

## Getting Started

Prereq1: you will need an empty git repo.  
Prereq2: Read requirements.txt for a list of application dependencies.  
Prereq3: Have an available kubernetes cluster in your default kubectl context.

1. At the root of the git repo, create a file called `.state`.
2. Add the State Machine repo as a git submodule within your current repo. Make sure to use a tagged release: `git submodule add -b alpha1 https://github.com/Dictum-SM/state.git state`  
3. Copy and paste the following ConfigMap into `.state`:
```
apiVersion: v1
kind: Namespace
metadata:
  name: state-machine
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: state
  namespace: state-machine
data:
  demo-wordpress-kubectlk: "demo/"
  state-kubectlf: ".state"

```


