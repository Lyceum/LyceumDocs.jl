using LyceumAI         # For `NaturalPolicyGradient` and `DiagGaussianPolicy`
using Shapes           # For the `allocate` function
using LyceumMuJoCo     # For the HopperV2 environment
using LyceumMuJoCoViz  # For the visualizer itself
using FastClosures     # For helping avoid performance issues with closures, discussed below
using JLSO             # For loading saved data

function viz_hopper_NPG()
    # Load our experiment results
    x = JLSO.load("/tmp/hopper_example.jlso")

    env = LyceumMuJoCo.HopperV2()

    # Load the states from our saved trajectory, as well as the learned policy.
    states = x["stocstates"].states
    pol = x["policy"]

    # Allocate some buffers for our control callback.
    a = allocate(actionspace(env))
    o = allocate(obsspace(env))

    # As discussed in the Julia performance tips, captured variables
    # (e.g. in a closure) can sometimes hinder performance. To help with that,
    # we use `let` blocks as suggested.
    ctrlfn = let o = o, a = a, pol = pol
        function (env)
            getobs!(o, env)
            a .= pol(o)
            setaction!(env, a)
        end
    end

    visualize(env, controller = ctrlfn, trajectories = states)
end

viz_hopper_NPG()

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

