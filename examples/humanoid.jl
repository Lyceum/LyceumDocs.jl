#cfg title = "Creating a MuJoCo Environment"
#cfg weight = 11
#cfg active = true
#cfg deps = ["humanoid.xml"]

# ## Overview

# Using LyceumMuJoCo, we will create the environment for a Humanoid "get-up" task
# that mostly relies on the defaults of LyceumBase and LyceumMuJoCo to
# propagate state, action, and observation data. We will have to implement reward
# and evaluation functions, of course, along with a few other parts of the
# `AbstractEnvironment` interface.

# We then solve the "get-up" task using a Model-Predictive Control method called
# ["Model Predictive Path Integral Control"](https://ieeexplore.ieee.org/iel7/7478842/7487087/07487277.pdf)
# or MPPI, walking through how to log experiment data and plot the results.

# ## The Code

# First we grab our dependencies of the Lyceum ecosystem and other helpful packages.
using LinearAlgebra, Random, Statistics
using Plots, UnicodePlots, JLSO
using LyceumBase, LyceumBase.Tools, LyceumAI, LyceumMuJoCo, MuJoCo, UniversalLogger, Shapes


#md # ### Humanoid Type

# This struct is our primary entry into the environment API. Environments utilizing
# the MuJoCo simulator through LyceumMuJoCo should subtype
# `AbstractMuJoCoEnvironment <: AbstractEnvironment`. As you can see, this simple
# example only wraps around the underlying simulator (the `sim::MJSim` field of `Humanoid`,
# referred to hereafter as just `sim`). The functions of the LyceumBase API will then
# dispatch on this struct through Julia's [multiple dispatch](https://en.wikipedia.org/wiki/Multiple_dispatch)
# mechanism. When an algorithm calls a function such as `getobs!(obs, env)`, Julia will select from
# all functions with that name depending on `typeof(obs)` and `typeof(env)`.
struct Humanoid{S<:MJSim} <: AbstractMuJoCoEnvironment
    sim::S
end

LyceumMuJoCo.getsim(env::Humanoid) = env.sim #src (needs to be here for below example to work)

# `Humanoid` (and all subtypes of `AbstractEnvironment`) are designed to be used in a single
# threaded context. To use `Humanoid` in a multi-threaded context, one could simply create
# `Threads.nthreads()` instances of `Humanoid`:
modelpath = joinpath(@__DIR__, "humanoid.xml")
envs = [Humanoid(MJSim(modelpath, skip = 2)) for i = 1:Threads.nthreads()]
Threads.@threads for i = 1:Threads.nthreads()
    thread_env = envs[Threads.threadid()]
    step!(thread_env)
end

# As `Humanoid` only ever uses its internal `jlModel` (found at `sim.m`) in a read-only
# fashion, we can make a performance optimization by sharing a single instance of `jlModel`
# across each thread, resulting in improved cache efficiency. `LyceumMuJoCo.tconstruct`,
# short for "thread construct", helps us to do just that by providing a common interface
# for defining "thread-aware" constructors. Below, we make a call to
# `tconstruct(MJSim, n, modelpath, skip = 2)` which will construct `n` instances of `MJSim`
# constructed from `modelpath` and with a `skip` of 2, all sharing the exact same `jlModel`
# instance, and return `n` instances of `Humanoid`. All of the environments provided by
# LyceumMuJoCo feature similar definitions of `tconstruct` as found below.
Humanoid() = first(tconstruct(Humanoid, 1))
function LyceumMuJoCo.tconstruct(::Type{Humanoid}, n::Integer)
    modelpath = joinpath(@__DIR__, "humanoid.xml")
    return Tuple(Humanoid(s) for s in tconstruct(MJSim, n, modelpath, skip = 2))
end

# We can then use `tconstruct` as follows:
envs = tconstruct(Humanoid, Threads.nthreads())
Threads.@threads for i = 1:Threads.nthreads()
    thread_env = envs[Threads.threadid()]
    step!(thread_env)
end


#md # ### Utilities

# The following are helpers for the "get-up" task we'd like to consider.
# We want the humanoid to stand up, thus we need to grab the model's height, as
# well as record a laying down position that we can use to set the state to.
# By exploring the model in the REPL or MJCF/XML file we can see that `sim.d.qpos[3]`
# is the index for the z-axis (height) of the root joint. The `LAYING_QPOS` data was
# collected externally by posing the model into a supine pose; one can either use
# LyceumMuJoCoViz or simulate.cpp included with a MuJoCo release to do this.
_getheight(shapedstate::ShapedView, ::Humanoid) = shapedstate.qpos[3]
const LAYING_QPOS = [
    -0.164158,
    0.0265899,
    0.101116,
    0.684044,
    -0.160277,
    -0.70823,
    -0.0693176,
    -0.1321,
    0.0203937,
    0.298099,
    0.0873523,
    0.00634907,
    0.117343,
    -0.0320319,
    -0.619764,
    0.0204114,
    -0.157038,
    0.0512385,
    0.115817,
    -0.0320437,
    -0.617078,
    -0.00153819,
    0.13926,
    -1.01785,
    -1.57189,
    -0.0914509,
    0.708539,
    -1.57187,
];

