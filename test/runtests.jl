using Test, Pkg, LyceumDocs

function collect_scripts()
    scripts = String[]
    for (root, _, files) in walkdir(LyceumDocs.SRC_DIR), file in files
        abs_path = joinpath(root, file)
        if LyceumDocs.isliterate(abs_path, read(abs_path, String))
            push!(scripts, abs_path)
        end
    end
    scripts
end

function do_one(script)
    curdir = pwd()
    curproj = Base.active_project()
    tmpdir = mktempdir()
    try
        LyceumDocs.create_example_project(tmpdir)
        cd(tmpdir)
        Pkg.activate(".")
        run(`julia --check-bounds=yes --startup-file=no --project=$(tmpdir) $(script)`)
        return true
    catch e
        @error e
        return false
    finally
        cd(curdir)
        Pkg.activate(curproj)
        rm(tmpdir, force = true, recursive = true)
    end
end

@testset "LyceumDocs.jl" begin
    @testset "$(relpath(script, LyceumDocs.SRC_DIR))" for script in collect_scripts()
        @test do_one(script)
    end
end
