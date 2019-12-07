# LyceumDocs.jl Examples

Included in this project are all the examples found at [LyceumDocs.jl](https://github.com/Lyceum/LyceumDocs.jl), each
available as either a `.jl` script or [Jupyter notebook](https://jupyter.org/). To start, open up a Julia REPL with the project activated by
executing the following in the directory containing this README:

```julia
julia --project=.
```

Now press the `]` charcter to enter the [Pkg REPL-mode](https://docs.julialang.org/en/v1.0/stdlib/Pkg/#Getting-Started-1).
Your prompt should now look like this:

```julia
(LyceumExamples) pkg>
```

First, we'll add the [LyceumRegistry](https://github.com/Lyceum/LyceumRegistry) so the package manager knows where to
find the Lyceum packages:
```julia
(LyceumExamples) pkg> registry add https://github.com/Lyceum/LyceumRegistry.git
   Cloning registry from "https://github.com/Lyceum/LyceumRegistry.git"
     Added registry `LyceumRegistry` to `~/.julia/registries/LyceumRegistry`

(LyceumExamples) pkg>
```

Next, call `instantiate` to download the required packages:
```julia
(LyceumExamples) pkg> instantiate
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `https://github.com/JuliaRegistries/General.git`
  Updating registry at `~/.julia/registries/LyceumRegistry`
  Updating git-repo `https://github.com/Lyceum/LyceumRegistry.git`
   Cloning git-repo `https://github.com/Lyceum/Lyceum.jl.git`

   ...
```

You can now press `Backspace` to exit Pkg REPL-mode, returning you to the regular REPL:

```julia
julia>
```

To run the Julia scripts, simply include them into your current session:
```julia
julia> include("scripts/path/to/example.jl")
```

Alternative, you can run the notebooks using [IJulia](https://github.com/JuliaLang/IJulia.jl):

```julia
julia> using IJulia
julia> notebook(dir="notebooks/"; detached=true)
```

The Jupyter notebook should open in your browser automatically. If not, go to [http://localhost:8888/](http://localhost:8888/) in your browser of choice. From there you can browse and execute the various notebooks.

If you run into any trouble, don't hesitate to [open an issue](https://github.com/Lyceum/LyceumDocs.jl/issues) on the LyceumDocs.jl repo.

Enjoy!