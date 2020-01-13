#cfg title = "Visualizing Results"
#cfg weight = 12

using LyceumBase, LyceumAI, MuJoCo, Shapes, FastClosures
using LyceumMuJoCo    # We need to bring the Pointmass, Hopper Envs into the workspace
using LyceumMuJoCoViz # This provides our visualization needs.
using JLSO
using FastClosures


# The following functions present two modes of visualizing results of NPG or MPPI packaged in
# LyceumAI. They both work by passing into the 'visualize' function a control callback
# and/or trajectory data to be rendered. These inputs select from available visualization modes
# TODO list the visualization modes here.
# that operate on either data passed in (the trajectory option) or will simulate the forward
# dynamics of the environment, and call the pass in control function appropriately. This
# allows for interactive policy evaluation or full model predictive control with MPPI.

function viz_mppi(mppi::MPPI, env::AbstractMuJoCoEnvironment)
    a = allocate(actionspace(env))
    o = allocate(obsspace(env))
    s = allocate(statespace(env))

    ## As discussed in the [Julia performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/),
    ## captured variables (e.g. in a closure) can sometimes hinder performance. To help with that, we use
    ## the suggested `@closure` macro from FastClosures.jl
    ctrlfn = @closure env -> (getstate!(s, env); getaction!(a, s, o, mppi); setaction!(env, a))
    visualize(env, controller = ctrlfn)
end

function viz_policy(
    path::AbstractString,
    etype::Union{Nothing,Type{<:AbstractMuJoCoEnvironment}} = nothing,
)
    x = JLSO.load(path)
    etype = isnothing(etype) ? x["etype"] : etype
    env = etype() # Load the environment based on what was in the JLSO file.

    ## Check if the JLSO has a policy saved, if so, load it and prepare to render
    ## the stochastic rollouts of the policy, and form a control function that is the policy's
    ## mean outputs w.r.t. observations.
    ## Otherwise, just render states, such as the output of MPPI.
    pol = haskey(x, "policy") ? x["policy"] : nothing

    if pol == nothing
        visualize(env; trajectories = [x["states"]])
    else
        a = allocate(actionspace(env))
        o = allocate(obsspace(env))
        ctrlfn = @closure (env) -> (getobs!(o, env); a .= pol(o); setaction!(env, a))

        states = x["stocstates"].states
        visualize(env, controller = ctrlfn, trajectories = states)
    end
end


# Assuming we have the saved JLSO files from the previous examples, we can call the above functions as such:
# TODO We want these lines in the generated script and markdown, but not to be executed during the build process.
# see https://github.com/Lyceum/LyceumDocs.jl/issues/13
#md viz_policy("/tmp/hopper_example.jlso", LyceumMuJoCo.HopperV2)
#md viz_policy("/tmp/opt_humanoid.jlso", Humanoid)
#md viz_mppi(mppi, LyceumMuJoCo.PointMass())
