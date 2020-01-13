using LinearAlgebra, Random, Statistics, UnicodePlots, JLSO
using LyceumBase, LyceumAI, LyceumMuJoCo, MuJoCo, UniversalLogger, Shapes
using LyceumBase.Tools
using Shapes: AbstractVectorShape
import LyceumBase: tconstruct
using Plots

struct Humanoid{S} <: AbstractMuJoCoEnvironment
    sim::S
end

Humanoid() = first(tconstruct(Humanoid, 1))
function tconstruct(::Type{Humanoid}, n::Integer)
    modelpath = joinpath(@__DIR__, "humanoid.xml")
    Tuple(Humanoid(s) for s in tconstruct(MJSim, n, modelpath, skip=2))
end;

_getheight(shapedstate::ShapedView, ::Humanoid) = shapedstate.qpos[3]
const LAYING_QPOS=[-0.164158, 0.0265899, 0.101116, 0.684044, -0.160277,
                   -0.70823, -0.0693176, -0.1321, 0.0203937, 0.298099,
                   0.0873523, 0.00634907, 0.117343, -0.0320319, -0.619764,
                   0.0204114, -0.157038, 0.0512385, 0.115817, -0.0320437,
                   -0.617078, -0.00153819, 0.13926, -1.01785, -1.57189,
                   -0.0914509, 0.708539, -1.57187];

LyceumMuJoCo.getsim(env::Humanoid) = env.sim

function LyceumMuJoCo.reset!(env::Humanoid)
    reset!(env.sim)
    env.sim.d.qpos .= LAYING_QPOS
    forward!(env.sim)
    env
end

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

function LyceumMuJoCo.geteval(state, ::Any, ::Any, env::Humanoid)
    return _getheight(statespace(env)(state), env)
end

function hmMPPI(etype=Humanoid; T=200, H=64, K=64)
    env = etype()

    # The following parameters work well for this get-up tasks, and make work for
    # other similar tasks, but is not invariant to the model.
    mppi = MPPI(
                env_tconstructor = i -> tconstruct(etype, i),
                covar0 = Diagonal(0.05^2*I, size(actionspace(env), 1)),
                lambda = 0.4,
                H = H,
                K = K,
                gamma = 1.0
               )

    iter = ControllerIterator(mppi, env; T=T, plotiter=div(T, 10))
    # We can time the following loop; if it ends up less than the time the
    # MuJoCo models integrated forward in, then one could conceivably run this
    # MPPI MPC controller interactively...
    @time for (t, traj) in iter
    end

    savepath = "/tmp/opt_humanoid.jlso"
    exper = Experiment(savepath, overwrite=true)
    exper[:etype] = etype

    for (k, v) in pairs(iter.trajectory)
        exper[k] = v
    end
    finish!(exper)

    return mppi, iter
end

m, d = hmMPPI()

x = JLSO.load("/tmp/opt_humanoid.jlso") # one can load the results as such
plot!(plot(d.trajectory.rewards, label="Inst. Reward", title="Humanoid Standup"),
      d.trajectory.evaluations, label="Evaluation")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

