#cfg title = "Getting Started"
#cfg weight = 10
#cfg active = true

# ## Initial Setup

# Julia can be downloaded for (Windows, Mac, and Linux)[https://julialang.org/downloads/]. We recommend the newest version.

# All Lyceum packages are currently tracked by it's own registry: (LyceumRegistry)[https://github.com/Lyceum/LyceumRegistry]. This is added first, before adding additional packages from the ecosystem. A 'Getting Started'
# guide to Julia's built in package management can be found (here)[https://julialang.github.io/Pkg.jl/v1/getting-started/]. We highly recommend that projects are organized through the Project/Manifest.toml system of Julia that tracks dependencies.
# The following is an example of activating a new Julia project, adding Lyceum to its dependencies, and precompiling its packages.

# TODO TODO TODO update lyceum reg to not need to check out lyceum#master ????
# and double check all this process because the shit seems super broken (wont precompile, even with lyceum#master)

#md ```julia
#md julia> ]     # This activates the Julia package manager in the REPL
#md (v1.3) pkg> activate LyceumTest
#md Activating new environment at `/tmp/LyceumTest/Project.toml`
#md 
#md (LyceumTest) pkg> registry add https://github.com/Lyceum/LyceumRegistry
#md    Cloning registry from "https://github.com/Lyceum/LyceumRegistry"
#md [ Info: registry `LyceumRegistry` already exist in `~/.julia/registries/LyceumRegistry`.
#md 
#md (LyceumTest) pkg> add Lyceum
#md   Updating registry at `~/.julia/registries/General`
#md   Updating git-repo `https://github.com/JuliaRegistries/General.git`
#md   Updating registry at `~/.julia/registries/LyceumRegistry`
#md   Updating git-repo `https://github.com/Lyceum/LyceumRegistry`
#md Resolving package versions...
#md   Updating `/tmp/LyceumTest/Project.toml`
#md   [f25b5985] + Lyceum v0.1.0
#md   Updating `/tmp/LyceumTest/Manifest.toml`
#md 
#md   (...)
#md
#md (LyceumTest) pkg> precompile
#md ```

# At this point we can add the individual Lyceum packages, and begin using them. The examples from this site can now be run.

#md (LyceumTest) pkg> add LyceumAI,LyceumMuJoCo
#md (LyceumTest) pkg> precompile
#md (LyceumTest) pkg> #ctrl-c
#md julia> using LyceumAI


# ## MuJoCo

# (MuJoCo)[http://mujoco.org/] is a physics simulator designed for multi-joint dynamics with contacts, and has
# become a standard in robotics, reinforcement learning, and trajectory optimization experiments in both academia
# and industry. Currently the abstract environment API of `LyceumBase` is implemented in `LyceumMuJoCo` utilizing
# a thin (MuJoCo wrapper)[https://github.com/Lyceum/MuJoCo.jl]. This allows for zero overhead access to all of
# (MuJoCos features)[http://mujoco.org/image/home/mujocodemo.mp4].

# We note this here as to use MuJoCo one needs to expose an environment variable, `MUJOCO_KEY_PATH` for the software
# to detect the license key file.

```bash
[host]:~/ > export MUJOCO_KEY_PATH=/home/$user/.mujoco/key.txt # replace with appropriate directory
```

# We encourage other instantiations of the LyceumBase API with other physics engines, but only MuJoCo is
# currently supported.

