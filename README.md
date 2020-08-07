# Dictum State Machine
## Introduction
The Dictum State Machine (DSM) is a framework and extensible program for managing declarative configurations of a defined environment. 

The DSM is intended to apply any declarative configurations, such as kubernetes (kubectl/kustomize/helm), terraform, and ansible in a user defined sequence with health checking and resource checking between each applied template.

DSM reads a Kubernetes ConfigMap and conditionally performs apply or delete operations with declarative configurations. Between apply operations, the DSM can execute scripts to perform health checking and resource availability.

Though preferred, Kubernetes is not required for the DSM to run. The DSM can be run remotely from an admin computer or from within a Kubernetes cluster as an Operator.

## Components
### - Environment Definition:  
An initialized workspace organized with adherence to modular design and code reuse principals. Uses git submodules to import common or generalized components that are applied by theDSM.
### - State Machine:  
A program that reads an Environment Definition and applies the defined configuration. The DSM combines the sequential application of declarative configuration patterns with imperative task execution for things like health checking and secrets management.
### - Resources: 
Any files that are referenced by the DSM while applying the defined state of the environment. Resources must adhere to certain design patterns when being called in the execution ofDSM tasks.

## Process
When the DSM is run, it first locates the `.state` file in the workspace root and attempts to retrieve an existing state ConfigMap with the current kubectl context. If an existing State is found, the existing state is compared to the incoming state. Resources present in the existing state that are missing from the incoming state are deleted from the environment. If no existing state is found, the incoming state is then applied to the environment. Resources in the incoming state are applied sequentially (from top to bottom). Resources are listed in `.state` as key/value pairs with the following syntax: `name-descriptor-res_type: file/path/to/resource`

**Note:** For now, the name and descriptor of the key are mostly arbitrary and used for the administrator to identify resources, but if the key changes, the resource will be deleted from the environment before being applied by the DSM.  

The res_type identifies the executor with which the resource will be managed.  For example, the DSM processing `nexus-deployment-kubectlk: nexus/nexus-deploy/` would result in either `kubectl apply -k /literal/path/nexus/nexus-deploy/` or `kubectl delete -k /literal/path/nexus/nexus-deploy/`

Every environment must be managed by an order of operations. Resources will inevitably rely on dependencies. TheDSM addresses an Environment's order of operations by applying configurations sequentially, but this is not enough for complex environment provisioning, management, and updating. TheDSM also executes process helpers between resource application that allow administrators to dynamically configure things like health checking and resource availability checks. This enables theDSM to pause, wait, or fail between configuration applications as needed.

## Getting Started

Prereq1: you will need an empty git repo.  
Prereq2: Read requirements.txt for a list of application dependencies.  
Prereq3: Have an available kubernetes cluster in your default kubectl context.

1. At the root of the git repo, create a file called `.state`.
2. Add the DSM repo as a git submodule within your current repo: `git submodule add https://github.com/Dictum-SM/state.git state`  
3. Copy and paste the following ConfigMap into `.state`:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: state
  namespace: state-machine
data:
  hello-deployment-kubectlf: "state/resources/demo-hello.yaml"
  state-ns-kubectlf: "state/resources/state-ns.yaml"
  state-kubectlf: ".state"

```
4. Start the DSM with  `./state.sh`
5. Check for deployment in default NS  
Notice that aside from the Hello World deployment, the DSM has stored its state in the cluster under the state-machine NS.
6. Edit the `.state` file again, and delete the entire hello-deployment key/value pair line.
7. Re-run the DSM and notice that the Hello World deployment is terminating or has already been deleted.

## Extensibility
The DSM can use any declarative resource if the resource can be invoked to perform binary operations. For example, a key/valude pair of `  hello-deployment-kubectlf: "resources/demo-hello.yaml"` would be either applied or deleted with `kubectl -f`. 

The DSM is expected to handle additional resource types beyond the Alpha1 defaults. Additional resource types include, but are not limited to Terraform and Ansible. 

There are two criteria for extending the DSM resource types:  
1. An apply and delete function must be written for each resource type and must be invoked by the same name.
2. Each function must be accompanied by an associative array entry for its corresponding action type (apply or delete)  

Take a look at the lib/apply and lib/delete libraries to see how the functions are indexed by the DSM
### Alpha1 Defaults
kubectlf: kubectl <apply/delete> -f  
kubectlk: kubectl <apply/delete> -k   
kbuild: kustomize build | kubectl <apply/delete> -f -  
bash: Executes the referenced script verbatim. **Note** This is a special resource type that does not have a corresponding delete, because a script cannot be considered reliably declarative and is difficult to call to perform an inverse operation from what it was set to do.

## How to use scripts between declarations
Scripts can be called, such as in bash, to provide imperative operations that help the DSM to successfully deploy an environment. There are two intended use cases for scripts:  
1. Check for liveness/health/resource availability before applying a declarative configuration.  
2. Unlock credentials used to manage declarative resources such as access tokens stored in ansible-vault.  

Do not use scripts to deploy configurations or manage any aspect of an environment because they can not be undone by invoking binary operations used by the DSM.

## Misc
For Ansible each resource must be written in a playbook with two plays that can be called by a common delete and apply variable. Therefore, every playbook should be written to execute one of two plays with a common agreed upon variable where one play performs an apply operation and the second play performs the inverse operation that will completely revert the changes of the apply play.
