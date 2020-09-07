function load_builtin_selectop()
    
    global TRIL = SelectOperator("GxB_TRIL", "TRIL")
    global TRIU = SelectOperator("GxB_TRIU", "TRIU")
    global DIAG = SelectOperator("GxB_DIAG", "DIAG")
    global OFFDIAG = SelectOperator("GxB_OFFDIAG", "OFFDIAG")
    global NONZERO = SelectOperator("GxB_NONZERO", "NONZERO")

end

show(io::IO, uop::SelectOperator) = print(io, "SelectOperator($(uop.name))")
