function create_example_project(dst_example_dir)
    mkpath(dst_example_dir)

    lyceumdocs_project = Pkg.TOML.parsefile(joinpath(REPO_DIR, "Project.toml"))
    lyceumdocs_manifest = Pkg.TOML.parsefile(joinpath(REPO_DIR, "Manifest.toml"))

    # copy project skeleton over and setup project/manifest
    example_project = Pkg.TOML.parsefile(joinpath(EXAMPLE_DIR, "Project.toml"))
    for k in keys(example_project)
        if !(k in ("name", "uuid", "deps"))
            delete!(example_project, k)
        end
    end
    example_project["compat"] = Dict{String, Any}()

    # sync deps/compat with LyceumDocs
    example_project["version"] = lyceumdocs_project["version"]
    example_project["compat"]["julia"] = lyceumdocs_project["compat"]["julia"]
    specs = Pkg.Types.PackageSpec[]
    for (name, uuid) in pairs(example_project["deps"])
        if haskey(lyceumdocs_project["compat"], name)
            example_project["compat"][name] = lyceumdocs_project["compat"][name]
        end
        if haskey(lyceumdocs_manifest, name)
            idx = findfirst(x->x["uuid"] == uuid, lyceumdocs_manifest[name])
            info = lyceumdocs_manifest[name][idx]
            haskey(info, "path") && error("Local path detected for $name")
            if haskey(info, "repo-rev")
                rev = info["repo-rev"]
                @warn "repo-rev $rev detected for $name"
                spec = PackageSpec(name = name, uuid = uuid, rev = rev)
                push!(specs, spec)
            end
        end
    end

    # write LyceumExamples to dst_example_dir,
    # overwriting project and deleting manifest if they exist
    DevTools.cpinto(EXAMPLE_DIR, dst_example_dir)
    open(joinpath(dst_example_dir, "Project.toml"), "w") do io
        Pkg.TOML.print(io, example_project)
    end
    rm(joinpath(dst_example_dir, "Manifest.toml"), force=true)

    curdir = pwd()
    curproj = Base.active_project()
    try
        cd(dst_example_dir)
        Pkg.activate(".")
        Pkg.add(specs)
        Pkg.instantiate()
    finally
        cd(curdir)
        Pkg.activate(curproj)
    end
end

function bundle_examples()
    Pkg.PlatformEngines.probe_platform_engines!()
    paths = map(p->joinpath(STAGING_DIR, p), PATHS)
    mktempdir() do tmpdir
        proj = mkdir(joinpath(tmpdir, basename(EXAMPLE_DIR)))
        create_example_project(proj)
        isdir(paths.script) && cp(paths.script, joinpath(proj, basename(paths.script)))
        isdir(paths.notebook) && cp(paths.notebook, joinpath(proj, basename(paths.notebook)))
        run(Pkg.PlatformEngines.gen_package_cmd(tmpdir, paths.examples_tarfile))
    end
end
