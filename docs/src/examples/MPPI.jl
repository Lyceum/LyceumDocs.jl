#cfg title = "Running a simple controller"
#cfg weight = 10

#md # ## Introduction
# In this example we walk through the process of setting up an experiment
# that runs [Model-Predictive Path Integral Control](https://ieeexplore.ieee.org/iel7/7478842/7487087/07487277.pdf),
# or "MPPI", a Model-Predictive Control method, on a simple PointMass environment.

# First, let's go head and grab all the dependencies
using LinearAlgebra, Random, Statistics # From Stdlib
using LyceumAI # For the MPPI controller
using LyceumMuJoCo # For the PointMass environment
using LyceumBase.Tools # For the ControllerIterator discussed below
using Plots

# **TODO LINK REF**
# Next, we'll define an `Experiment` which we'll use to log the trajectory
# executed by our controller and save the results to "/tmp/pointmass.jlso".
exper = Experiment("/tmp/pointmass.jlso", overwrite = true);

# Then we configure and instantiate of our `PointMass` environment
# and `MPPI` controller. See the documention for `MPPI` to learn more
# about its parameters. **TODO LINK REF**
env = LyceumMuJoCo.PointMass();
mppi = MPPI(
    env_tconstructor = i -> tconstruct(LyceumMuJoCo.PointMass, i),
    covar0 = Diagonal(0.1^2 * I, size(actionspace(env), 1)),
    lambda = 0.01,
    K = 32,
    H = 20,
    gamma = 0.99,
);

# Finally, let's rollout our controller for 300 timesteps.
# As discused in the algorithms section **TODO LINK REF**, `AbstractController`'s are
# by themselves not iterable, so we wrap them in a `ControllerIterator`
# which will apply the controls generated by `MPPI` to the environment
# at each timestep. We'll also plot the progress so far to the terminal
# every 100 timesteps.
#md # For clarity, we do not reproduce these plots here, but you'll
#md # see them when you run this example locally!
iter = ControllerIterator(mppi, env; T = 300, plotiter = 50);
for (t, traj) in iter
end

# Let's go ahead and plot the final reward trajectory and see how we did:
plot(iter.trajectory.rewards)

# and save the results:
for (k, v) in pairs(iter.trajectory)
    exper[k] = v
end
finish!(exper);

using Test #src
@test abs(geteval(env)) < 0.005 #src
