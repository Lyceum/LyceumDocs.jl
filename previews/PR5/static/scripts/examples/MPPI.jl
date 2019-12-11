!!! note "Running examples locally"
    This example and more are also available as Julia scripts and Jupyter notebooks.

    See [the how-to page](example_howto.md) for more information.

# Running a simple controller

using LinearAlgebra, Random, Statistics # From Stdlib
using LyceumAI # For the MPPI controller
using LyceumMuJoCo # For the PointMass environment
using LyceumBase.Tools # For the ControllerIterator discussed below
using Plots

exper = Experiment("/tmp/pointmass.jlso", overwrite=true);

env = LyceumMuJoCo.PointMass();
mppi = MPPI(
    sharedmemory_envctor = (i)->sharedmemory_envs(LyceumMuJoCo.PointMass, i),
    covar0 = Diagonal(0.001^2*I, size(actionspace(env), 1)),
    lambda = 0.005,
    K =  32,
    H = 25,
    gamma = 0.99
);

iter = ControllerIterator(mppi, env; T=1000, plotiter=100);
for (t, traj) in iter
end

plot(iter.trajectory.rewards)

for (k, v) in pairs(iter.trajectory)
    exper[k] = v
end
finish!(exper);

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

