push!(LOAD_PATH,"../src/")

using Documenter, SuiteSparseGraphBLAS

makedocs(
    modules     = [MatrixSuiteSparseGraphBLAS],
    format      = Documenter.HTML(),
    sitename    = "MatrixSuiteSparseGraphBLAS",
    doctest     = false,
    pages       = Any[
		"Home"								=> "index.md",
    "Project operations"					=> "operation.md"
    ]
)

deploydocs(
    repo = "github.com/valeriolosito/julia_project.git",
)
