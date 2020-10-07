using Documenter

makedocs(
	sitename = "My Documentation",
	pages = Any[
		"Funzioni" => "funzioni.md"
	]	
)
deploydocs(
   repo = "github.com/valeriolosito/julia_project.git",
)
