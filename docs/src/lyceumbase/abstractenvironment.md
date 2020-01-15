```@cfg
title = AbstractEnvironment
weight = 10
```

```@meta
CurrentModule = LyceumDocs.LyceumBase
```

What follows is the `AbstractEnvironment` interface in its entirety. The methods comprising this interface can be divided. The remainder are built upon the required
methods and thus do not need to be implemented for each subtype of `AbstractEnvironment`.

| Required methods               |                        | Brief description                                                                     |
|:------------------------------ |:---------------------- |:------------------------------------------------------------------------------------- |
| `iterate(iter)`                |                        | Returns either a tuple of the first item and initial state or [`nothing`](@ref) if empty        |

```@docs
AbstractEnvironment

statespace
getstate!
setstate!
getstate

obsspace
getobs!
getobs

actionspace
getaction!
setaction!
getaction

rewardspace
getreward

evalspace
geteval

reset!
randreset!
step!
isdone
timestep
Base.time
spaces
```

```@eval
error(@__MODULE__)
```