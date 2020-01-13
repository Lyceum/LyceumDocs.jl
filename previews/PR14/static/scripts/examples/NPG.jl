using LinearAlgebra, Random, Statistics # From Stdlib
using LyceumAI         # For the NPG controller
using LyceumMuJoCo     # For the Hopper environment
using LyceumBase.Tools # For the ControllerIterator discussed below
using Flux             # For our Neural Network Needs
using Flux: glorot_uniform
using UniversalLogger
using Plots

env = LyceumMuJoCo.HopperV2();
dobs, dact = length(obsspace(env)), length(actionspace(env));

policy = DiagGaussianPolicy(multilayer_perceptron(dobs, 32, 32, dact;
                                                  σ=tanh,
                                                  initb=glorot_uniform,
                                                  initb_final=glorot_uniform),
                            zeros(dact))
policy = Flux.paramtype(Float32, policy); # We make sure the Policy is a consistent type

value = multilayer_perceptron(dobs, 128, 128, 1;
                              σ=Flux.relu,
                              initb=glorot_uniform,
                              initb_final=glorot_uniform)
value = Flux.paramtype(Float32, value); # Again, consistent type; imporant for performance

valueloss(bl, X, Y) = Flux.mse(vec(bl(X)), vec(Y))
valuetrainer = FluxTrainer(optimiser = ADAM(1e-3),
                           szbatch = 64,
                           lossfn = valueloss,
                           stopcb = s -> s.nepochs > 2);

npg = NaturalPolicyGradient((i)->tconstruct(LyceumMuJoCo.HopperV2, i),
                            policy,
                            value,
                            valuetrainer;
                            gamma = 0.995,
                            gaelambda = 0.97,
                            norm_step_size = 0.05,
                            Hmax=1000,
                            N=10000);

exper = Experiment("/tmp/hopper_example.jlso", overwrite=true)
lg = ULogger() # walks, talks, and acts like a Julia logger
for (i, state) in enumerate(npg)
    if i > 200
        # serialize some stuff and quit
        exper[:policy]     = npg.policy
        exper[:value]      = npg.value
        exper[:etype]      = LyceumMuJoCo.HopperV2
        exper[:meanstates] = state.meanbatch
        exper[:stocstates] = state.stocbatch
        break
    end

    # log everything in `state` except meanbatch and stocbatch
    push!(lg, :algstate, filter_nt(state, exclude=(:meanbatch, :stocbatch)))

    if mod(i, 20) == 0
        x = lg[:algstate]
        # The following are helper functions for plotting to the terminal.
        # The first plot renders the 'Eval' function associated with the env.
        display(expplot(Line(x[:stocterminal_eval], "StocLastE"),
                        Line(x[:meanterminal_eval], "MeanLastE"),
                        title="Evaluation Score, Iter=$i", width=60, height=8
                       ));

        display(expplot(Line(x[:stoctraj_reward], "StocR"),
                        Line(x[:meantraj_reward], "MeanR"),
                        title="Reward, Iter=$i", width=60, height=8
                       ));

        # The following is timing values for each component of the last iteration.
        # It's useful to see where the compute is going.
        println("elapsed_sampled  = ", state.elapsed_sampled); #md
        println("elapsed_gradll   = ", state.elapsed_gradll);  #md
        println("elapsed_vpg      = ", state.elapsed_vpg);     #md
        println("elapsed_cg       = ", state.elapsed_cg);      #md
        println("elapsed_valuefit = ", state.elapsed_valuefit);#md
    end
end

plot!(plot(lg[:algstate][:meantraj_reward], label="Mean Policy", title="HopperV2 Reward"),
      lg[:algstate][:stoctraj_reward], label="Stochastic Policy")

for (k, v) in get(lg)
    exper[k] = v
end
finish!(exper);

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

