"""
    GrB_Matrix_new(A, type, nrows, ncols)

Initialize a matrix with specified domain and dimensions.

"""
function GrB_Matrix_new(A::GBMatrix, type::GType, nrows::Union{Int64,UInt64}, ncols::Union{Int64,UInt64}) where T
    A_ptr = pointer_from_objref(A)

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_new"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Cuintmax_t),
            A_ptr, _gb_pointer(type), nrows, ncols
            )
        )
    
end

"""
    GrB_Matrix_build(C, I, J, X, nvals, dup)

Store elements from tuples into a matrix.

"""
function GrB_Matrix_build(C::GBMatrix{T}, I::Vector{U}, J::Vector{U}, X::Vector{T}, nvals::U, dup::GrB_BinaryOp) where {T,U <: Union{Int64,UInt64}}
    I_ptr = pointer(I)
    J_ptr = pointer(J)
    X_ptr = pointer(X)
    fn_name = "GrB_Matrix_build_" * _gb_type(T).name
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{T}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(C), I_ptr, J_ptr, X_ptr, nvals, _gb_pointer(dup)
            )
        )
    
end

"""
    GrB_Matrix_nrows(A)

Return the number of rows in a matrix if successful.
Else return `GrB_Info` error code.

"""
function GrB_Matrix_nrows(A::GBMatrix)
    nrows = Ref(UInt64(0))
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_nrows"),
            Cint,
            (Ptr{UInt64}, Ptr{Cvoid}),
            nrows, _gb_pointer(A)
            )
        )
    
    return nrows[]
end

"""
    GrB_Matrix_ncols(A)

Return the number of columns in a matrix if successful.
Else return `GrB_Info` error code.

"""
function GrB_Matrix_ncols(A::GBMatrix)
    ncols = Ref(UInt64(0))
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_ncols"),
            Cint,
            (Ptr{UInt64}, Ptr{Cvoid}),
            ncols, _gb_pointer(A)
            )
        )
    
    return ncols[]
end

"""
    GrB_Matrix_nvals(A)

Return the number of stored elements in a matrix if successful.
Else return `GrB_Info` error code..

"""
function GrB_Matrix_nvals(A::GBMatrix)
    nvals = Ref(UInt64(0))
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_nvals"),
            Cint,
            (Ptr{UInt64}, Ptr{Cvoid}),
            nvals, _gb_pointer(A)
            )
        )
    
    return nvals[]
end

"""
    GrB_Matrix_dup(C, A)

Initialize a new matrix with the same domain, dimensions, and contents as another matrix.

"""
function GrB_Matrix_dup(C::GBMatrix{T}, A::GBMatrix{T}) where T
    C_ptr = pointer_from_objref(C)

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_dup"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}),
            C_ptr, _gb_pointer(A)
            )
        )
    
end

"""
    GrB_Matrix_clear(A)

Remove all elements from a matrix.

"""
function GrB_Matrix_clear(A::GBMatrix)
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_clear"),
            Cint,
            (Ptr{Cvoid},),
            _gb_pointer(A)
            )
        )
end

"""
    GrB_Matrix_setElement(C, X, I, J)

Set one element of a matrix to a given value, C[I][J] = X.

"""
function GrB_Matrix_setElement(C::GBMatrix{T}, X::T, I::U, J::U) where {T,U <: Integer}
    fn_name = "GrB_Matrix_setElement_" * _gb_type(T).name
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Cintmax_t, Cuintmax_t, Cuintmax_t),
            _gb_pointer(C), X, I, J
            )
        )
end

function GrB_Matrix_setElement(C::GBMatrix{UInt64}, X::UInt64, I::Integer, J::Integer)
    fn_name = "GrB_Matrix_setElement_UINT64"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Cuintmax_t, Cuintmax_t, Cuintmax_t),
            _gb_pointer(C), X, I, J
            )
        )
end

function GrB_Matrix_setElement(C::GBMatrix{Float32}, X::Float32, I::Integer, J::Integer)
    fn_name = "GrB_Matrix_setElement_FP32"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Cfloat, Cuintmax_t, Cuintmax_t),
            _gb_pointer(C), X, I, J
            )
        )
end

function GrB_Matrix_setElement(C::GBMatrix{Float64}, X::Float64, I::Integer, J::Integer)
    fn_name = "GrB_Matrix_setElement_FP64"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Cdouble, Cuintmax_t, Cuintmax_t),
            _gb_pointer(C), X, I, J
            )
        )
end

function GrB_assign(A::GBMatrix{T}, v, rows, cols, mask, accum, desc) where T
    v = convert(T, v)
    
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_assign_" * A.type.name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), v,
            pointer(rows), length(rows), pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
end

function GrB_assign(A::GBMatrix{UInt64}, v::UInt64, rows, cols, mask, accum, desc)
    fn_name = "GrB_Matrix_assign_UINT64"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), v,
            pointer(rows), length(rows), pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
end

function GrB_assign(A::GBMatrix{Float32}, v::Float32, rows, cols, mask, accum, desc)
    fn_name = "GrB_Matrix_assign_FP32"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cfloat, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), v,
            pointer(rows), length(rows), pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
end

function GrB_assign(A::GBMatrix{Float64}, v::Float64, rows, cols, mask, accum, desc)
    fn_name = "GrB_Matrix_assign_FP64"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cdouble, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), v,
            pointer(rows), length(rows), pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
end


"""
    GrB_Matrix_extractElement(A, row_index, col_index)

Return element of a matrix at a given index (A[row_index][col_index]) if successful.
Else return `GrB_Info` error code.

"""
function GrB_Matrix_extractElement(A::GBMatrix{T}, row_index::U, col_index::U) where {T,U <: Integer}
    fn_name = "GrB_Matrix_extractElement_" * _gb_type(T).name

    element = Ref(T(0))
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Cuintmax_t),
            element, _gb_pointer(A), row_index, col_index
            )
        )

    return element[]
end

"""
    GrB_Matrix_extractTuples(A,[ index_type])

Return tuples stored in a matrix if successful.
Else return `GrB_Info` error code.
Returns zero based indices by default.

"""
function GrB_Matrix_extractTuples(A::GBMatrix{T}) where T
    nvals = GrB_Matrix_nvals(A)

    row_indices = Vector{Int64}(undef, nvals)
    col_indices = Vector{Int64}(undef, nvals)
    vals = Vector{T}(undef, nvals)
    n = Ref(UInt64(nvals))

    fn_name = "GrB_Matrix_extractTuples_" * _gb_type(T).name
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{UInt64}, Ptr{Cvoid}),
            pointer(row_indices), pointer(col_indices), pointer(vals), n, _gb_pointer(A)
            )
        )
    
    return row_indices, col_indices, vals
end
