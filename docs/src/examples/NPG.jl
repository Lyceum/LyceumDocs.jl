#cfg title = "Learning a control policy"
#cfg weight = 11

#md # ## Policy Gradient Example
# In this example we walk through the process of setting up an experiment
# that runs [Natural Policy Gradient](https://papers.nips.cc/paper/2073-a-natural-policy-gradient.pdf),
# or more recently [in this work](https://arxiv.org/abs/1703.02660).
# This is an on-policy reinforcement learning method that is comparable to TRPO,
# PPO, and other policy gradient methods.

# First, let's go head and grab all the dependencies
using LinearAlgebra, Random, Statistics # From Stdlib
using LyceumAI         # For the NPG controller
using LyceumMuJoCo     # For the Hopper environment
using LyceumBase.Tools # For the ControllerIterator discussed below
using Flux             # For our Neural Network Needs
using Flux: glorot_uniform
using UniversalLogger
using Plots

# We first configure and instantiate of our `Hopper` environment to grab useful
# environment specific values such as the size of the observation and action vectors.
env = LyceumMuJoCo.HopperV2();
dobs, dact = length(obsspace(env)), length(actionspace(env));

#md # ## Policy Gradient Components
# Policy Gradient methods require a policy: a function that takes in the state/observations
# of the agent, and output an action. a = π(obs).
# In much of Deep RL, the policy takes the form of a neural network, which we instantiate
# on top of the [Flux.jl](https://github.com/FluxML/Flux.jl) library.
# The network below is two layers, mapping from our observation space to 32 hidden units,
# to the second 32 hidden units layer, before emitting a vector of actions. The activations
# are all tanh functions, and we initialize the network with Glorot Uniform initializations.
# The policy is more than just a feed forward nerual network, however. It's treated as a
# stochastic variable, and thus we track the log of the standard deviation of noise to apply
# to the action sampling; this is final zero vector of size 'dact'.
policy = DiagGaussianPolicy(
    multilayer_perceptron(
        dobs,
        32,
        32,
        dact;
        σ = tanh,
        initb = glorot_uniform,
        initb_final = glorot_uniform,
    ),
    zeros(dact),
)
policy = Flux.paramtype(Float32, policy); # We make sure the Policy is a consistent type



# This NPG implementation uses Generalized Advantaged Estimation, where we subract the estimate
# of the current policy's performance from an estimate of the value function on the same inputs.
# The calculation of the advangate is more stable in for gradient descent. We represent the value
# function as a neural network as well.
value = multilayer_perceptron(
    dobs,
    128,
    128,
    1;
    σ = Flux.relu,
    initb = glorot_uniform,
    initb_final = glorot_uniform,
)
value = Flux.paramtype(Float32, value); # Again, consistent type; imporant for performance




# FluxTrainer is an iterator that loops on the Flux object provided.
# The result at each loop is passed to stopcb below, so you can quit after
# a number of epochs, convergence, or other criteria; here it's capped at two epochs
# as a lambda function.
valueloss(bl, X, Y) = Flux.mse(vec(bl(X)), vec(Y))
valuetrainer = FluxTrainer(
    optimiser = ADAM(1e-3),
    szbatch = 64,
    lossfn = valueloss,
    stopcb = s -> s.nepochs > 2,
);


# The `NaturalPolicyGradient` iterator is a struct that contains relevant data objects
# for learning a policy. We first pass in a constructor that, given an input Int
# (in this case the thread ID), will construct an env; this is for thread-safe multi-threading.
# The policy and value objects are passed as well as a number of parameters; shown here are
# generally good defaults but could change depending on the environment and problem.
# Finally, the max trajectory length is set as 'Hmax', and the total
# number of samples 'N', specified.
# Multi-threading happens to collect the 'N' samples using as many threads as possible, up to
# a trajectory length of Hmax.
npg = NaturalPolicyGradient(
    i -> tconstruct(LyceumMuJoCo.HopperV2, i),
    policy,
    value,
    valuetrainer;
    gamma = 0.995,
    gaelambda = 0.97,
    norm_step_size = 0.05,
    Hmax = 1000,
    N = 10000,
);

#md # ## Running Experiments
# Finally, let's spin on our iterator 200 times, plotting every 20 iterations.
# This lets us break out of the loop if certain conditions are met, or re-start training
# manually if needed. We of course wish to track results, so we create an Experiment to
# which we can save data. We also
# have useful timing information displayed every 20 iterations to understand CPU performance.
exper = Experiment("/tmp/hopper_example.jlso", overwrite = true)
lg = ULogger() # walks, talks, and acts like a Julia logger
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

    if mod(i, 20) == 0
        x = lg[:algstate]
        ## The following are helper functions for plotting to the terminal.
        ## The first plot renders the 'Eval' function associated with the env.
        display(expplot(
            Line(x[:stocterminal_eval], "StocLastE"),
            Line(x[:meanterminal_eval], "MeanLastE"),
            title = "Evaluation Score, Iter=$i",
            width = 60,
            height = 8,
        ))

        display(expplot(
            Line(x[:stoctraj_reward], "StocR"),
            Line(x[:meantraj_reward], "MeanR"),
            title = "Reward, Iter=$i",
            width = 60,
            height = 8,
        ))

        ## The following is timing values for each component of the last iteration.
        ## It's useful to see where the compute is going.
        println("elapsed_sampled  = ", state.elapsed_sampled) #md
        println("elapsed_gradll   = ", state.elapsed_gradll)  #md
        println("elapsed_vpg      = ", state.elapsed_vpg)     #md
        println("elapsed_cg       = ", state.elapsed_cg)      #md
        println("elapsed_valuefit = ", state.elapsed_valuefit)#md
    end
end

# Let's go ahead and plot the final reward trajectory and see how we did. The two
# lines is a property of a Policy Gradient method: there is a stochastic policy that takes
# the actions of the policy and adds noise to explore for better behavior.
plot!(
    plot(lg[:algstate][:meantraj_reward], label = "Mean Policy", title = "HopperV2 Reward"),
    lg[:algstate][:stoctraj_reward],
    label = "Stochastic Policy",
)

# and save the logged results to the experiment's JLSO
for (k, v) in get(lg)
    exper[k] = v
end
finish!(exper);
