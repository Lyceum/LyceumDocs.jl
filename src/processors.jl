function add_editurl(content::String)
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

function add_examples_header(content::String)
    path = relpath(STAGING.examples_tarfile, STAGING.src)
    content = """
    #md # _This example and more can be downloaded [here]($path)_
    #md #
    #md # ---
    """ * content
end


function preprocess(notebook::Dict, args...; kwargs...)
    for cell in notebook["cells"], i in eachindex(cell["source"])
        cell["source"][i] = preprocess(cell["source"][i], args...; kwargs...)
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
    repo_root = get(config, "repo_root_path", REPO_DIR)
    repo_root_url =  get(config, "repo_root_url", "<unknown>")
    rel_root_name = first(splitext(doc.rel_path))
    relrepo_path = relpath(abs_src, repo_root)

    s = replace(s, "@__FILE_URL__" => "@__REPO_ROOT_URL__/$(relrepo_path)")
    s = replace(s, "@__FILE__" => relrepo_path)

    if doc.kind === :documenter
        s = parse_documenter(s).body
        s = add_editurl(s)
    elseif doc.kind === :literate
        s = parse_literate(s).body
        s = add_examples_header(s)

        notebook_path = relpath(joinpath(STAGING.notebook, rel_root_name * ".ipynb"), STAGING.src)
        s = replace(s, "@__NOTEBOOK__" => notebook_path)

        script_path = relpath(joinpath(STAGING.script, rel_root_name * ".jl"), STAGING.src)
        s = replace(s, "@__SCRIPT__" => script_path)
    end

    s
end


function postprocess(s::String, doc::Document; config::Dict=Dict())
    abs_src = joinpath(doc.root, doc.rel_path)

    repo_root = get(config, "repo_root_path", REPO_DIR)
    repo_root_url =  get(config, "repo_root_url", "<unknown>")

    filename = Literate.filename(abs_src)
    relrepo_path = relpath(abs_src, repo_root)

    if doc.kind === :documenter
        s = replace(s, "@__REPO_ROOT_URL__" => get(config, "repo_root_url", "<unknown>"))
    end

    s
end

