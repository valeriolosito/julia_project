push!(LOAD_PATH,"../src/")
using Documenter, Funzioni

makedocs(
	sitename = "Julia Project",
	modules = [Funzioni],
	pages = Any[
		"Home" => "index.md",
		"Funzioni" => "funzioni.md"
	]	
)
deploydocs(
   repo = "github.com/valeriolosito/julia_project.git"
)
