function process(group::Group; config = Dict())
    for child in group.children
        child.config[:active] && process(child, config = config)
    end
    group
end

function process(doc::Document; config = Dict())
    abs_src = joinpath(doc.root, doc.rel_path)
    config = deepcopy(config)

    haskey(config, "preprocess") && @warn "Overriding preprocess function in config"

    config = Literate.create_configuration(abs_src, user_config = config, user_kwargs = ())

    pre = x -> preprocess(x, doc, config = config)
    config["preprocess"] = pre

    builds = doc.config[:builds]
    paths = map(p -> joinpath(STAGING_DIR, p), PATHS)

    copy_deps(doc)

    if doc.kind === :documenter && :markdown in builds
        abs_dst = joinpath(STAGING_DIR, doc.rel_path)
        mkpath(dirname(abs_dst))
        content = pre(read(abs_src, String))
        open(io -> write(io, content), abs_dst, "w")
    else
        if :markdown in builds
            abs_dst = joinpath(STAGING_DIR, doc.rel_path)
            mkpath(dirname(abs_dst))
            Literate.markdown(abs_src, dirname(abs_dst), config = config)
        end
        if :script in builds
            abs_dst = joinpath(paths.script, doc.rel_path)
            mkpath(dirname(abs_dst))
            Literate.script(abs_src, dirname(abs_dst), config = config)
        end
        if :notebook in builds
            abs_dst = joinpath(paths.notebook, doc.rel_path)
            mkpath(dirname(abs_dst))
            Literate.notebook(abs_src, dirname(abs_dst), config = config)
        end
    end
end

function copy_deps(doc::Document)
    if !isempty(doc.config[:deps])
        for rel_path in doc.config[:deps]
            rel_path = joinpath(dirname(doc.rel_path), rel_path) # relative to doc.root
            abs_src = joinpath(doc.root, rel_path)
            abs_dst = joinpath(STAGING_DIR, rel_path)
            mkpath(dirname(abs_dst))
            cp(abs_src, abs_dst)
        end
    end
    nothing
end

function build_pages(group::Group)
    pages = filter(x -> !isnothing(x), map(_build_pages, group.children))
    sort!(pages, by = p -> p.first)
    pages = map(p -> p.second, pages)
end

function _build_pages(group::Group)
    pages = []
    for child in group.children
        page = _build_pages(child)
        page !== nothing && push!(pages, page)
    end
    sort!(pages, by = p -> p.first)
    pages = map(p -> p.second, pages)
    group.config[:weight] => group.config[:short_title] => pages
end

function _build_pages(doc::Document)
    if doc.config[:active] && (:markdown in doc.config[:builds])
        path = first(splitext(doc.rel_path)) * ".md"
        page = doc.config[:short_title] => path
        page = doc.config[:hide] ? hide(page) : page
        return doc.config[:weight] => page
    else
        return nothing
    end
end


function indented_println(xs...; indent = 0)
    for _ = 1:(Base.indent_width*indent)
        print(' ')
    end
    println(xs...)
end

function print_pages(index, indent = 0)
    for (title, page_or_section) in index
        if page_or_section isa String
            indented_println(title, " => ", page_or_section, indent = indent)
        else
            indented_println(title, indent = indent)
            print_pages(page_or_section, indent + 1)
        end
    end
end

function execute_block(block::String)
    m = Module(gensym())
    # eval(expr) is available in the REPL (i.e. Main) so we emulate that for the sandbox
    Core.eval(m, :(eval(x) = Core.eval($m, x)))
    # modules created with Module() does not have include defined
    # abspath is needed since this will call `include_relative`
    Core.eval(m, :(include(x) = Base.include($m, abspath(x))))

    # r is the result
    # status = (true|false)
    # _: backtrace
    # str combined stdout, stderr output
    r, status, _, str = Literate.Documenter.withoutput() do
        include_string(m, block)
    end
    if !status
        error("""
             $(sprint(showerror, r))
             when executing the following code block:

             $block
             """)
    end
    m
end

islocalbuild() = get(ENV, "GITHUB_ACTIONS", nothing) != "true"
