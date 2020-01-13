using LinearAlgebra, Random, Statistics # From Stdlib
using LyceumAI # For the MPPI controller
using LyceumMuJoCo # For the PointMass environment
using LyceumBase.Tools # For the ControllerIterator discussed below
using Plots

exper = Experiment("/tmp/pointmass.jlso", overwrite = true);

env = LyceumMuJoCo.PointMass();
mppi = MPPI(
    env_tconstructor = i -> tconstruct(LyceumMuJoCo.PointMass, i),
    covar0 = Diagonal(0.1^2 * I, size(actionspace(env), 1)),
    lambda = 0.01,
    K = 32,
    H = 10,
    gamma = 0.99,
);

iter = ControllerIterator(mppi, env; T = 300, plotiter = 50);
for (t, traj) in iter
end

plot(iter.trajectory.rewards)

for (k, v) in pairs(iter.trajectory)
    exper[k] = v
end
finish!(exper);

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

