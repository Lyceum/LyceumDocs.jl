```@cfg
title = "AbstractEnvironment"
weight = 10
```

```@meta
CurrentModule = LyceumDocs.LyceumBase
```

## Overview

What follows is the `AbstractEnvironment` interface in its entirety. For users implementing
new environments, only a subset of the methods discussed below are required. The remaining
methods are built off of that subset and should not be implemented directly. Some of the
required methods may have defaults.

**Required Methods**

* State
  * `statespace(env)`
  * `getstate!(state, env)`
  * `setstate!(env, state)`
* Observation
  * `obsspace(env)`
  * `getobs!(obs, env)`
* Action
  * `actionspace(env)`
  * `getaction!(action, env)`
  * `setaction!(env, action)`
* Reward
  * `rewardspace(env)`
  * `getreward(env)`
* Evaluation
  * `evalspace(env)`
  * `geteval(env)`
* Simulation
  * `reset!(env)`
  * `randreset!(env)`
  * `step!(env)`
  * `isdone(env)`
  * `timestep(env)`
  * `Base.time(env)`


## API

```@docs
AbstractEnvironment
```

### State

```@docs
statespace
getstate!
setstate!
getstate
```

### Observation

```@docs
obsspace
getobs!
getobs
```

### Action

```@docs
actionspace
getaction!
setaction!
getaction
```

### Reward

```@docs
rewardspace
getreward
```

### Evaluation

```@docs
evalspace
geteval
```

### Simulation

```@docs
reset!
randreset!
step!
isdone
timestep
Base.time
```