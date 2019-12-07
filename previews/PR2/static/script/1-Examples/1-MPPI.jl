using LinearAlgebra, Random, Statistics

using LyceumBase, LyceumAI, LyceumMuJoCo, UniversalLogger
using LyceumBase.Tools
using Plots

env = LyceumMuJoCo.PointMass()
T = 1000
K = 32
H = 25

exper = Experiment("/tmp/pointmass.jlso", overwrite=true)
lg = ULogger()

mppi = MPPI(
    sharedmemory_envctor = (i)->sharedmemory_envs(LyceumMuJoCo.PointMass, i),
    covar0 = Diagonal(0.001^2*I, size(actionspace(env), 1)),
    lambda = 0.005,
    K =  K,
    H = H,
    gamma = 0.99
)

iter = ControllerIterator(mppi, env; T=T, plotiter=100)
for (t, traj) in iter
end

#plot(iter.trajectory.rewards)

for (k, v) in pairs(iter.trajectory)
    exper[k] = v
end
finish!(exper)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

