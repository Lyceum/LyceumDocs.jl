# Lyceum Documentation

Welcome to Lyceum, a framework for developing reinforcement learning, trajectory
optimization, and other algorithms for continuous control problems in Julia. The primary
goal of Lyceum is to increase research throughput and creativity by leveraging the
flexible, performant nature of Julia and its cutting-edge ecosystem.

We hope the community can build on these tools to produce more creative (and performant!)
methods.

The Lyceum ecosystem is organized into several packages:

- [LyceumBase.jl](https://github.com/Lyceum/LyceumBase.jl), a lightweight package consisting of
    common interface definitions and utilities used throughout Lyceum, such as the
    `AbstractEnvironment` type that provides a (PO)MDP-like environment abstraction for
    robotic control.
- [LyceumAI.jl](https://github.com/Lyceum/LyceumAI.jl), a collection of trajectory optimization,
    reinforcement learning, and other algorithms for robotic control.
- [LyceumMuJoCo.jl](https://github.com/Lyceum/LyceumMuJoCo.jl), a variety of environments
    implementing the `AbstractEnvironment` interface built on the MuJoCo physics simulator.
- [LyceumMuJoCoViz.jl](https://github.com/Lyceum/LyceumMuJoCoViz.jl), a feature-rich
    interactive visualizer for LyceumMuJoCo.
- [Shapes.jl](https://github.com/Lyceum/Shapes.jl), a high-performance library for viewing
    flat (e.g. vector) data as structured data.
- [MuJoCo.jl](https://github.com/Lyceum/MuJoCo.jl), a low-level wrapper for the MuJoCo physics
    library.
- [Lyceum.jl](https://github.com/Lyceum/Lyceum.jl), a meta-package combining all of the above.


## Initial Setup

Julia can be downloaded for [Windows, Mac, and Linux](https://julialang.org/downloads/).
We recommend the newest version. Lyceum tests against all three platforms, but the authors
primarily use Linux so your mileage may vary.

As Lyceum is still under heavy development, all Lyceum packages are currently registered in
the [LyceumRegistry](@__LYCEUM_REGISTRY_URL__). Note that in the future,
Lyceum will migrate to Julia's General registry. For now, however, we can add
LyceumRegistry by first entering the `]` key into the REPL to enter "Pkg Mode":

```julia-repl
julia> ]
(v1.3) pkg> registry add @__LYCEUM_REGISTRY_URL__
   Cloning registry from "@__LYCEUM_REGISTRY_URL__"
     Added registry `LyceumRegistry` to `~/.julia/registries/LyceumRegistry`
```

Now you can add the Lyceum packages to your environment:
```julia-repl
(v1.3) pkg> add Lyceum
```

For more information on registrys and packaging, checkout the
[Julia Pkg.jl docs](https://julialang.github.io/Pkg.jl/v1/getting-started/).


## Supporting and Citing

The Lyceum ecosystem was developed as a part of academic research. If you found Lyceum
helpful and would like to support further development, please star the repository(s) as
such metrics may help secure further funding in the future. If you use Lyceum as part of your
research, teaching, or other engagements, we would be grateful if you could cite our work:

[Lyceum: An efficient and scalable ecosystem for robot learning](https://arxiv.org/abs/2001.07343)

```bibtex
@InProceedings{summers2020Lyceum,
  author        = {Summers, Colin and Lowrey, Kendall and Rajeswaran, Aravind and Srinivasa, Siddhartha and Todorov, Emanuel},
  booktitle     = {Proceedings of Machine Learning Research (PMLR)},
  title         = {Lyceum: An Efficient and Scalable Ecosystem for Robot Learning},
  year          = {2020},
  note          = {Presented at Learning for Dynamics & Control (L4DC)},
  archiveprefix = {arxiv},
  eprint        = {2001.07343},
}
```