#md # ### The `AbstractMuJoCoEnvironment` and `AbstractEnvironment` APIs

# LyceumMuJoCo requires access to the underlying `MJSim` simulator, thus any LyceumMuJoCo
# environments need to point to the correct field in the environment struct that is the
# simulator; in our case there's only one field: `sim`.
LyceumMuJoCo.getsim(env::Humanoid) = env.sim

# Normally we could rely on MuJoCo to reset the model to the default configuration when the
# model XML is loaded; the humanoid.xml model, however, defaults to a vertical pose. To
# reset the model to our laying down or supine pose, we can copy in the data from
# `LAYING_QPOS` above to `d.qpos`. Calling `forward!` here is the same as
# `mj_forward(env.sim.m, env.sim.d)`, for a pure MuJoCo reference.
function LyceumMuJoCo.reset!(env::Humanoid)
    reset!(env.sim)
    env.sim.d.qpos .= LAYING_QPOS
    forward!(env.sim)
    return env
end

# This reward function uses the `_getheight` helper function above to get the model's
# height when the function is called. We also specify a target height of 1.25 and
# penalize the agent for deviating from the target height. There is also a small penalty
# for using large control activations; if the coefficient is made larger, the agent
# may not move at all!
function LyceumMuJoCo.getreward(state, action, obs, env::Humanoid)
    height = _getheight(statespace(env)(state), env)
    target = 1.25
    reward = 1.0
    if height < target
        reward -= 2.0 * abs(target - height)
    end
    reward -= 1e-3 * norm(action)^2

    return reward
end

# Finally, we can specify an evaluation function. The difference between `geteval` and
# `getreward` is that `getreward` is the shaped reward our algorithm is optimizing for,
# while `geteval` lets us track a useful value for monitoring performance, such as height.
# Plotting this eval function will show the agent's height over time and is very useful
# for reviewing actual desired behavior, regardless of the reward achieved, as it can be
# used to diagnose reward specification problems.
function LyceumMuJoCo.geteval(state, action, obs, env::Humanoid)
    return _getheight(statespace(env)(state), env)
end

#md # ### Running Experiments

# As discussed in the [Julia performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/),
# globals can hinder performance. To avoid this, we construct the `MPPI` and
# `ControllerIterator` instances within a function. This also lets us easily run our
# experiment with different choices of parameters (e.g. `H`). Like most algorithms in
# `LyceumAI`, `MPPI` accepts a "thread-aware" environment constructor as well as any
# algorithm parameters. In this case, we just pass a closure around the `tconstruct`
# function we defined above. `MPPI`, being a single-step algorithm, is itself not iterable,
# so we wrap it in a `ControllerIterator` which simply calls the passed-in function
# `ctrlfn` for `T` timesteps, while simultaneously plotting and logging the trajectory rollout.
function humanoid_MPPI(etype = Humanoid; T = 200, H = 64, K = 64)
    env = etype()

    ## The following parameters work well for this get-up task, and may work for
    ## similar tasks, but are not invariant to the model.
    mppi = MPPI(
        env_tconstructor = n -> tconstruct(etype, n),
        covar = Diagonal(0.05^2 * I, size(actionspace(env), 1)),
        lambda = 0.4,
        H = H,
        K = K,
        gamma = 1.0,
    )

    ctrlfn = (action, state, obs) -> getaction!(action, state, mppi)
    iter = ControllerIterator(ctrlfn, env; T = T, plotiter = div(T, 10))

    ## We can time the following loop; if it ends up less than the time the
    ## MuJoCo models integrated forward in, then one could conceivably run this
    ## MPPI MPC controller interactively...
    elapsed = @elapsed for (t, traj) in iter
        ## If desired, one can inspect `traj`, `env`, or `mppi` at each timestep.
    end

    if elapsed < time(env)
        @info "We ran in real time!"
    end

    ## Save our experiment results to a file for later review.
    savepath = "/tmp/opt_humanoid.jlso"
    exper = Experiment(savepath, overwrite = true)
    exper[:etype] = etype

    for (k, v) in pairs(iter.trajectory)
        exper[k] = v
    end
    finish!(exper)

    return mppi, env, iter.trajectory
end


#md # ### Checking Results

seed_threadrngs!(1) #src

# The MPPI algorithm, and any that you develop, can and should use plotting tools
# to track progress as they go.
mppi, env, traj = humanoid_MPPI();
plot(
    [traj.rewards traj.evaluations],
    labels = ["Reward" "Evaluation"],
    title = "Humanoid Standup",
    legend = :bottomright,
)

# If one wanted to review the results after training, or prepare plots for presentations,
# one can load the data from disk instead.
data = JLSO.load("/tmp/opt_humanoid.jlso")
plot(
    [data["rewards"] data["evaluations"]],
    labels = ["Reward" "Evaluation"],
    title = "Humanoid Standup",
    legend = :bottomright,
)

using Test #src
@test abs(geteval(env)) > 1.2 #src
@test data["rewards"] == traj.rewards #src
