var documenterSearchIndex = {"docs":
[{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"EditURL = \"https://github.com/Lyceum/LyceumDocs.jl/blob/master/docs/src/literate_example.jl\"","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"This example and more are also available as Julia scripts and Jupyter notebooks. See the how-to page for more information.","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"","category":"page"},{"location":"literate_example/#**7.**-Example-1","page":"Literate Example","title":"7. Example","text":"","category":"section"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"(Image: )","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"This is an example generated with Literate based on this source file: example.jl source file: example.ipynb","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"available when reading this, to better understand how the syntax in the source file corresponds to the output you are seeing.","category":"page"},{"location":"literate_example/#Basic-syntax-1","page":"Literate Example","title":"Basic syntax","text":"","category":"section"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"The basic syntax for Literate is simple, lines starting with # is interpreted as markdown, and all the other lines are interpreted as code. Here is some code:","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"x = 1//3\ny = 2//5","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"In markdown sections we can use markdown syntax. For example, we can write text in italic font, text in bold font and use links.","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"It is possible to filter out lines depending on the output using the","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"This line starts with #md and is thus only visible in the markdown output.","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"The source file is parsed in chunks of markdown and code. Starting a line with #- manually inserts a chunk break. For example, if we want to display the output of the following operations we may insert #- in between. These two code blocks will now end up in different @example-blocks in the markdown output, and two different notebook cells in the notebook output.","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"x + y","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"x * y","category":"page"},{"location":"literate_example/#Output-Capturing-1","page":"Literate Example","title":"Output Capturing","text":"","category":"section"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"Code chunks are by default placed in Documenter @example blocks in the generated markdown. This means that the output will be captured in a block when Documenter is building the docs. In notebooks the output is captured in output cells, if the execute keyword argument is set to true. Output to stdout/stderr is also captured.","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"note: Note\nNote that Documenter currently only displays output to stdout/stderr if there is no other result to show. Since the vector [1, 2, 3, 4] is returned from foo, the printing of \"This string is printed to stdout.\" is hidden.","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"function foo()\n    println(\"This string is printed to stdout.\")\n    return [1, 2, 3, 4]\nend\n\nfoo()","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"Just like in the REPL, outputs ending with a semicolon hides the output:","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"1 + 1;\nnothing #hide","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"Both Documenter's @example block and notebooks can display images. Here is an example where we generate a simple plot using the Plots.jl package","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"#using Plots\n#x = range(0, stop=6π, length=1000)\n#y1 = sin.(x)\n#y2 = cos.(x)\n#plot(x, [y1, y2])","category":"page"},{"location":"literate_example/#Custom-processing-1","page":"Literate Example","title":"Custom processing","text":"","category":"section"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"It is possible to give Literate custom pre- and post-processing functions. For example, here we insert two placeholders, which we will replace with something else at time of generation. We have here replaced our placeholders with z and 1.0 + 2.0im:","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"#MYVARIABLE = MYVALUE","category":"page"},{"location":"literate_example/#documenter-interaction-1","page":"Literate Example","title":"Documenter.jl interaction","text":"","category":"section"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"In the source file it is possible to use Documenter.jl style references, such as @ref and @id. These will be filtered out in the notebook output. For example, here is a link, but it is only visible as a link if you are reading the markdown output. We can also use equations:","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"int_Omega nabla v cdot nabla u mathrmdOmega = int_Omega v f mathrmdOmega","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"using Documenters math syntax. Documenters syntax is automatically changed to \\begin{equation} ... \\end{equation} in the notebook output to display correctly.","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"","category":"page"},{"location":"literate_example/#","page":"Literate Example","title":"Literate Example","text":"This page was generated using Literate.jl.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"EditURL = \"@__FILE_URL__\"","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"All examples can be found as Julia scripts and Jupyter notebooks in a self-contained Julia project which is available here: examples.tar.gz.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"Once downloaded, extract the archive with your tool of choice. On Linux machines, you can run:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"tar xzf examples.tar.gz","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"which will produce a folder in the same directory named \"LyceumExamples\". Inside, you'll find a README.md, reproduced below, with further instructions.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"","category":"page"},{"location":"example_howto/#LyceumDocs.jl-Examples-1","page":"Running Examples Locally","title":"LyceumDocs.jl Examples","text":"","category":"section"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"Included in this project are all the examples found at LyceumDocs.jl, each available as either a .jl script or Jupyter notebook. To start, open up a Julia REPL with the project activated by executing the following in the directory containing this README:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"julia --project=.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"Now press the ] charcter to enter the Pkg REPL-mode. Your prompt should now look like this:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"(LyceumExamples) pkg>","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"First, we'll add the LyceumRegistry so the package manager knows where to find the Lyceum packages:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"(LyceumExamples) pkg> registry add https://github.com/Lyceum/LyceumRegistry.git\n   Cloning registry from \"https://github.com/Lyceum/LyceumRegistry.git\"\n     Added registry `LyceumRegistry` to `~/.julia/registries/LyceumRegistry`\n\n(LyceumExamples) pkg>","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"Next, call instantiate to download the required packages:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"(LyceumExamples) pkg> instantiate\n  Updating registry at `~/.julia/registries/General`\n  Updating git-repo `https://github.com/JuliaRegistries/General.git`\n  Updating registry at `~/.julia/registries/LyceumRegistry`\n  Updating git-repo `https://github.com/Lyceum/LyceumRegistry.git`\n   Cloning git-repo `https://github.com/Lyceum/Lyceum.jl.git`\n\n   ...","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"You can now press Backspace to exit Pkg REPL-mode, returning you to the regular REPL:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"julia>","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"To run the Julia scripts, simply include them into your current session:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"julia> include(\"scripts/path/to/example.jl\")","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"Alternative, you can run the notebooks using IJulia:","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"julia> using IJulia\njulia> notebook(dir=\"notebooks/\"; detached=true)","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"The Jupyter notebook should open in your browser automatically. If not, go to http://localhost:8888/ in your browser of choice. From there you can browse and execute the various notebooks.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"If you run into any trouble, don't hesitate to open an issue on the LyceumDocs.jl repo.","category":"page"},{"location":"example_howto/#","page":"Running Examples Locally","title":"Running Examples Locally","text":"Enjoy!","category":"page"},{"location":"#","page":"Home","title":"Home","text":"EditURL = \"@__FILE_URL__\"","category":"page"},{"location":"#Lyceum-1","page":"Home","title":"Lyceum","text":"","category":"section"},{"location":"#Package-Statuses-1","page":"Home","title":"Package Statuses","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"import LyceumDocs: package_table_markdown_nodocs, LYCEUM_PACKAGE_DEFS\npackage_table_markdown_nodocs(LYCEUM_PACKAGE_DEFS)","category":"page"}]
}
