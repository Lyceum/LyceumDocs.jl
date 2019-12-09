function add_editurl(content::String, path::AbsStr)
    if occursin("EditURL", content)
        print(content)
        error("$path already contains an EditURL")
    end
    """
    ```@meta
    EditURL = "@__FILE_URL__"
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
    for cell in notebook["cells"], i in eachindex(cell["source"])
        cell["source"][i] = postprocess(cell["source"][i], args...; kwargs...)
    end
    notebook
end

function postprocess(notebook::Dict, args...; kwargs...)
    for cell in notebook["cells"], i in eachindex(cell["source"])
        cell["source"][i] = postprocess(cell["source"][i], args...; kwargs...)
    end
    notebook
end


function preprocess(s::String, doc::Document; config::Dict=Dict())
    abs_src = joinpath(doc.root, doc.rel_path)
    isfile(abs_src) || error("Not a file: $abs_src")

    filename = Literate.filename(abs_src)
    fullpath = relpath(abs_src, get(config, "repo_root_path", REPO_DIR)::String)
    path = relpath(abs_src, STAGING.src)

    if doc.kind === :documenter
        s = parse_documenter(s).body
        fullpath = relpath(abs_src, get(config, "repo_root_path", REPO_DIR)::String)
        path = relpath(abs_src, STAGING.src)
        s = add_editurl(s, fullpath)
    elseif doc.kind === :literate
        s = parse_literate(s).body
    end

    s
end

function postprocess(s::String, doc::Document; config::Dict=Dict())
    abs_src = joinpath(doc.root, doc.rel_path)

    filename = Literate.filename(abs_src)
    repo_root = config["repo_root_path"]
    relrepo_path = relpath(abs_src, repo_root)
    repo_url = config["repo_root_url"]
    build_root = islocalbuild() ? STAGING.build : repo_root

    s = replace(s, "@__FILE_URL__" => "$(repo_url)/$(relrepo_path)")
    s = replace(s, "@__FILE__" => relrepo_path)
    if doc.kind === :literate
        x = relpath(joinpath(STAGING.notebook, filename * ".ipynb"), STAGING.src)
        notebook_build = relpath(joinpath(build_root, x), repo_root)
        s = replace(s, "@__NOTEBOOK__" => notebook_build)
        s = replace(s, "@__SCRIPT__" => relpath(joinpath(STAGING.script, filename * ".jl"), repo_root))
    elseif doc.kind === :documenter
        s = replace(s, "@__REPO_ROOT_URL__" => get(config, "repo_root_url", "<unknown>"))
    end

    s
end

