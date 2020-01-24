```@cfg
title = "Getting Started"
weight = 5
```

## Initial Setup

Julia can be downloaded for (Windows, Mac, and Linux)[https://julialang.org/downloads/].
We recommend the newest version.

As Lyceum is still under heavy development, all Lyceum packages are currently registered in
the [LyceumRegistry](https://github.com/Lyceum/LyceumRegistry). Note that in the future,
Lyceum will migrate to Julia's General registry. For now, however, we can add
LyceumRegistry by first entering the `]` key into the REPL to enter "Pkg Mode":

```julia-repl
julia> ]
(v1.3) pkg> registry add https://github.com/Lyceum/LyceumRegistry
   Cloning registry from "https://github.com/Lyceum/LyceumRegistry"
     Added registry `LyceumRegistry` to `~/.julia/registries/LyceumRegistry`
```

Now you can add the Lyceum packages to your environment:
```julia-repl
(v1.3) pkg> add LyceumBase
```

For more information on registrys and packaging, checkout the
[Julia Pkg.jl docs](https://julialang.github.io/Pkg.jl/v1/getting-started/).