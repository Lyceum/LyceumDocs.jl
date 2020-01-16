var documenterSearchIndex = {"docs":
[{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"EditURL = \"https://github.com/Lyceum/LyceumDocs.jl/blob/master/docs/src/examples/NPG.jl\"","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"note: Running examples locally\nThis example and more are also available as Julia scripts and Jupyter notebooks.See the how-to page for more information.","category":"page"},{"location":"examples/NPG/#Learning-a-Control-Policy-1","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"","category":"section"},{"location":"examples/NPG/#Overview-1","page":"Learning a Control Policy","title":"Overview","text":"","category":"section"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"In this example we walk through the process of setting up an experiment that runs Natural Policy Gradient (or more recently in this work). This is an on-policy reinforcement learning method that is comparable to TRPO, PPO, and other policy gradient methods. See the documentation for NaturalPolicyGradient for full implementation details.","category":"page"},{"location":"examples/NPG/#The-Code-1","page":"Learning a Control Policy","title":"The Code","text":"","category":"section"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"First, let's go head and grab all the dependencies:","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"using LinearAlgebra, Random, Statistics # From Stdlib\nusing LyceumAI                          # For the NPG controller\nusing LyceumMuJoCo                      # For the Hopper environment\nusing LyceumBase.Tools                  # For the ControllerIterator discussed below\nusing Flux                              # For our neural networks needs\nusing UniversalLogger                   # For logging experiment data\nusing Plots                             # For plotting the results","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"We first instantiate a HopperV2 environment to grab useful environment-specific values, such as the size of the observation and action vectors:","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"env = LyceumMuJoCo.HopperV2();\ndobs, dact = length(obsspace(env)), length(actionspace(env));\nnothing #hide","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"We'll also seed the per-thread global RNGs:","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"seed_threadrngs!(1)","category":"page"},{"location":"examples/NPG/#Policy-Gradient-Components-1","page":"Learning a Control Policy","title":"Policy Gradient Components","text":"","category":"section"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"Policy Gradient methods require a policy: a function that takes in the state/observations of the agent, and outputs an action i.e. action = π(obs). In much of Deep RL, the policy takes the form of a neural network which can be built on top of the Flux.jl library. We utilize a stochastic policy in this example. Specifically, our policy is represented as a multivariate Gaussian distribution of the form:","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"pi(a  s) = mathcalN(mu_theta_1(textobs) Sigma_theta_2)","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"where mu_theta_1 is a neural network, parameterized by theta_1, that maps an observation obs to a mean action and Sigma_theta_2 is a diagonal covariance matrix parameterized by theta_2, the diagonal entries of the matrix. For mu_theta_1 we utilize a 2-layer neural network, where each layer has a \"width\" of 32. We use tanh activations for each hidden layer and initialize the network weights with Glorot Uniform initializations. Rather than tracking Sigma_theta_2 directly, we track the log standard deviations, which are easier to learn. We initialize log textdiag(Sigma_theta_2) as zeros(dact), i.e. a Vector of length dact, initialized to 0. Both theta_1 and theta_2 are learned in this example. Note that mu_theta_1 is a state-dependent mean while Sigma_theta_2 is a global covariance.","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"const policy = DiagGaussianPolicy(\n    multilayer_perceptron(\n        dobs,\n        32,\n        32,\n        dact;\n        σ = tanh,\n        initb = Flux.glorot_uniform,\n        initb_final = Flux.glorot_uniform,\n        dtype = Float32,\n    ),\n    zeros(Float32, dact),\n);\nnothing #hide","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"This NPG implementation uses Generalized Advantaged Estimation, which requires an estimate of the value function, value(state), which we represent using a 2-layer, feedforward neural network where each layer has a width of 128 and uses the ReLU activation function. The model weights are initialized using Glorot Uniform initialization as above.","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"const value = multilayer_perceptron(\n    dobs,\n    128,\n    128,\n    1;\n    σ = Flux.relu,\n    initb = Flux.glorot_uniform,\n    initb_final = Flux.glorot_uniform,\n    dtype = Float32,\n);\nnothing #hide","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"Next, we set up the optimization pipeline for value. We use a mini-batch size of 64 and the ADAM optimizer. FluxTrainer is an iterator that loops on the model provided, performing a single step of gradient descent at each iteration. The result at each loop is passed to stopcb below, so you can quit after a number of epochs, convergence, or other criteria; here it's capped at two epochs. See the documentation for FluxTrainer for more information.","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"valueloss(bl, X, Y) = Flux.mse(vec(bl(X)), vec(Y))\nstopcb(x) = x.nepochs > 2\nconst valuetrainer = FluxTrainer(\n    optimiser = ADAM(1e-3),\n    szbatch = 64,\n    lossfn = valueloss,\n    stopcb = stopcb\n);\nnothing #hide","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"The NaturalPolicyGradient iterator is a type that pre-allocates all necesary data structures and performs one gradient update to policy at each iteration. We first pass in a constructor that given n returns n instances of LyceumMuJoCo.HopperV2, all sharing the same jlModel, to allow NaturalPolicyGradient to allocate per-thread environments and enable performant, parallel sampling from policy. We then pass in the policy, value, and valuetrainer instances constructed above and override a few of the default NaturalPolicyGradient parameters: gamma, gaelambda, and norm_step_size. Finally, we set the max trajectory length Hmax and total number of samples per iteration, N. Under the hood, NaturalPolicyGradient will use approximately div(N, Hmax) threads to perform the sampling.","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"const npg = NaturalPolicyGradient(\n    n -> tconstruct(LyceumMuJoCo.HopperV2, n),\n    policy,\n    value,\n    valuetrainer;\n    gamma = 0.995,\n    gaelambda = 0.97,\n    norm_step_size = 0.05,\n    Hmax = 1000,\n    N = 10240,\n);\nnothing #hide","category":"page"},{"location":"examples/NPG/#Running-Experiments-1","page":"Learning a Control Policy","title":"Running Experiments","text":"","category":"section"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"Finally, let's spin on our iterator 200 times, plotting every 20 iterations. This lets us break out of the loop if certain conditions are met, or re-start training manually if needed. We of course wish to track results, so we create a ULogger and Experiment to which we can save data. We also have useful timing information displayed every 20 iterations to better understand the performance of our algorithm and identify any potential bottlenecks. Rather than iterating on npg at the global scope, we'll do it inside of a function to avoid the performance issues associated with global variables as discussed in the Julia performance tips. Note, to keep the Markdown version of this tutorial readable, we skip the plots and performance statistics. To enable them, simply call hopper_NPG(npg, true).","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"function hopper_NPG(npg::NaturalPolicyGradient, plot::Bool)\n    exper = Experiment(\"/tmp/hopper_example.jlso\", overwrite = true)\n    # Walks, talks, and acts like a Julia logger. See the UniversalLogger.jl docs for more info.\n    lg = ULogger()\n    for (i, state) in enumerate(npg)\n        if i > 200\n            # serialize some stuff and quit\n            exper[:policy] = npg.policy\n            exper[:value] = npg.value\n            exper[:etype] = LyceumMuJoCo.HopperV2\n            exper[:meanstates] = state.meanbatch\n            exper[:stocstates] = state.stocbatch\n            break\n        end\n\n        # log everything in `state` except meanbatch and stocbatch\n        push!(lg, :algstate, filter_nt(state, exclude = (:meanbatch, :stocbatch)))\n\n        if plot && mod(i, 20) == 0\n            x = lg[:algstate]\n            # The following are helper functions for plotting to the terminal.\n            # The first plot displays the `geteval` function for our stochastic\n            # and mean policy rollouts.\n            display(expplot(\n                Line(x[:stocterminal_eval], \"StocLastE\"),\n                Line(x[:meanterminal_eval], \"MeanLastE\"),\n                title = \"Evaluation Score, Iter=$i\",\n                width = 60,\n                height = 8,\n            ))\n            # While the second one similarly plots `getreward`.\n            display(expplot(\n                Line(x[:stoctraj_reward], \"StocR\"),\n                Line(x[:meantraj_reward], \"MeanR\"),\n                title = \"Reward, Iter=$i\",\n                width = 60,\n                height = 8,\n            ))\n\n            # The following are timing values for various parts of the Natural Policy Gradient\n            # algorithm at the last iteration, useful for finding performance bottlenecks\n            # in the algorithm.\n            println(\"elapsed_sampled  = \", state.elapsed_sampled)\n            println(\"elapsed_gradll   = \", state.elapsed_gradll)\n            println(\"elapsed_vpg      = \", state.elapsed_vpg)\n            println(\"elapsed_cg       = \", state.elapsed_cg)\n            println(\"elapsed_valuefit = \", state.elapsed_valuefit)\n        end\n    end\n    exper, lg\nend\nexper, lg = hopper_NPG(npg, false);\nnothing #hide","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"Let's go ahead and plot the final reward trajectory for our stochastic and mean policies to see how we did:","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"plot(\n    [lg[:algstate][:meantraj_reward] lg[:algstate][:stoctraj_reward]],\n    labels = [\"Mean Policy\" \"Stochastic Policy\"],\n    title = \"HopperV2 Reward\",\n    legend = :bottomright,\n)","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"We'll also plot the evaluations:","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"plot(\n    [lg[:algstate][:meantraj_eval] lg[:algstate][:stoctraj_eval]],\n    labels = [\"Mean Policy\" \"Stochastic Policy\"],\n    title = \"HopperV2 Eval\",\n    legend = :bottomright,\n)","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"Finally, we save the logged results to exper for later review:","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"exper[:logs] = get(lg)\nfinish!(exper); # flushes everything to disk\nnothing #hide","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"","category":"page"},{"location":"examples/NPG/#","page":"Learning a Control Policy","title":"Learning a Control Policy","text":"This page was generated using Literate.jl.","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"EditURL = \"https://github.com/Lyceum/LyceumDocs.jl/blob/master/docs/src/examples/visualize.jl\"","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"note: Running examples locally\nThis example and more are also available as Julia scripts and Jupyter notebooks.See the how-to page for more information.","category":"page"},{"location":"examples/visualize/#Using-the-Visualizer-1","page":"Using the Visualizer","title":"Using the Visualizer","text":"","category":"section"},{"location":"examples/visualize/#Overview-1","page":"Using the Visualizer","title":"Overview","text":"","category":"section"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"In this example, we walk through how to use LyceumMuJoCoViz.jl to playback saved trajectories and interact with a saved policy in real time using the policy we learned in the \"Learning a control policy\" example.","category":"page"},{"location":"examples/visualize/#The-Code-1","page":"Using the Visualizer","title":"The Code","text":"","category":"section"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"First, let's go head and grab all the dependencies:","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"using LyceumAI         # For `NaturalPolicyGradient` and `DiagGaussianPolicy`\nusing Shapes           # For the `allocate` function\nusing LyceumMuJoCo     # For the HopperV2 environment\nusing LyceumMuJoCoViz  # For the visualizer itself\nusing FastClosures     # For helping avoid performance issues with closures, discussed below\nusing JLSO             # For loading saved data","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"Here we demonstrate two modes of visualizing results of an algorithm like NaturalPolicyGradient or MPPI from LyceumAI: playing back saved trajectories and interacting with a policy or controller in real time. For the former, we need only pass to the visualize function our saved trajectories as a vector of matricies, where each element of the vector is a matrix of size (length(statespace(env)), T), where T is the length the trajectory. Note that each trajectory can be of a different length. For the latter, we pass a control callback to visualize that will be called each time step!(env) is called.","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"function viz_hopper_NPG()\n    # Load our experiment results\n    x = JLSO.load(\"/tmp/hopper_example.jlso\")\n\n    env = LyceumMuJoCo.HopperV2()\n\n    # Load the states from our saved trajectory, as well as the learned policy.\n    states = x[\"stocstates\"].states\n    pol = x[\"policy\"]\n\n    # Allocate some buffers for our control callback.\n    a = allocate(actionspace(env))\n    o = allocate(obsspace(env))\n\n    # As discussed in the Julia performance tips, captured variables\n    # (e.g. in a closure) can sometimes hinder performance. To help with that,\n    # we use `let` blocks as suggested.\n    ctrlfn = let o = o, a = a, pol = pol\n        function (env)\n            getobs!(o, env)\n            a .= pol(o)\n            setaction!(env, a)\n        end\n    end\n\n    visualize(env, controller = ctrlfn, trajectories = states)\nend","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"Now just call the function to see the visualizer appear!","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"viz_hopper_NPG()","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"You should see the following: (Image: visualizer)","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"","category":"page"},{"location":"examples/visualize/#","page":"Using the Visualizer","title":"Using the Visualizer","text":"This page was generated using Literate.jl.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"EditURL = \"@__REPO_ROOT_URL__/docs/src/example_howto.md\"","category":"page"},{"location":"example_howto/#Running-Examples-Locally-1","page":"Running Examples Locally","title":"Running Examples Locally","text":"","category":"section"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"All examples can be found as Julia scripts and Jupyter notebooks in a self-contained Julia project which is available here: examples.tar.gz.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"Once downloaded, extract the archive with your tool of choice. On Linux machines, you can run:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"tar xzf examples.tar.gz","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"which will produce a folder in the same directory named \"LyceumExamples\". Inside, you'll find a README.md, reproduced below, with further instructions.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"@EXAMPLES_README","category":"page"},{"location":"#","page":"Home","title":"Home","text":"EditURL = \"@__REPO_ROOT_URL__/docs/src/index.md\"","category":"page"},{"location":"#Home-1","page":"Home","title":"Home","text":"","category":"section"},{"location":"#Lyceum-1","page":"Home","title":"Lyceum","text":"","category":"section"},{"location":"#Package-Statuses-1","page":"Home","title":"Package Statuses","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"import LyceumDocs: package_table_markdown_nodocs, LYCEUM_PACKAGE_DEFS\npackage_table_markdown_nodocs(LYCEUM_PACKAGE_DEFS)","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"EditURL = \"https://github.com/Lyceum/LyceumDocs.jl/blob/master/docs/src/examples/humanoid.jl\"","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"note: Running examples locally\nThis example and more are also available as Julia scripts and Jupyter notebooks.See the how-to page for more information.","category":"page"},{"location":"examples/humanoid/#Creating-a-MuJoCo-Environment-1","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"","category":"section"},{"location":"examples/humanoid/#Overview-1","page":"Creating a MuJoCo Environment","title":"Overview","text":"","category":"section"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"Using LyceumMuJoCo, we will create the environment for a Humanoid \"get-up\" task that mostly relies on the defaults of LyceumBase and LyceumMuJoCo to propagate state, action, and observation data. We will have to implement reward and evaluation functions, of course, along with a few other parts of the AbstractEnvironment interface.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"We then solve the \"get-up\" task using a Model-Predictive Control method called \"Model Predictive Path Integral Control\" or MPPI, walking through how to log experiment data and plot the results.","category":"page"},{"location":"examples/humanoid/#The-Code-1","page":"Creating a MuJoCo Environment","title":"The Code","text":"","category":"section"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"First we grab our dependencies of the Lyceum ecosystem and other helpful packages.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"using LinearAlgebra, Random, Statistics\nusing Plots, UnicodePlots, JLSO\nusing LyceumBase, LyceumBase.Tools, LyceumAI, LyceumMuJoCo, MuJoCo, UniversalLogger, Shapes","category":"page"},{"location":"examples/humanoid/#Humanoid-Type-1","page":"Creating a MuJoCo Environment","title":"Humanoid Type","text":"","category":"section"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"This struct is our primary entry into the environment API. Environments utilizing the MuJoCo simulator through LyceumMuJoCo should subtype AbstractMuJoCoEnvironment <: AbstractEnvironment. As you can see, this simple example only wraps around the underlying simulator (the sim::MJSim field of Humanoid, referred to hereafter as just sim). The functions of the LyceumBase API will then dispatch on this struct through Julia's multiple dispatch mechanism. When an algorithm calls a function such as getobs!(obs, env), Julia will select from all functions with that name depending on typeof(obs) and typeof(env).","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"struct Humanoid{S<:MJSim} <: AbstractMuJoCoEnvironment\n    sim::S\nend\n\nLyceumMuJoCo.getsim(env::Humanoid) = env.sim #src (needs to be here for below example to work)","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"Humanoid (and all subtypes of AbstractEnvironment) are designed to be used in a single threaded context. To use Humanoid in a multi-threaded context, one could simply create Threads.nthreads() instances of Humanoid:","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"modelpath = joinpath(@__DIR__, \"humanoid.xml\")\nenvs = [Humanoid(MJSim(modelpath, skip = 2)) for i = 1:Threads.nthreads()]\nThreads.@threads for i = 1:Threads.nthreads()\n    thread_env = envs[Threads.threadid()]\n    step!(thread_env)\nend","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"As Humanoid only ever uses its internal jlModel (found at sim.m) in a read-only fashion, we can make a performance optimization by sharing a single instance of jlModel across each thread, resulting in improved cache efficiency. LyceumMuJoCo.tconstruct, short for \"thread construct\", helps us to do just that by providing a common interface for defining \"thread-aware\" constructors. Below, we make a call to tconstruct(MJSim, n, modelpath, skip = 2) which will construct n instances of MJSim constructed from modelpath and with a skip of 2, all sharing the exact same jlModel instance, and return n instances of Humanoid. All of the environments provided by LyceumMuJoCo feature similar definitions of tconstruct as found below.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"Humanoid() = first(tconstruct(Humanoid, 1))\nfunction LyceumMuJoCo.tconstruct(::Type{Humanoid}, n::Integer)\n    modelpath = joinpath(@__DIR__, \"humanoid.xml\")\n    return Tuple(Humanoid(s) for s in tconstruct(MJSim, n, modelpath, skip = 2))\nend","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"We can then use tconstruct as follows:","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"envs = tconstruct(Humanoid, Threads.nthreads())\nThreads.@threads for i = 1:Threads.nthreads()\n    thread_env = envs[Threads.threadid()]\n    step!(thread_env)\nend","category":"page"},{"location":"examples/humanoid/#Utilities-1","page":"Creating a MuJoCo Environment","title":"Utilities","text":"","category":"section"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"The following are helpers for the \"get-up\" task we'd like to consider. We want the humanoid to stand up, thus we need to grab the model's height, as well as record a laying down position that we can use to set the state to. By exploring the model in the REPL or MJCF/XML file we can see that sim.d.qpos[3] is the index for the z-axis (height) of the root joint. The LAYING_QPOS data was collected externally by posing the model into a supine pose; one can either use LyceumMuJoCoViz or simulate.cpp included with a MuJoCo release to do this.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"_getheight(shapedstate::ShapedView, ::Humanoid) = shapedstate.qpos[3]\nconst LAYING_QPOS = [\n    -0.164158,\n    0.0265899,\n    0.101116,\n    0.684044,\n    -0.160277,\n    -0.70823,\n    -0.0693176,\n    -0.1321,\n    0.0203937,\n    0.298099,\n    0.0873523,\n    0.00634907,\n    0.117343,\n    -0.0320319,\n    -0.619764,\n    0.0204114,\n    -0.157038,\n    0.0512385,\n    0.115817,\n    -0.0320437,\n    -0.617078,\n    -0.00153819,\n    0.13926,\n    -1.01785,\n    -1.57189,\n    -0.0914509,\n    0.708539,\n    -1.57187,\n];\nnothing #hide","category":"page"},{"location":"examples/humanoid/#The-AbstractMuJoCoEnvironment-and-AbstractEnvironment-APIs-1","page":"Creating a MuJoCo Environment","title":"The AbstractMuJoCoEnvironment and AbstractEnvironment APIs","text":"","category":"section"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"LyceumMuJoCo requires access to the underlying MJSim simulator, thus any LyceumMuJoCo environments need to point to the correct field in the environment struct that is the simulator; in our case there's only one field: sim.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"LyceumMuJoCo.getsim(env::Humanoid) = env.sim","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"Normally we could rely on MuJoCo to reset the model to the default configuration when the model XML is loaded; the humanoid.xml model, however, defaults to a vertical pose. To reset the model to our laying down or supine pose, we can copy in the data from LAYING_QPOS above to d.qpos. Calling forward! here is the same as mj_forward(env.sim.m, env.sim.d), for a pure MuJoCo reference.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"function LyceumMuJoCo.reset!(env::Humanoid)\n    reset!(env.sim)\n    env.sim.d.qpos .= LAYING_QPOS\n    forward!(env.sim)\n    return env\nend","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"This reward function uses the _getheight helper function above to get the model's height when the function is called. We also specify a target height of 1.25 and penalize the agent for deviating from the target height. There is also a small penalty for using large control activations; if the coefficient is made larger, the agent may not move at all!","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"function LyceumMuJoCo.getreward(state, action, obs, env::Humanoid)\n    height = _getheight(statespace(env)(state), env)\n    target = 1.25\n    reward = 1.0\n    if height < target\n        reward -= 2.0 * abs(target - height)\n    end\n    reward -= 1e-3 * norm(action)^2\n\n    return reward\nend","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"Finally, we can specify an evaluation function. The difference between geteval and getreward is that getreward is the shaped reward our algorithm is optimizing for, while geteval lets us track a useful value for monitoring performance, such as height. Plotting this eval function will show the agent's height over time and is very useful for reviewing actual desired behavior, regardless of the reward achieved, as it can be used to diagnose reward specification problems.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"function LyceumMuJoCo.geteval(state, action, obs, env::Humanoid)\n    return _getheight(statespace(env)(state), env)\nend","category":"page"},{"location":"examples/humanoid/#Running-Experiments-1","page":"Creating a MuJoCo Environment","title":"Running Experiments","text":"","category":"section"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"As discussed in the Julia performance tips, globals can hinder performance. To avoid this, we construct the MPPI and ControllerIterator instances within a function. This also lets us easily run our experiment with different choices of parameters (e.g. H). Like most algorithms in LyceumAI, MPPI accepts a \"thread-aware\" environment constructor as well as any algorithm parameters. In this case, we just pass a closure around the tconstruct function we defined above. MPPI, being a single-step algorithm, is itself not iterable, so we wrap it in a ControllerIterator which simply calls getaction!(action, state, obs, mppi::MPPI) for T timesteps, while simultaneously plotting and logging the trajectory rollout.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"function humanoid_MPPI(etype = Humanoid; T = 200, H = 64, K = 64)\n    env = etype()\n\n    # The following parameters work well for this get-up task, and may work for\n    # similar tasks, but are not invariant to the model.\n    mppi = MPPI(\n        env_tconstructor = n -> tconstruct(etype, n),\n        covar0 = Diagonal(0.05^2 * I, size(actionspace(env), 1)),\n        lambda = 0.4,\n        H = H,\n        K = K,\n        gamma = 1.0,\n    )\n\n    iter = ControllerIterator(mppi, env; T = T, plotiter = div(T, 10))\n\n    # We can time the following loop; if it ends up less than the time the\n    # MuJoCo models integrated forward in, then one could conceivably run this\n    # MPPI MPC controller interactively...\n    elapsed = @elapsed for (t, traj) in iter\n        # If desired, one can inspect `traj`, `env`, or `mppi` at each timestep.\n    end\n\n    if elapsed < time(env)\n        @info \"We ran in real time!\"\n    end\n\n    # Save our experiment results to a file for later review.\n    savepath = \"/tmp/opt_humanoid.jlso\"\n    exper = Experiment(savepath, overwrite = true)\n    exper[:etype] = etype\n\n    for (k, v) in pairs(iter.trajectory)\n        exper[k] = v\n    end\n    finish!(exper)\n\n    return mppi, env, iter.trajectory\nend","category":"page"},{"location":"examples/humanoid/#Checking-Results-1","page":"Creating a MuJoCo Environment","title":"Checking Results","text":"","category":"section"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"The MPPI algorithm, and any that you develop, can and should use plotting tools to track progress as they go.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"mppi, env, traj = humanoid_MPPI();\nplot(\n    [traj.rewards traj.evaluations],\n    labels = [\"Reward\" \"Evaluation\"],\n    title = \"Humanoid Standup\",\n    legend = :bottomright,\n)","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"If one wanted to review the results after training, or prepare plots for presentations, one can load the data from disk instead.","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"data = JLSO.load(\"/tmp/opt_humanoid.jlso\")\nplot(\n    [data[\"rewards\"] data[\"evaluations\"]],\n    labels = [\"Reward\" \"Evaluation\"],\n    title = \"Humanoid Standup\",\n    legend = :bottomright,\n)","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"","category":"page"},{"location":"examples/humanoid/#","page":"Creating a MuJoCo Environment","title":"Creating a MuJoCo Environment","text":"This page was generated using Literate.jl.","category":"page"}]
}
