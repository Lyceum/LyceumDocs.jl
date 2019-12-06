function add_editurl(content::String, path::AbsStr)
    if occursin("EditURL", content)
        print(content)
        error("$path already contains an EditURL")
    end
    path = replace(path, "\\" => "/")
    """
    ```@meta
    EditURL = "@__REPO_ROOT_URL__/$path"
    ```
    """ * content
end

# TODO SKIPLINE, SKIPFILE?

function add_examples_header(content::String)
    path = relpath(STAGING.examples_tarfile, STAGING.src)
    content = """
    # _This example and more can be downloaded [here]($path)_
    #
    # ---
    """ * content
end


function preprocess(notebook::Dict, args...; kwargs...)
    for cell in notebook["cells"]
        cell["source"] = preprocess.(cell["source"], args...; kwargs...)
    end
    notebook
end

function postprocess(notebook::Dict, args...; kwargs...)
    for cell in notebook["cells"]
        cell["source"] = postprocess.(cell["source"], args...; kwargs...)
    end
    notebook
end


function preprocess(s::String, abs_srcfile::AbsStr, rel_srcfile::AbsStr; config::Dict=Dict())
    isfile(abs_srcfile) || error("Not a file: $abs_srcfile")

    filename = Literate.filename(abs_srcfile)
    fullpath = relpath(abs_srcfile, get(config, "repo_root_path", REPO_DIR)::String)
    path = relpath(abs_srcfile, STAGING.src)

    s = replace(s, "@__PATH__" => path)
    s = replace(s, "@__FULLPATH__" => fullpath)
    if isliterate(abs_srcfile)
        s = replace(s, "@__NOTEBOOK__" => relpath(joinpath(STAGING.notebook, first(splitext(rel_srcfile)) * ".ipynb"), STAGING.src))
        s = replace(s, "@__SCRIPT__" => relpath(joinpath(STAGING.script, first(splitext(rel_srcfile)) * ".jl"), STAGING.src))
    end

    s
end

function postprocess(s::String, abs_srcfile::AbsStr, rel_srcfile::AbsStr; config::Dict=Dict())
    isfile(abs_srcfile) || error("Not a file: $abs_srcfile")

    filename = Literate.filename(abs_srcfile)
    fullpath = relpath(abs_srcfile, get(config, "repo_root_path", REPO_DIR)::String)
    path = relpath(abs_srcfile, STAGING.src)

    if ismarkdown(abs_srcfile)
        s = add_editurl(s, fullpath)
    end
    s
end

