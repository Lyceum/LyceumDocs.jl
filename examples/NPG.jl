#cfg title = "Learning a Control Policy"
#cfg weight = 12
#cfg active = true

#md # ## Overview

# In this example we walk through the process of setting up an experiment
# that runs [Natural Policy Gradient](https://papers.nips.cc/paper/2073-a-natural-policy-gradient.pdf)
# (or more recently [in this work](https://arxiv.org/pdf/1703.02660.pdf)).
# This is an on-policy reinforcement learning method that is comparable to TRPO,
# PPO, and other policy gradient methods. See the documentation for `NaturalPolicyGradient`
# for full implementation details.


#md # ## The Code

# First, let's go head and grab all the dependencies:
using LinearAlgebra, Random, Statistics # From Stdlib
using LyceumAI                          # For the NPG controller
using LyceumMuJoCo                      # For the Hopper environment
using Flux                              # For our neural networks needs
using UniversalLogger                   # For logging experiment data
using Plots                             # For plotting the results
using LyceumBase.Tools                  # Miscellaneous utilities

# We first instantiate a `HopperV2` environment to grab useful
# environment-specific values, such as the size of the observation and action vectors:
env = LyceumMuJoCo.HopperV2();
dobs, dact = length(obsspace(env)), length(actionspace(env));

# We'll also seed the per-thread global RNGs:
seed_threadrngs!(1)


#md # ### Policy Gradient Components

# Policy Gradient methods require a policy: a function that takes in the state/observations
# of the agent, and outputs an action i.e. `action = π(obs)`. In much of Deep RL, the
# policy takes the form of a neural network which can be built on top of the
# [Flux.jl](https://github.com/FluxML/Flux.jl) library. We utilize a stochastic policy in
# this example. Specifically, our policy is represented as a multivariate Gaussian
# distribution of the form:
# ```math
# \pi(a | o) = \mathcal{N}(\mu_{\theta_1}(o), \Sigma_{\theta_2})
# ```
# where ``\mu_{\theta_1}`` is a neural network, parameterized by ``\theta_1``, that maps
# an observation to a mean action and ``\Sigma_{\theta_2}`` is a diagonal
# covariance matrix parameterized by ``\theta_2``, the diagonal entries of the matrix.
# For ``\mu_{\theta_1}`` we utilize a 2-layer neural network, where each layer has a "width"
# of 32. We use tanh activations for each hidden layer and initialize the network weights
# with Glorot Uniform initializations. Rather than tracking ``\Sigma_{\theta_2}`` directly,
# we track the log standard deviations, which are easier to learn. We initialize
# ``\log \text{diag}(\Sigma_{\theta_2})`` as `zeros(dact)`, i.e. a `Vector` of length `dact`,
# initialized to 0. Both ``\theta_1`` and ``\theta_2`` are learned in this example.
# Note that ``\mu_{\theta_1}`` is a _state-dependent_ mean while ``\Sigma_{\theta_2}``
# is a _global_ covariance.
const policy = DiagGaussianPolicy(
    multilayer_perceptron(
        dobs,
        32,
        32,
        dact;
        σ = tanh,
        initb = Flux.glorot_uniform,
        initb_final = Flux.glorot_uniform,
        dtype = Float32,
    ),
    zeros(Float32, dact),
);

# This NPG implementation uses [Generalized Advantaged Estimation](https://arxiv.org/pdf/1506.02438.pdf),
# which requires an estimate of the value function, `value(state)`, which we
# represent using a 2-layer, feedforward neural network where each layer has a width of
# 128 and uses the ReLU activation function. The model weights are initialized using
# Glorot Uniform initialization as above.
const value = multilayer_perceptron(
    dobs,
    128,
    128,
    1;
    σ = Flux.relu,
    initb = Flux.glorot_uniform,
    initb_final = Flux.glorot_uniform,
    dtype = Float32,
);

# Next, we set up the optimization pipeline for `value`. We use a mini-batch size of 64
# and the [ADAM](https://arxiv.org/pdf/1412.6980.pdf) optimizer. `FluxTrainer` is an
# iterator that loops on the model provided, performing a single step of gradient
# descent at each iteration. The result at each loop is passed to `stopcb` below, so you
# can quit after a number of epochs, convergence, or other criteria; here it's capped at
# two epochs. See the documentation for `FluxTrainer` for more information.
valueloss(bl, X, Y) = Flux.mse(vec(bl(X)), vec(Y))
stopcb(x) = x.nepochs > 2
const valuetrainer = FluxTrainer(
    optimiser = ADAM(1e-3),
    szbatch = 64,
    lossfn = valueloss,
    stopcb = stopcb
);

