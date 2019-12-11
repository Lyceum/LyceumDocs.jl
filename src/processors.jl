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
    """
    !!! note "Running examples locally"
        This example and more are also available as Julia scripts and Jupyter notebooks.

        See [the how-to page](example_howto.md) for more information.

    """ * content
end

function add_title(content::String, title::String)
    """
    # $title

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

    rel_base = first(splitext(doc.rel_path))
    relrepo_path = relpath(abs_src, repo_root)

    s = replace(s, "@__FILE_URL__" => "@__REPO_ROOT_URL__/$(relrepo_path)")
    s = replace(s, "@__FILE__" => relrepo_path)
    s = replace(s, "@__EXAMPLES__" => PATHS.examples_tarfile)
    s = replace(s, "@__EXAMPLES_README__" => read(joinpath(EXAMPLE_DIR, "README.md"), String))


    if doc.kind === :documenter
        s = parse_documenter(s).body
        s = add_editurl(s)
    elseif doc.kind === :literate
        s = parse_literate(s).body

        notebook_path = joinpath(PATHS.notebook, rel_base * ".ipynb")
        s = replace(s, "@__NOTEBOOK__" => notebook_path)

        script_path = joinpath(PATHS.script, rel_base * ".jl")
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

    s = add_title(s, doc.config[:title])

    if doc.kind === :documenter
        s = replace(s, "@__REPO_ROOT_URL__" => get(config, "repo_root_url", "<unknown>"))
    elseif doc.kind === :literate
        if :script in doc.config[:builds] || :notebook in doc.config[:builds]
            s = add_examples_header(s)
        end
    end


    s
end

