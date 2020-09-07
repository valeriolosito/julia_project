using Documenter

makedocs(
    root 	= "./",
    source	= "src",
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
