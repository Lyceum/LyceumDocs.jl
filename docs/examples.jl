const EXAMPLE_DIR = joinpath(@__DIR__, "assets/LyceumExamples")
const EXAMPLE_UUID = "208cb147-aad3-4bdb-b918-25b9ecee4332"

function create_example_project(dst_example_dir)
    # copy project skeleton over and setup project/manifest
    example_project = Dict{String, Any}()
    example_manifest = Dict{String, Any}()
    example_project["name"] = basename(EXAMPLE_DIR)
    example_project["uuid"] = EXAMPLE_UUID

    lyceumdocs_project = Pkg.TOML.parsefile(joinpath(REPO_DIR, "Project.toml"))
    lyceumdocs_manifest = Pkg.TOML.parsefile(joinpath(REPO_DIR, "Manifest.toml"))

    # sync deps/compat with LyceumDocs
    example_project["version"] = lyceumdocs_project["version"]
    example_project["deps"] = lyceumdocs_project["deps"]
    example_project["compat"] = lyceumdocs_project["compat"]

    # write LyceumExamples to dst_example_dir,
    # overwriting project/manifest if they exist
    DevTools.cpinto(EXAMPLE_DIR, dst_example_dir)
    open(joinpath(dst_example_dir, "Project.toml"), "w") do io
        Pkg.TOML.print(io, example_project)
    end
    open(joinpath(dst_example_dir, "Manifest.toml"), "w") do io
        Pkg.TOML.print(io, example_manifest)
    end
end