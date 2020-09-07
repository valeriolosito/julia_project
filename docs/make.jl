push!(LOAD_PATH,"../src/")

using Documenter

makedocs(
    format      = Documenter.HTML(),
    sitename    = "Progetto",
    doctest     = false,
    pages       = Any[
		"Home"								=> "index.md",
    "Project operations"					=> "operation.md"
    ]
)

deploydocs(
    repo = "github.com/valeriolosito/julia_project.git",
)
