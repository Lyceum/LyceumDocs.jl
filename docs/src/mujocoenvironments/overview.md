# Overview

```@meta
CurrentModule = LyceumMuJoCo
```

LyceumMuJoCo uses [MuJoCo.jl](https://github.com/Lyceum/MuJoCo.jl) to provide the following:

* MuJoCo-based environments that implement the [`AbstractEnvironment`]
    (@ref LyceumBase.AbstractEnvironment) interface.
* The `MJSim` type and related utilities for combining a `jlModel` and `jlData` from
    MuJoCo.jl to provide a full simulation.

Note that to use MuJoCo, you'll need a valid license which you can obtain from
[here](https://www.roboti.us/license.html). Up to three thirty-day trials can be obtained
for free from MuJoCo's webiste, while students are eligible for a free personal license.
Once you have obtained the license file, set the environment variable `MUJOCO_KEY_PATH`
to point to its location. On Linux machines this would look like:
```
$ export MUJOCO_KEY_PATH=/path/to/mjkey.txt
```

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
observationspace(::MJSim)
getobservation!(::RealVec, ::MJSim)
getobservation(::MJSim)
zeroctrl!(::MJSim)
zerofullctrl!(::MJSim)
forward!(::MJSim)
timestep(::MJSim)
time(::MJSim)
```
