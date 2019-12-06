using Test, Pkg, LyceumDocs

@testset "LyceumDocs.jl" begin


function collect_scripts()
    scripts = String[]
    for (root, _, files) in walkdir(LyceumDocs.DOCSRC_DIR), file in files
        abs_path = joinpath(root, file)
        if LyceumDocs.isliterate(abs_path)
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
        return success(`julia --check-bounds=yes --startup-file=no --project $script`)
    finally
        cd(curdir)
        Pkg.activate(curproj)
        rm(tmpdir, force=true, recursive=true)
    end
end

@testset "$(relpath(script, LyceumDocs.DOCSRC_DIR))" for script in collect_scripts()
    @test do_one(script)
end


end