# The `NaturalPolicyGradient` iterator is a type that pre-allocates all necesary
# data structures and performs one gradient update to `policy` at each iteration.
# We first pass in a constructor that given `n` returns `n` instances of
# `LyceumMuJoCo.HopperV2`, all sharing the same `jlModel`, to allow `NaturalPolicyGradient`
# to allocate per-thread environments and enable performant, parallel sampling from
# `policy`. We then pass in the `policy`, `value`, and `valuetrainer` instances
# constructed above and override a few of the default `NaturalPolicyGradient` parameters:
# `gamma`, `gaelambda`, and `norm_step_size`. Finally, we set the max trajectory length
# `Hmax` and total number of samples per iteration, `N`. Under the hood,
# `NaturalPolicyGradient` will use approximately `div(N, Hmax)` threads to perform the
# sampling.
const npg = NaturalPolicyGradient(
    n -> tconstruct(LyceumMuJoCo.HopperV2, n),
    policy,
    value,
    valuetrainer;
    gamma = 0.995,
    gaelambda = 0.97,
    norm_step_size = 0.05,
    Hmax = 1000,
    N = 10240,
);


#md # ### Running Experiments

# Finally, let's spin on our iterator 200 times, plotting every 20 iterations.
# This lets us break out of the loop if certain conditions are met, or re-start training
# manually if needed. We of course wish to track results, so we create a `ULogger` and
# `Experiment` to which we can save data. We also have useful timing information displayed
# every 20 iterations to better understand the performance of our algorithm and identify
# any potential bottlenecks. Rather than iterating on `npg` at the global scope, we'll
# do it inside of a function to avoid the performance issues associated with global
# variables as discussed in the
# [Julia performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/).
# Note, to keep the Markdown version of this tutorial readable, we skip the plots
# and performance statistics. To enable them, simply call `hopper_NPG(npg, true)`.
function hopper_NPG(npg::NaturalPolicyGradient, plot::Bool)
    exper = Experiment("/tmp/hopper_example.jlso", overwrite = true)
    ## Walks, talks, and acts like a Julia logger. See the UniversalLogger.jl docs for more info.
    lg = ULogger()
    for (i, state) in enumerate(npg)
        if i > 200
            ## serialize some stuff and quit
            exper[:policy] = npg.policy
            exper[:value] = npg.value
            exper[:etype] = LyceumMuJoCo.HopperV2
            exper[:meanstates] = state.meanbatch
            exper[:stocstates] = state.stocbatch
            break
        end

        ## log everything in `state` except meanbatch and stocbatch
        push!(lg, :algstate, filter_nt(state, exclude = (:meanbatch, :stocbatch)))

        if plot && mod(i, 20) == 0
            x = lg[:algstate]
            ## The following are helper functions for plotting to the terminal.
            ## The first plot displays the `geteval` function for our stochastic
            ## and mean policy rollouts.
            display(expplot(
                Line(x[:stocterminal_eval], "StocLastE"),
                Line(x[:meanterminal_eval], "MeanLastE"),
                title = "Evaluation Score, Iter=$i",
                width = 60,
                height = 8,
            ))
            ## While the second one similarly plots `getreward`.
            display(expplot(
                Line(x[:stoctraj_reward], "StocR"),
                Line(x[:meantraj_reward], "MeanR"),
                title = "Reward, Iter=$i",
                width = 60,
                height = 8,
            ))

            ## The following are timing values for various parts of the Natural Policy Gradient
            ## algorithm at the last iteration, useful for finding performance bottlenecks
            ## in the algorithm.
            println("elapsed_sampled  = ", state.elapsed_sampled)
            println("elapsed_gradll   = ", state.elapsed_gradll)
            println("elapsed_vpg      = ", state.elapsed_vpg)
            println("elapsed_cg       = ", state.elapsed_cg)
            println("elapsed_valuefit = ", state.elapsed_valuefit)
        end
    end
    exper, lg
end
exper, lg = hopper_NPG(npg, false);

# Let's go ahead and plot the final reward trajectory for our stochastic and mean policies
# to see how we did:
plot(
    [lg[:algstate][:meantraj_reward] lg[:algstate][:stoctraj_reward]],
    labels = ["Mean Policy" "Stochastic Policy"],
    title = "HopperV2 Reward",
    legend = :bottomright,
)

# We'll also plot the evaluations:
plot(
    [lg[:algstate][:meantraj_eval] lg[:algstate][:stoctraj_eval]],
    labels = ["Mean Policy" "Stochastic Policy"],
    title = "HopperV2 Eval",
    legend = :bottomright,
)

# Finally, we save the logged results to `exper` for later review:
exper[:logs] = get(lg)
finish!(exper); # flushes everything to disk

using Test #src
@test lg[:algstate][:stoctraj_reward][end] > 1000 #src
