```@cfg
title = "For Contributors"
weight = 1000
```

## Filing Issues

using Pkg
function getinfo(dstpath::AbstractString)
    mktempdir() do dir
        env = Pkg.Types.Context().env
        Pkg.Types.write_project(env.project, joinpath(dir, "Project.toml"))
        Pkg.Types.write_manifest(env.manifest, joinpath(dir, "Manifest.toml"))
        open(joinpath(dir, "versioninfo.txt"), "w") do io
            versioninfo(io)
        end
        Pkg.PlatformEngines.probe_platform_engines!()
        Pkg.PlatformEngines.package(dir, dstpath)
    end
end