function process_dir(root::AbsStr, rel_dir::AbsStr; builds::TupleN{Symbol} = BUILDS, config::Dict = Dict())
    abs_dir = normpath(joinpath(root, rel_dir))
    isdir(root) || error("`root` must be a directory, got: $root")
    isdir(abs_dir) || error("`rel_dir` must be a directory, got: $rel_dir")

    seen = Set{Int}()
    for path in readdir(abs_dir)
        abs_path = normpath(joinpath(abs_dir, path))
        rel_path = normpath(joinpath(rel_dir, path))
        idtitle = parse_filename(rel_path)

        if shouldskip(abs_path)
            @warn "Skipping $abs_path: matches $SKIP_REGEX"
            continue
        elseif isnothing(idtitle)
            error("Bad name \"$idtitle\": does not match $NAME_REGEX")
        else
            id, title = idtitle
            if id in seen
                @warn "Skipping $abs_path. Duplicate page or section id \"$id\" detected."
                continue
            else
                push!(seen, id)
                if isdir(abs_path)
                    process_dir(root, rel_path, builds=builds, config=config)
                else
                    @assert isfile(abs_path)
                    if ismarkdown(abs_path) && :documenter in builds
                        process_documenter(abs_path, rel_path, config=config)
                    else
                        for b in builds
                            if b !== :documenter
                                process_literate(abs_path, rel_path, b, config=config)
                            end
                        end
                    end
                end
            end
        end
    end
end


function process_documenter(abs_srcfile::AbsStr, rel_srcfile::AbsStr; config::Dict = Dict())
    isfile(abs_srcfile) || error("Not a file: $abs_srcfile")
    ismarkdown(abs_srcfile) || error("Expected Markdown, got $abs_srcfile")
    abs_dstfile = joinpath(STAGING.src, rel_srcfile)
    mkpath(dirname(abs_dstfile))

    haskey(config, "preprocess") && @warn "Overriding preprocess function in config"
    haskey(config, "postprocess") && @warn "Overriding postprocess function in config"
    pre = x -> preprocess(x, abs_srcfile, rel_srcfile; config=config)
    post = x -> postprocess(x, abs_srcfile, rel_srcfile; config=config)
    content = post(pre(read(abs_srcfile, String)))

    open(io -> write(io, content), abs_dstfile, "w")
    abs_dstfile
end

function process_literate(abs_srcfile::AbsStr, rel_srcfile::AbsStr, build::Symbol; config::Dict = Dict())
    isfile(abs_srcfile) || error("Not a file: $abs_srcfile")
    isliterate(abs_srcfile) || error("Expected Literate file, got $abs_srcfile")

    haskey(config, "preprocess") && @warn "Overriding preprocess function in config"
    haskey(config, "postprocess") && @warn "Overriding postprocess function in config"
    pre = x -> preprocess(x, abs_srcfile, rel_srcfile; config=config)
    post = x -> postprocess(x, abs_srcfile, rel_srcfile; config=config)
    config["preprocess"] = pre
    config["postprocess"] = post

    if build === :markdown
        abs_dstfile = joinpath(STAGING.src, rel_srcfile)
        mkpath(dirname(abs_dstfile))
        Literate.markdown(abs_srcfile, dirname(abs_dstfile), config=config)
    elseif build === :script
        abs_dstfile = joinpath(STAGING.script, rel_srcfile)
        mkpath(dirname(abs_dstfile))
        Literate.script(abs_srcfile, dirname(abs_dstfile), config=config)
    elseif build === :notebook
        abs_dstfile = joinpath(STAGING.notebook, rel_srcfile)
        mkpath(dirname(abs_dstfile))
        Literate.notebook(abs_srcfile, dirname(abs_dstfile), config=config)
    else
        error("`build` must be one of :markdown, :script, or :notebook")
    end

    return abs_dstfile
end



islocalbuild() = get(ENV, "GITHUB_ACTIONS", nothing) != "true"
shouldskip(path) = !isnothing(match(SKIP_REGEX, path))
ismarkdown(file) = (@assert isfile(file); endswith(file, ".md"))
isliterate(file) = (@assert isfile(file); endswith(file, ".jl"))

function parse_filename(rel_path)
    if rel_path == "index.md"
        return -1, "Home"
    else
        m = match(NAME_REGEX, basename(rel_path))
        if isnothing(m)
            return nothing
        else
            id = parse(Int, m[1])
            title = replace(splitext(m[2])[1], '_'=>' ')
            id < 0 && error("id must be >= 0, got: $id")
            return id, title
        end
    end
end


function build_pages(root::AbsStr, rel_dir::AbsStr)
    abs_dir = normpath(joinpath(root, rel_dir))
    isdir(root) || error("`root` must be a directory, got: $root")
    isdir(abs_dir) || error("`rel_dir` must be a directory, got: $rel_dir")

    pages = Vector{Tuple{Int, String, Union{String, Vector}}}() # (id, title, page_or_section)
    for file_or_dir in readdir(abs_dir)
        abs_path = normpath(joinpath(abs_dir, file_or_dir))
        rel_path = normpath(joinpath(rel_dir, file_or_dir))
        idtitle = parse_filename(rel_path)

        if shouldskip(abs_path)
            @warn "Skipping $abs_path: matches $SKIP_REGEX"
            continue
        elseif isnothing(idtitle)
            error("Bad name \"$idtitle\": does not match $NAME_REGEX")
        else
            id, title = idtitle
        end

        if isfile(abs_path) && ismarkdown(abs_path)
            # Only add markdown files to index
            page_or_section = relpath(abs_path, root)
        else
            @assert isdir(abs_path)
            page_or_section = build_pages(root, joinpath(rel_dir, file_or_dir))
        end

        push!(pages, (id, title, page_or_section))
    end
    sort!(pages, by=first)
    map(pages) do (_, title, page_or_section)
        title => page_or_section
    end
end

function indented_println(xs...; indent = 0)
    for _ = 1:(Base.indent_width*indent)
        print(' ')
    end
    println(xs...)
end

function print_pages(index, indent=0)
    for (title, page_or_section) in index
        if page_or_section isa String
            indented_println(title, " => ", page_or_section, indent=indent)
        else
            indented_println(title, indent=indent)
            print_pages(page_or_section, indent + 1)
        end
    end
end