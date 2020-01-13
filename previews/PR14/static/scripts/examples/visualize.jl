using LyceumBase, LyceumAI, MuJoCo, Shapes, FastClosures
using LyceumMuJoCo    # We need to bring the Pointmass, Hopper Envs into the workspace
using LyceumMuJoCoViz # This provides our visualization needs.
using JLSO
using FastClosures

function viz_mppi(mppi::MPPI, env::AbstractMuJoCoEnvironment)
    a = allocate(actionspace(env))
    o = allocate(obsspace(env))
    s = allocate(statespace(env))

    ctrlfn = @closure env -> (getstate!(s, env); getaction!(a, s, o, mppi); setaction!(env, a))

    # The above line is functionally the same as:
    # ctrlfn(env) = begin
    #     getstate!(s, env)
    #     getaction!(a, s, o, mppi)
    #     setaction!(env, a)
    # end
    visualize(env, controller=ctrlfn)
end

function viz_policy(path::AbstractString, etype::Union{Nothing, Type{<:AbstractMuJoCoEnvironment}}=nothing)
    x = JLSO.load(path)
    etype = isnothing(etype) ? x["etype"] : etype
    env = etype() # Load the environment based on what was in the JLSO file.

    # Check if the JLSO has a policy saved, if so, load it and prepare to render
    # the stochastic rollouts of the policy, and form a control function that is the policy's
    # mean outputs w.r.t. observations.
    # Otherwise, just render states, such as the output of MPPI.
    pol = haskey(x, "policy") ? x["policy"] : nothing

    if pol == nothing
        visualize(env; trajectories=[x["states"]])
    else
        a = allocate(actionspace(env))
        o = allocate(obsspace(env))
        ctrlfn = @closure (env) -> (getobs!(o, env); a .= pol(o); setaction!(env, a))

        states = x["stocstates"].states
        visualize(env, controller=ctrlfn, trajectories=states)
    end
end

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

