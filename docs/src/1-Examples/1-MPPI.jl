using LinearAlgebra, Random, Statistics

using LyceumBase, LyceumAI, LyceumMuJoCo, UniversalLogger
using LyceumBase.Tools
using Plots


# ### Setup
env = LyceumMuJoCo.PointMass()
T = 1000
K = 32
H = 25


# ### Logging
exper = Experiment("/tmp/pointmass.jlso", overwrite=true)
lg = ULogger()

# ### MPPI
mppi = MPPI(
    sharedmemory_envctor = (i)->sharedmemory_envs(LyceumMuJoCo.PointMass, i),
    covar0 = Diagonal(0.001^2*I, size(actionspace(env), 1)),
    lambda = 0.005,
    K =  K,
    H = H,
    gamma = 0.99
)

# ### Run
iter = ControllerIterator(mppi, env; T=T, plotiter=100)
for (t, traj) in iter
end

# ### Plot results

#plot(iter.trajectory.rewards)


# # Save results
for (k, v) in pairs(iter.trajectory)
    exper[k] = v
end
finish!(exper)

using Test #src
@test abs(geteval(env)) < 0.001 #src