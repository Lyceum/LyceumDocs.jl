#cfg title = "Creating a MuJoCo Environment"
#cfg weight = 13


# Using Mujoco, we can create an environment that mostly relies on the defaults of
# LyceumBase and LyceumMuJoCo to propagate state, action, and observation data.
# We will have to include a reward and evaluation function, of course, and also show
# how the functions can be customized for different tasks.


# First we grab our dependencies of the Lyceum ecosystem and other helpful packages
using LinearAlgebra, Random, Statistics, UnicodePlots, JLSO
using LyceumBase, LyceumAI, LyceumMuJoCo, MuJoCo, UniversalLogger, Shapes
using LyceumBase.Tools
using Shapes: AbstractVectorShape
import LyceumBase: tconstruct


#md # ## Humanoid Type
# This struct is our primary entry into the environment API. As you can see, this simple
# example only wraps around the underlying simulator. The functions of the LyceumBase
# API will dispatch on this struct. When an algorithm calls a function such as `getobs!`,
# Julia will select from all functions with that name depending on the _type_ of environment
# that is passed in.
struct Humanoid{S} <: AbstractMuJoCoEnvironment
    sim::S
end

# The following lines facilliatate construction of the simulation such that multi-threading
# performance is enabled; we will construct multiple instances of MuJoCo mjData structures
# which at run time will share the same mjModel struct. Primarily, this points to the xml
# file and how many mujoco timesteps to skip when doing steps at the environment level.
Humanoid() = first(tconstruct(Humanoid, 1))
function tconstruct(::Type{Humanoid}, n::Integer)
    modelpath = joinpath(@__DIR__, "humanoid.xml")
    Tuple(Humanoid(s) for s in tconstruct(MJSim, n, modelpath, skip=4))
end;


#md # ## Customizing
# The following are helpers for the tasks we'd like to consider. We want the humanoid
# to stand up, thus we need to grab the model's height, as well as record a laying down
# position that we can use to set the state to. By exploring the model in the REPL or xml
# we can see that qpos[3] is the index for the z-axis (height) of the root joint.
# The LAYING_QPOS data was collected externally by posing the model into a supine pose;
# one can use `simulate.cpp` included with a MuJoCo release to do this, if desired, or
# use LyceumMuJoCoViz as well.
_getheight(shapedstate::ShapedView, ::Humanoid) = shapedstate.qpos[3]
const LAYING_QPOS=[-0.164158, 0.0265899, 0.101116, 0.684044, -0.160277,
                   -0.70823, -0.0693176, -0.1321, 0.0203937, 0.298099,
                   0.0873523, 0.00634907, 0.117343, -0.0320319, -0.619764,
                   0.0204114, -0.157038, 0.0512385, 0.115817, -0.0320437,
                   -0.617078, -0.00153819, 0.13926, -1.01785, -1.57189,
                   -0.0914509, 0.708539, -1.57187];

#md # ## Lyceum API Simple Setup
# LyceumBase requires access to the underlying simulator, thus any LyceumMuJoCo environments
# need to point to the correct field in the env struct that is the simulator; in our case here
# there's only one field.
LyceumMuJoCo.getsim(env::Humanoid) = env.sim

# Normally we could rely on MuJoCo to reset the model to the default configuration when the 
# model XML is loaded; in humanoid.xml's case, it is in a vertical position. To reset the model
# to our laying down or supine pose, we can copy in the data from the const array above to `d.qpos`.
# Calling `forward!` here is the same as `mj_forward(m,d)`, for a pure MuJoCo reference.
function LyceumMuJoCo.reset!(env::Humanoid)
    reset!(env.sim)
    env.sim.d.qpos .= LAYING_QPOS
    forward!(env.sim)
    env
end


# This reward function uses the `_getheight` helper function above to get the model's height
# when the function is called. We also specify a target height of 1.25, and penalize the agent
# for deviating from the target height. There is also a small penalty for using large control
# activations; if the coefficient is made larger, the agent may not move at all!
function LyceumMuJoCo.getreward(state, action, obs, env::Humanoid)
    height = _getheight(statespace(env)(state), env)
    target = 1.25

    reward = 1.0
    if height < target
        reward -= 2.0*abs(target - height)
    end

    reward -= 1e-3*norm(action)^2

    return reward
end

# Finally, we can specify an evaluation function. The difference between the eval and reward
# functions are that we can track a useful value, such as height with `geteval`, but an algorithm
# like MPPI or NPG may need a shaped function to guide any optimization. Plotting this eval function
# will show the agent's height over time: this is very useful for reviewing actual desired behavior 
# regardless of the reward achieved, as it can be used to diagnose reward specification problems.
# The function signature isn't typed to allow for flexibility with algorithms. In this case,
# because we know what data we will extract, we can specify that there are two `Any` type inputs
# that are not labelled just to match the function signature.
function LyceumMuJoCo.geteval(state, ::Any, ::Any, env::Humanoid) 
    return _getheight(statespace(env)(state), env)
end

#md # ## Running Experiments
# Julia performs better when functions are well scoped. Here we construct the MPPI and
# ControllerIterator objects within a function so they are not global. The MPPI struct
# accepts an environment constructor and algorithm parameters, and runs the controller.
# Putting the algorithm in a function allows a user to quickly iterate through parameter
# searching, or using packages such as `Revise` can seemlessly allow for reloading of
# algorithms in development.
function hmMPPI(etype=Humanoid; T=100, H=32, K=32)
    env = etype()

    ## The following parameters work well for this get-up tasks, and make work for
    ## other similar tasks, but is not invariant to the model.
    mppi = MPPI(
                env_tconstructor = i -> tconstruct(etype, i),
                covar0 = Diagonal(0.2^2*I, size(actionspace(env), 1)),
                lambda = 0.8,
                H = H,
                K = K,
                gamma = 1.0
               )

    iter = ControllerIterator(mppi, env; T=T, plotiter=div(T, 10))
    ## We can time the following loop; if it ends up less than the time the
    ## MuJoCo models integrated forward in, then one could conceivably run this
    ## MPPI MPC controller interactively...
    @time for (t, traj) in iter
    end

    savepath = "/tmp/opt_humanoid.jlso"
    exper = Experiment(savepath, overwrite=true)
    exper[:etype] = etype

    for (k, v) in pairs(iter.trajectory)
        exper[k] = v
    end
    finish!(exper)

    return mppi, savepath
end

m, p = hmMPPI()

#md # ## Checking Results
# The MPPI algorithm, and any that you develop, can and should use plotting tools
# to track progress as they go. IF one wanted to review the results after training,
# or prepare plots for presentations, one can load the data from disk instead.
using Plots
x = JLSO.load(p)
plot!(plot(x["rewards"], label="Inst. Reward", title="Humanoid Standup"),
      x["evaluations"], label="Evaluation")
