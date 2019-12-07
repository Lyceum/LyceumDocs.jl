# Lyceum

![](https://github.com/Lyceum/LyceumDocs.jl/workflows/CI/badge.svg)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://lyceum.github.io/LyceumDocs.jl/dev/)

LyceumDocs.jl is part of the Lyceum eco-system and [holds contains the documentation](https://lyceum.github.io/LyceumDocs.jl/dev/) for several of the packages it is comprised of, alongside tutorials. To contribute, see below.


## Contributing

### Literate and Documenter

The documentation contained in LyceumDocs.jl is written with one of two packages:

1. [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) formatted Markdown, used primarily for auto-generated docstrings or docs which don't feature a lot of source code examples.
2. [Literate.jl](https://github.com/fredrikekre/Literate.jl) formatted `.jl` scripts, designed for [Literate programming](https://en.wikipedia.org/wiki/Literate_programming) and used when docs are comprised largely of Julia source code, like tutorials. Literate allows you to generate Markdown, regular `.jl` scripts, and IPython notebooks from a single source file.

Each has their pros and cons, and the syntax is similar enough that switching between them is fairly seamless. See each package's documentation to get a better idea of what their respective pros and cons are, as well as how to use them.

### Adding documentation

Once you've chosen which syntax you'll use, go ahead and create the respective `.md` (for Documenter) or `.jl` (for Literate) file under `docs/src`. The names of the files and folders in `docs/srcs` are parsed to generate the respective sidebar entries and follow the following scheme:

1. A valid name matches `r"^[0-9]+-.+"`. For those unfamiliar with [regular expressions](https://en.wikipedia.org/wiki/Regular_expression), that means: "(any positive number)-(anything)". The number controls in which order the pages appear, with the smallest appearing first. Group or page titles are generated from these names by dropping the leading number and replacing underscores with spaces. As an example, the following file tree:

    ```
    1-First_Page.md
    2-My_Group/1-A_Subpage.md
    ```

    Would generate:

    * A top-level page, "1-First_Page.md", with the name "First Page" and appearing first.
    * A subgroup named "My Group", appearing after "First Page", with a single sub-page: "A Subpage".

2. Additionally, if any directory or filename starts with "`@`", it is skipped and a warning message displayed. This allows you to temporarily disable pages or groups without having to move them out of `docs/src`.

3. Any other file not falling into the above two categories is considered an error.

### Building the docs

Once you've created your source file, run `julia --project` in the root of this folder and run:

```julia
julia> using LyceumDocs
julia> LyceumDocs.make(clean=true)
```

Which will delete any existing build products and generate the documentation in a new folder: `staging/build`. You can examine the page locally by opening `staging/build/index.html` in your browser. Note that links are often broken when built locally. You can also find the generated scripts and notebooks under `staging/build/static/{notebook, script}`.

By default, both Literate and Documenter files are processed, with scripts and IPython notebooks being generated from Literate source files. To change this, you can pass in a tuple of desired build targets:

```julia
julia> using LyceumDocs
julia> LyceumDocs.make(clean=true, builds=(:documenter, :notebook))
```

Which will process/build Documenter files and generate notebooks, but no Markdown or scripts from any Literate files. The default value of `builds` is `(:documenter, :notebook, :script, :markdown)`.