abstract type Node end

struct Group <: Node
    root::String
    rel_path::String
    children::Vector{Node}
    config::Dict{Symbol,Any}
    function Group(root, rel_path, children, config)
        d = joinpath(root, rel_path)
        isdir(d) || throw(ArgumentError("Not a directory: $d"))
        check_config(config)
        new(root, rel_path, children, config)
    end
end

struct Document <: Node
    root::String
    rel_path::String
    kind::Symbol
    config::Dict{Symbol,Any}
    function Document(root, rel_path, children, config)
        f = joinpath(root, rel_path)
        isfile(f) || throw(ArgumentError("Not a file: $f"))
        check_config(config)
        new(root, rel_path, children, config)
    end
end


const BUILDS = (:markdown, :script, :notebook)

const CONFIG_DEFAULTS = Dict(
    :active => true,
    :builds => BUILDS,
    :hide => false,
    :short_title => :use_title,
    :title => nothing,
    :weight => nothing,
)



function group(root)
    config = parsefile_config(joinpath(root, "_config.jl"))
    inheritconfig!(config, CONFIG_DEFAULTS)

    grp = Group(root, ".", Node[], config)

    for child in readdir(root)
        if endswith(child, ".jl") || endswith(child, ".md")
            if child == "_config.jl"
                continue
            elseif isdir(joinpath(root, child))
                push!(grp.children, group(child, grp))
            else
                push!(grp.children, document(child, grp))
            end
        end
    end
    grp
end

function group(rel_path, parent::Group)
    config = parsefile_config(joinpath(parent.root, rel_path, "_config.jl"))
    inheritconfig!(config, parent.config)

    grp = Group(parent.root, rel_path, Node[], config)

    for child in readdir(joinpath(parent.root, rel_path))
        if child == "_config.jl"
            continue
        else
            child = joinpath(rel_path, child)
            if isdir(joinpath(parent.root, child))
                push!(grp.children, group(child, grp))
            else
                push!(grp.children, document(child, grp))
            end
        end
    end
    grp
end

function document(rel_path, parent::Group)
    kind, config, body = parsefile(joinpath(parent.root, rel_path))
    inheritconfig!(config, parent.config)
    Document(parent.root, rel_path, kind, config)
end



function parsefile(path)
    try
        content = read(path, String)
        if isliterate(path, content)
            kind = :literate
            config, body = parse_literate(content)
        elseif isdocumenter(path, content)
            kind = :documenter
            config, body = parse_documenter(content)
        else
            error("Expected either a Documenter or Literate formatted file")
        end
        return kind, parse_config(config), body
    catch e
        error("""
             $(sprint(showerror, e))
             while processing $path
             """)
    end
end

function parse_documenter(content::String)
    md = Markdown.parse(content)
    body_blocks, content_blocks = Markdown.Code[], []
    for block in md.content
        if block isa Markdown.Code && block.language == "@cfg"
            push!(body_blocks, block)
        else
            push!(content_blocks, block)
        end
    end
    config = join(map(b -> b.code, body_blocks), '\n') * '\n'
    body = string(Markdown.MD(content_blocks))
    (config = config, body = body)
end

function parse_literate(content::String)
    lines = collect(eachline(IOBuffer(content)))
    config, body = String[], String[]
    for line in lines
        line = rstrip(line)
        m = match(r"^#cfg\h*(?<content>.+)", line)
        if m === nothing
            push!(body, line)
        else
            push!(config, rstrip(m[:content]))
        end
    end

    if isempty(config)
        error("No #cfg lines found")
    else
        config = join(config, '\n') * '\n'
        body = join(body, '\n') * '\n'
        return (config = config, body = body)
    end
end

function parsefile_config(path)
    try
        return parse_config(read(path, String))
    catch e
        error("""
             $(sprint(showerror, e))
             while parsing $path
             """)
    end
end

function parse_config(config_block::String)
    mod = execute_block(config_block)
    config = Dict{Symbol,Any}()
    for k in keys(CONFIG_DEFAULTS)
        isdefined(mod, k) && (config[k] = getfield(mod, k))
    end
    config
end



function inheritconfig!(dst, src)
    for k in keys(CONFIG_DEFAULTS)
        if k === :short_title
            dst[k] = get(dst, k, :use_title)
        else
            get(dst, k, nothing) === nothing && (dst[k] = src[k])
        end
    end
end

function check_config(config)
    c = config
    _check_type(k, T) = c[k] isa T || error("Config option `$k` must be of type `$T`")

    for k in keys(CONFIG_DEFAULTS)
        haskey(c, k) || error("Missing config option `$k`")
    end

    _check_type(:active, Bool)
    _check_type(:builds, Tuple)
    for b in c[:builds]
        b in BUILDS || error("Invalid build option `$b`. Valid options are: $BUILDS")
    end
    _check_type(:hide, Bool)
    _check_type(:title, AbstractString)
    if c[:short_title] === :use_title
        c[:short_title] = c[:title]
    elseif !(c[:short_title] isa AbstractString)
        error("Config option `$k` must be of type `AbstractString` or `:use_title`")
    end
    _check_type(:weight, Integer)
end



ismarkdown(path, content) = endswith(path, ".md")
isliterate(path, content) = endswith(path, ".jl")
isdocumenter(path, content) = ismarkdown(path, content)
