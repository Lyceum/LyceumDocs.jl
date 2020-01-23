```@cfg
title = "LyceumMuJoCo"
weight = 0
```

```@meta
CurrentModule = LyceumDocs.LyceumMuJoCo
```

LyceumMuJoCo uses [MuJoCo.jl](https://github.com/Lyceum/MuJoCo.jl) to provide the following:

* MuJoCo-based environments that implement the [`AbstractEnvironment`]
    (@ref LyceumBase.AbstractEnvironment) interface.
* The `MJSim` type and related utilities for combining a `jlModel` and `jlData` from
    MuJoCo.jl to provide a full simulation.


## AbstractMuJoCoEnvironment

To create a new MuJoCo-based environment, you will need to:

1. Define a type `Env` that subtypes [`AbstractMuJoCoEnvironment <: LyceumBase.AbstractEnvironment`](@ref AbstractMuJoCoEnvironment).
2. Implement the [`AbstractEnvironment`](@ref) interface.
3. Additionally, implement the method [`getsim(env::Env) --> MJSim`](@ref getsim) that
    returns the underlying `MJSim` which is used to provide defaults and other features.

```@docs
AbstractMuJoCoEnvironment
getsim
```

## MJSim

```@docs
MJSim
setstate!(::MJSim, ::RealVec)
getstate!(::RealVec, ::MJSim)
obsspace(::MJSim)
getobs!(::RealVec, ::MJSim)
getobs(::MJSim)
zeroctrl!(::MJSim)
zerofullctrl!(::MJSim)
forward!(::MJSim)
timestep(::MJSim)
time(::MJSim)
```