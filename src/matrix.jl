import Base: getindex, size, copy, lastindex, setindex!, eltype, adjoint, Matrix, identity, kron, transpose,
             show, ==, *, |>

import LinearAlgebra: LowerTriangular, UpperTriangular, Diagonal

"""
    from_type(type, m, n)

Create an empty `GBMatrix` of size `m`×`n` from the given type `type`.

"""
function from_type(type, m, n)
    r = GBMatrix{type}()
    GrB_Matrix_new(r, _gb_type(type), m, n)
    finalizer(_free, r)
    return r
end

"""
    from_lists(I, J, V; m = nothing, n = nothing, type = nothing, combine = Binaryop.FIRST)

Create a new `GBMatrix` from the given lists of row indices, column indices and values.
If `m` and `n` are not provided, they are computed from the max values of the row and column indices lists, respectively.
If `type` is not provided, it is inferred from the values list.
A combiner `Binary Operator` can be provided to manage duplicates values. If it is not provided, the default `BinaryOp.FIRST` is used.

# Arguments
- `I`: the list of row indices.
- `J`: the list of column indices.
- `V`: the list of values.
- `[m]`: the number of rows.
- `[n]`: the number of columns.
- `[type]`: the type of the elements of the matrix.
- `[combine]`: the `BinaryOperator` which assembles any duplicate entries with identical indices.

# Examples
```julia-repl
julia> from_lists([1,1,2,3], [1,2,2,2], [5,2,7,4])
3x2 GBMatrix{Int64} with 4 stored entries:
  [1, 1] = 5
  [1, 2] = 2
  [2, 2] = 7
  [3, 2] = 4

julia> from_lists([1,1,2,3], [1,2,2,2], [5,2,7,4], type=Float64)
3x2 GBMatrix{Float64} with 4 stored entries:
  [1, 1] = 5.0
  [1, 2] = 2.0
  [2, 2] = 7.0
  [3, 2] = 4.0

julia> from_lists([1,1,2,3], [1,2,2,2], [5,2,7,4], m=10, n=4)
10x4 GBMatrix{Int64} with 4 stored entries:
  [1, 1] = 5
  [1, 2] = 2
  [2, 2] = 7
  [3, 2] = 4

julia> A = from_lists([1,1,2,3], [1,1,2,2], [5,2,7,4], combine=Binaryop.PLUS)
3x2 GBMatrix{Int64} with 3 stored entries:
  [1, 1] = 7
  [2, 2] = 7
  [3, 2] = 4
```
"""
function from_lists(I, J, V; m = nothing, n = nothing, type = nothing, combine = Binaryop.FIRST)
    @assert length(I) == length(J) == length(V)
    if m === nothing
        m = maximum(I)
    end
    if n === nothing
        n = maximum(J)
    end
    if type === nothing
        type = eltype(V)
    elseif type !== eltype(V)
        V = convert.(type, V)
    end
    gb_type = _gb_type(type)
    m = from_type(type, m, n)

    combine_bop = _get(combine, gb_type, gb_type, gb_type)
    I = map(x->x - 1, I)
    J = map(x->x - 1, J)
    GrB_Matrix_build(m, I, J, V, length(V), combine_bop)
    return m
end

"""
    from_matrix(m)

Create a `GBMatrix` from the given `Matrix` `m`.

# Examples
```julia-repl
julia> from_matrix([1 0 2; 0 0 3; 0 1 0])
3x3 GBMatrix{Int64} with 4 stored entries:
  [1, 1] = 1
  [1, 3] = 2
  [2, 3] = 3
  [3, 2] = 1
```
"""
function from_matrix(m)
    r, c = size(m)
    res = from_type(eltype(m), r, c)

    i, j = 1, 1
    for v in m
        if !iszero(v)
            res[i, j] = v
        end
        i += 1
        if i > r
            i = 1
            j += 1
        end
    end
    return res
end

"""
    identity(type, n)

Create an identity `GBMatrix` of size `n`×`n` with the given type `type`.

# Examples
```julia-repl
julia> identity(Bool, 4)
4x4 GBMatrix{Bool} with 4 stored entries:
  [1, 1] = true
  [2, 2] = true
  [3, 3] = true
  [4, 4] = true
```
"""
function identity(type, n)
    res = from_type(type, n, n)
    for i in 1:n
        res[i,i] = one(type)
    end
    return res
end

"""
    Matrix(A::GBMatrix{T}) -> Matrix{T}

Construct a `Matrix{T}` from a `GBMatrix{T}` A.

"""
function Matrix(A::GBMatrix{T}) where T
    rows, cols = size(A)
    res = Matrix{T}(undef, rows, cols)
    
    for i in 1:rows
        for j in 1:cols
            res[i, j] = A[i, j]
        end
    end
    return res
end

function __print_sparse(io, print_elem, padding_fun, S)
    maxHeight = displaysize(io)[1] - 5              # prompt, header, ..., newline, prompt    
    tuples = zip(findnz(S)...)
    pad = padding_fun(tuples)

    if length(tuples) > maxHeight
        firstHalfCount = Int64(floor(maxHeight / 2))
        secondHalfCount = maxHeight - firstHalfCount
        
        firstHalf = Iterators.take(tuples, firstHalfCount)
        secondHalf = Iterators.drop(tuples, length(tuples) - secondHalfCount)

        print_elem(firstHalf, pad)
        println(io, "\n  ⋮")
        print_elem(secondHalf, pad)
    else
        print_elem(tuples, pad)
    end

end

function show(io::IO, M::GBMatrix)

    function _print(tuples, pad)
        count = 1
        size = length(tuples)
        for (i, j, x) in tuples
            print(io, "\n  [$(lpad(i, pad[1])), $(lpad(j, pad[2]))] = $x")
            count += 1
        end
    end

    function padding(iter)
        local last = first(Iterators.drop(iter, length(iter) - 1))
        return length(string(last[1])), length(string(last[2]))
    end
    
    __print_sparse(io, _print, padding, M)

end

function show(io::IO, ::MIME"text/plain", M::GBMatrix{T}) where T
    elem = nnz(M)
    print(io, "$(Int64(size(M, 1)))x$(Int64(size(M, 2))) GBMatrix{$(T)} ")
    print(io, "with $(elem) stored entries:")
    if elem != 0
        show(io, M)
    end
end

"""
    ==(A, B)

Check if two matrices `A` and `B` are equal.
"""
function ==(A::GBMatrix{T}, B::GBMatrix{U}) where {T,U}
    T != U && return false

    Asize = size(A)
    Anvals = nnz(A)

    Asize == size(B) || return false
    Anvals == nnz(B) || return false

    @with Binaryop.EQ, Monoids.LAND begin
        C = emult(A, B, out = from_type(Bool, Asize...))
        eq = reduce_scalar(C)
    end
    
    return eq
end

*(A::GBMatrix, B::GBMatrix) = mxm(A, B)
*(A::GBMatrix, u::GBVector) = mxv(A, u)

broadcasted(::typeof(+), A::GBMatrix, B::GBMatrix) = eadd(A, B)
broadcasted(::typeof(*), A::GBMatrix, B::GBMatrix) = emult(A, B)
broadcasted(::typeof(+), A::GBMatrix, u::GBVector) = eadd_matrix_vector(A, u)
broadcasted(::typeof(*), A::GBMatrix, u::GBVector) = emult_matrix_vector(A, u)

|>(A::GBMatrix, op::UnaryOperator) = apply(A, unaryop = op)

"""
    size(m::GBMatrix, [dim])

Return a tuple containing the dimensions of m.
Optionally you can specify a dimension to just get the length of that dimension.

# Examples
```julia-repl
julia> A = from_matrix([1 2 3; 4 5 6]);

julia> size(A)
(2, 3)

julia> size(A, 1)
2
```
"""
function size(m::GBMatrix, dim = nothing)
    if dim === nothing
        return (Int64(GrB_Matrix_nrows(m)), Int64(GrB_Matrix_ncols(m)))
    elseif dim == 1
        return Int64(GrB_Matrix_nrows(m))
    elseif dim == 2
        return Int64(GrB_Matrix_ncols(m))
    else
        error("dimension out of range")
    end
end

"""
    square(m::GBMatrix)

Return true if `m` is a square matrix.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 4 5]);

julia> square(A)
true
```
"""
function square(m::GBMatrix)
    rows, cols = size(m)
    return rows == cols
end

"""
    copy(m::GBMatrix)

Create a copy of `m`.

# Examples
```julia-repl
julia> A = from_matrix([1 0 1; 0 0 2; 2 0 1]);

julia> B = copy(A)
3x3 GBMatrix{Int64} with 5 stored entries:
  [1, 1] = 1
  [1, 3] = 1
  [2, 3] = 2
  [3, 1] = 2
  [3, 3] = 1

julia> A == B
true

julia> A === B
false
```
"""
function copy(m::GBMatrix{T}) where T
    cpy = from_type(T, size(m)...)
    GrB_Matrix_dup(cpy, m)
    return cpy
end

"""
    findnz(m::GBMatrix)

Return a tuple `(I, J, V)` where `I` and `J` are the row and column lists of the "non-zero" values in `m`,
and `V` is a list of "non-zero" values.

# Examples
```julia-repl
julia> A = from_matrix([1 2 0; 0 0 1]);

julia> findnz(A)
([1, 1, 2], [1, 2, 3], [1, 2, 1])
```
"""
function findnz(m::GBMatrix)
    I, J, V = GrB_Matrix_extractTuples(m)
    map!(x->x + 1, I, I)
    map!(x->x + 1, J, J)
    return I, J, V
end

"""
    nnz(m::GBMatrix)

Return the number of entries in a matrix `m`.

# Examples
```julia-repl
julia> A = from_matrix([1 2 0; 0 0 1]);

julia> nnz(A)
3
```
"""
function nnz(m::GBMatrix)
    return Int64(GrB_Matrix_nvals(m))
end

"""
    clear!(m::GBMatrix)

Clear all entries from a matrix `m`.

"""
function clear!(m::GBMatrix)
    GrB_Matrix_clear(m)
end

"""
    lastindex(m::GBMatrix, [d])

Return the last index of a matrix `m`. If `d` is given, return the last index of `m` along dimension `d`.

# Examples
```julia-repl
julia> A = from_matrix([1 2 0; 0 0 1]);

julia> lastindex(A)
(2, 3)

julia> lastindex(A, 2)
3
```
"""
function lastindex(m::GBMatrix, d = nothing)
    return size(m, d)
end

function setindex!(m::GBMatrix{T}, value, i::Integer, j::Integer) where T
    value = convert(T, value)
    GrB_Matrix_setElement(m, value, i - 1, j - 1)
end

setindex!(m::GBMatrix, value, i::Colon, j::Integer) = _assign_col!(m, value, j - 1, ALL)
setindex!(m::GBMatrix, value, i::Integer, j::Colon) = _assign_row!(m, value, i - 1, ALL)
setindex!(m::GBMatrix, value, i::Colon, j::Colon) = 
    _assign!(m, value, ALL, ALL)
setindex!(m::GBMatrix, value::GBMatrix, i::Colon, j::Colon) = 
    _assign_matrix!(m, value, ALL, ALL)
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Integer) = 
    _assign_col!(m, value, j - 1, _zero_based_indexes(i))
setindex!(m::GBMatrix, value, i::Integer, j::Union{UnitRange,Vector}) = 
    _assign_row!(m, value, i - 1, _zero_based_indexes(j))
setindex!(m::GBMatrix{T}, value::T, i::Union{UnitRange,Vector}, j::Union{UnitRange,Vector}) where T =
    _assign!(m, value, _zero_based_indexes(i), _zero_based_indexes(j))
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Union{UnitRange,Vector}) =
    _assign_matrix!(m, value, _zero_based_indexes(i), _zero_based_indexes(j))
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Colon) =
    _assign_matrix!(m, value, _zero_based_indexes(i), ALL)
setindex!(m::GBMatrix, value, i::Colon, j::Union{UnitRange,Vector}) =
    _assign_matrix!(m, value, ALL, _zero_based_indexes(j))


function getindex(m::GBMatrix{T}, i::Integer, j::Integer) where T
    try
        return GrB_Matrix_extractElement(m, i - 1, j - 1)
    catch e
        if e isa GraphBLASNoValueException
            return zero(T)
        else
            rethrow(e)
        end
    end
end

getindex(m::GBMatrix, i::Colon, j::Integer) = _extract_col(m, j - 1, ALL)
getindex(m::GBMatrix, i::Integer, j::Colon) = _extract_row(m, i - 1, ALL)
getindex(m::GBMatrix, i::Colon, j::Colon) = copy(m)
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Integer) = _extract_col(m, j - 1, _zero_based_indexes(i))
getindex(m::GBMatrix, i::Integer, j::Union{UnitRange,Vector}) = _extract_row(m, i - 1, _zero_based_indexes(j))
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Union{UnitRange,Vector}) =
    _extract_matrix(m, _zero_based_indexes(i), _zero_based_indexes(j))
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Colon) =
    _extract_matrix(m, _zero_based_indexes(i), ALL)
getindex(m::GBMatrix, i::Colon, j::Union{UnitRange,Vector}) =
    _extract_matrix(m, ALL, _zero_based_indexes(j))

_zero_based_indexes(i::Vector) = map!(x->x - 1, i, i)
_zero_based_indexes(i::UnitRange) = collect(i .- 1)


function LowerTriangular(A::GBMatrix)
    return select(A, TRIL)
end

function UpperTriangular(A::GBMatrix)
    return select(A, TRIU)
end

function Diagonal(A::GBMatrix)
    return reduce_vector(select(A, DIAG))
end


"""
    mxm(A::GBMatrix, B::GBMatrix; kwargs...)

Multiply two sparse matrix `A` and `B` using the `semiring`. If a `semiring` is not provided, it uses the default semiring.

# Arguments
- `A`: the first matrix.
- `B`: the second matrix.
- `[out]`: the output matrix for result.
- `[semiring]`: the semiring to use.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask`, `A` and `B`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> B = copy(A);

julia> mxm(A, B, semiring = Semirings.PLUS_TIMES)
2x2 GBMatrix{Int64} with 4 stored entries:
  [1, 1] = 7
  [1, 2] = 10
  [2, 1] = 15
  [2, 2] = 22
```
"""
function mxm(A::GBMatrix{T}, B::GBMatrix{U}; kwargs...) where {T,U}
    rowA, colA = size(A)
    rowB, colB = size(B)
    @assert colA == rowB

    out, semiring, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = from_type(T, rowA, colB)
    end

    if semiring === NULL
        semiring = g_operators.semiring
    end
    semiring_impl = _get(semiring, out.type, A.type, B.type)

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_mxm"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(semiring_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    
    return out
end

"""
    mxv(A::GBMatrix, u::GBVector; kwargs...) -> GBVector

Multiply a sparse matrix `A` times a column vector `u`.

# Arguments
- `A`: the sparse matrix.
- `u`: the column vector.
- `[out]`: the output vector for result.
- `[semiring]`: the semiring to use.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask`, `A` and `B`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> u = from_vector([1, 2]);

julia> mxv(A, u, semiring = Semirings.PLUS_TIMES)
2-element GBVector{Int64} with 2 stored entries:
  [1] = 5
  [2] = 11
```
"""
function mxv(A::GBMatrix{T}, u::GBVector{U}; kwargs...) where {T,U}
    rowA, colA = size(A)
    @assert colA == size(u)

    out, semiring, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = from_type(T, rowA)
    end

    if semiring === NULL
        semiring = g_operators.semiring
    end
    semiring_impl = _get(semiring, out.type, A.type, u.type)
    
    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_mxv"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(semiring_impl),
            _gb_pointer(A), _gb_pointer(u), _gb_pointer(desc)
            )
        )
    
    return out
end

"""
    emult(A::GBMatrix, B::GBMatrix; kwargs...)

Compute the element-wise "multiplication" of two matrices `A` and `B`, using a `Binary Operator`, a `Monoid` or a `Semiring`.
If given a `Monoid`, the additive operator of the monoid is used as the multiply binary operator.
If given a `Semiring`, the multiply operator of the semiring is used as the multiply binary operator.

# Arguments
- `A`: the first matrix.
- `B`: the second matrix.
- `[out]`: the output matrix for result.
- `[operator]`: the operator to use. Can be either a `Binary Operator`, or a `Monoid` or a `Semiring`.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask`, `A` and `B`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> B = copy(A);

julia> emult(A, B, operator = Binaryop.PLUS)
2x2 GBMatrix{Int64} with 4 stored entries:
  [1, 1] = 2
  [1, 2] = 4
  [2, 1] = 6
  [2, 2] = 8
```
"""
function emult(A::GBMatrix{T}, B::GBMatrix{U}; kwargs...) where {T,U}
    # operator: can be binaryop, monoid, semiring
    @assert size(A) == size(B)

    out, operator, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = from_type(T, size(A)...)
    end

    if operator === NULL
        operator = g_operators.binaryop
    end
    operator_impl = _get(operator, out.type, A.type, B.type)

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    suffix = split(string(typeof(operator_impl)), "_")[end]

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_eWiseMult_Matrix_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(operator_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    
    return out
end

"""
    eadd(A::GBMatrix, B::GBMatrix; kwargs...)

Compute the element-wise "addition" of two matrices `A` and `B`, using a `Binary Operator`, a `Monoid` or a `Semiring`.
If given a `Monoid`, the additive operator of the monoid is used as the add binary operator.
If given a `Semiring`, the additive operator of the semiring is used as the add binary operator.

# Arguments
- `A`: the first matrix.
- `B`: the second matrix.
- `[out]`: the output matrix for result.
- `[operator]`: the operator to use. Can be either a Binary Operator, or a Monoid or a Semiring.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask`, `A` and `B`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> B = copy(A);

julia> eadd(A, B, operator = Binaryop.TIMES)
2x2 GBMatrix{Int64} with 4 stored entries:
  [1, 1] = 1
  [1, 2] = 4
  [2, 1] = 9
  [2, 2] = 16
```
"""
function eadd(A::GBMatrix{T}, B::GBMatrix{U}; kwargs...) where {T,U}
    # operator: can be binaryop, monoid and semiring
    @assert size(A) == size(B)

    out, operator, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = from_type(T, size(A)...)
    end

    if operator === NULL
        operator = g_operators.binaryop
    end
    operator_impl = _get(operator, out.type, A.type, B.type)

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    suffix = split(string(typeof(operator_impl)), "_")[end]

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_eWiseAdd_Matrix_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(operator_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    
    return out
end

function eadd_matrix_vector(A::GBMatrix{T}, u::GBVector{T}; kwargs...) where T
    Asize = size(A)
    @assert Asize[1] == size(u)

    out, operator, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = from_type(T, size(A)...)
    end

    if mask === NULL
        mask = g_operators.mask
    end
    
    for i in 1:Asize[2]
        out[:, i] = eadd(A[:, i], u, operator = operator, mask = mask, accum = accum, desc = desc)
    end    

    return out
end

function emult_matrix_vector(A::GBMatrix{T}, u::GBVector{T}; kwargs...) where T
    Asize = size(A)
    @assert Asize[1] == size(u)

    out, operator, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = from_type(T, size(A)...)
    end

    if mask === NULL
        mask = g_operators.mask
    end
    
    for i in 1:Asize[2]
        out[:, i] = emult(A[:, i], u, operator = operator, mask = mask, accum = accum, desc = desc)
    end    

    return out
end

"""
    apply(A::GBMatrix; kwargs...)

Apply a `Unary Operator` to the entries of a matrix `A`, creating a new matrix.

# Arguments
- `A`: the sparse matrix.
- `[out]`: the output matrix for result.
- `[unaryop]`: the Unary Operator to use.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([-1 2; -3 -4]);

julia> apply(A, unaryop = Unaryop.ABS)
2x2 GBMatrix{Int64} with 4 stored entries:
  [1, 1] = 1
  [1, 2] = 2
  [2, 1] = 3
  [2, 2] = 4
```
"""
function apply(A::GBMatrix{T}; kwargs...) where T
    out, unaryop, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = from_type(T, size(A)...)
    end

    if unaryop === NULL
        unaryop = g_operators.unaryop
    end
    unaryop_impl = _get(unaryop, out.type, A.type)

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_apply"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(unaryop_impl),
            _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return out
end

"""
    apply!(A::GBMatrix; kwargs...)

Apply a `Unary Operator` to the entries of a matrix `A`.

# Arguments
- `A`: the sparse matrix.
- `[unaryop]`: the Unary Operator to use.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([-1 2; -3 -4]);

julia> apply!(A, unaryop = Unaryop.ABS);

julia> A
2x2 GBMatrix{Int64} with 4 stored entries:
  [1, 1] = 1
  [1, 2] = 2
  [2, 1] = 3
  [2, 2] = 4
```
"""
function apply!(A::GBMatrix; kwargs...)
    _, operator, mask, accum, desc = __get_args(kwargs)
    return apply(A, out = A, operator = operator, mask = mask, accum = accum, desc = desc)
end

"""
    select(A::GBMatrix, op::SelectOperator; kwargs...)

Apply a `Select Operator` to the entries of a matrix `A`.

# Arguments
- `A`: the sparse matrix.
- `op`: the `Select Operator` to use.
- `[out]`: the output matrix for result.
- `[thunk]`: optional input for the `Select Operator`.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

# TODO: insert example
```
"""
function select(A::GBMatrix{T}, op::SelectOperator; kwargs...) where T
    out, thunk, mask, accum, desc = __get_args(kwargs)
    
    if out === NULL
        out = from_type(T, size(A)...)
    end

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end
    
    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Matrix_select"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(op),
            _gb_pointer(A), _gb_pointer(thunk), _gb_pointer(desc)
            )
        )
    
    return out
end

"""
    reduce_vector(A::GBMatrix; kwargs...)

Reduce a matrix `A` to a column vector using an operator.
Normally the operator is a `Binary Operator`, in which all the three domains must be the same.
It can be used a `Monoid` as an operator. In both cases the reduction operator must be commutative and associative.

# Arguments
- `A`: the sparse matrix.
- `[out]`: the output matrix for result.
- `[operator]`: reduce operator.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> reduce_vector(A, operator = Binaryop.PLUS)
2-element GBVector{Int64} with 2 stored entries:
  [1] = 3
  [2] = 7
```
"""
function reduce_vector(A::GBMatrix{T}; kwargs...) where T
    out, operator, mask, accum, desc = __get_args(kwargs)
    
    # operator: can be binary op or monoid
    if out === NULL
        out = from_type(T, size(A, 1))
    end

    if operator === NULL
        operator = g_operators.monoid
    end
    operator_impl = _get(operator, A.type, A.type, A.type)

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    suffix = split(string(typeof(operator_impl)), "_")[end]

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_reduce_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(operator_impl),
            _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return out
end

"""
    reduce_scalar(A::GBMatrix{T}; kwargs...) -> T

Reduce a matrix `A` to a scalar, using the given `Monoid`.

# Arguments
- `A`: the sparse matrix to reduce.
- `[monoid]`: monoid to do the reduction.
- `[accum]`: optional accumulator.
- `[desc]`: descriptor for `A`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> reduce_scalar(A, monoid = Monoids.PLUS)
10
```
"""
function reduce_scalar(A::GBMatrix{T}; kwargs...) where T
    _, monoid, _, accum, desc = __get_args(kwargs)
    
    if monoid === NULL
        monoid = g_operators.monoid
    end
    monoid_impl = _get(monoid, A.type)

    if accum !== NULL
        accum = _get(accum)
    end
    
    scalar = Ref(zero(T))
    
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_reduce_" * _gb_type(T).name),
            Cint,
            (Ptr{T}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            scalar, _gb_pointer(accum), _gb_pointer(monoid_impl), _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return scalar[]
end

"""
    transpose(A::GBMatrix; kwargs...)

Transpose a matrix `A`.

# Arguments
- `A`: the sparse matrix to transpose.
- `[out]`: the output matrix for result.
- `[mask]`: optional mask.
- `[accum]`: optional accumulator.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([1 2 3; 4 5 6]);

julia> transpose(A)
3x2 GBMatrix{Int64} with 6 stored entries:
  [1, 1] = 1
  [1, 2] = 4
  [2, 1] = 2
  [2, 2] = 5
  [3, 1] = 3
  [3, 2] = 6
```
"""
function transpose(A::GBMatrix{T}; kwargs...) where T
    out, _, mask, accum, desc = __get_args(kwargs)
    
    if out === NULL
        out = from_type(T, reverse(size(A))...)
    end

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_transpose"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return out
end

adjoint(A::GBMatrix) = transpose(A)

# function transpose!(A::GBMatrix; mask = nothing, accum = nothing, desc = nothing)
#     return transpose(A, out = A, mask = mask, accum = accum, desc = desc)
# end

"""
    kron(A::GBMatrix, B::GBMatrix; kwargs...)

Compute the Kronecker product, using the given `Binary Operator`.

# Arguments
- `A`: the first matrix.
- `B`: the second matrix.
- `[out]`: the output matrix for result.
- `[binaryop]`: the `Binary Operator` to use.
- `[mask]`: optional mask.
- `[accum]`: optional accumulator.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix[1 2; 3 4]);

julia> B = copy(A)

julia> Matrix(kron(A, B, binaryop = Binaryop.TIMES))
4×4 Array{Int64,2}:
 1   2   2   4
 3   4   6   8
 3   6   4   8
 9  12  12  16
```
"""
function kron(A::GBMatrix{T}, B::GBMatrix{U}; kwargs...) where {T,U}
    out, binaryop, mask, accum, desc = __get_args(kwargs)
    
    if out === NULL
        out = from_type(T, size(A) .* size(B)...)
    end

    if binaryop === NULL
        binaryop = g_operators.binaryop
    end
    binaryop_impl = _get(binaryop, out.type, A.type, B.type)

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_kron"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(binaryop_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    
    return out
end

function __extract_col__(A::GBMatrix{T}, col, pointer_rows, ni; out = NULL, mask = NULL, accum = NULL, desc = NULL) where T
    @assert ni > 0

    if out === NULL
        out = from_type(T, ni)
    end

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Col_extract"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum),
            _gb_pointer(A), pointer_rows, ni, col, _gb_pointer(desc)
            )
        )
    
    return out
end

function _extract_col(A::GBMatrix, col, rows::GAllTypes; out = NULL, mask = NULL, accum = NULL, desc = NULL)
    return __extract_col__(A, col, rows.p, size(A, 1), out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_col(A::GBMatrix, col, rows::Vector{I}; out = NULL, mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    return __extract_col__(A, col, pointer(rows), length(rows), out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_row(A::GBMatrix, row, cols; out = NULL, mask = NULL, accum = NULL)
    tran_descriptor = descriptor(inp0 => tran)
    return _extract_col(A, row, cols, out = out, mask = mask, accum = accum, desc = tran_descriptor)
end

function __extract_matrix__(A::GBMatrix{T}, pointer_rows, pointer_cols, ni, nj; out = NULL, mask = NULL, accum = NULL, desc = NULL) where T
    @assert ni > 0 && nj > 0

    if out === NULL
        out = from_type(T, ni, nj)
    end

    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_extract"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(A),
            pointer_rows, ni, pointer_cols, nj, _gb_pointer(desc)
            )
        )
    
    return out
end

function _extract_matrix(A::GBMatrix, rows::Vector{I}, cols::Vector{I}; out = NULL, mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    return __extract_matrix__(A, pointer(rows), pointer(cols), length(rows), length(cols), out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_matrix(A::GBMatrix, rows::GAllTypes, cols::Vector{I}; out = NULL, mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    return __extract_matrix__(A, rows.p, pointer(cols), size(A, 1), length(cols), out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_matrix(A::GBMatrix, rows::Vector{I}, cols::GAllTypes; out = NULL, mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    return __extract_matrix__(A, pointer(rows), cols.p, length(rows), size(A, 2), out = out, mask = mask, accum = accum, desc = desc)
end

function _assign_row!(A::GBMatrix, u::GBVector, row::I, cols::Union{Vector{I},GAllTypes}; mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}    
    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Row_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(u),
            row, pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
    nothing
end

function _assign_col!(A::GBMatrix, u::GBVector, col::I, rows::Union{Vector{I},GAllTypes}; mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Col_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cuintmax_t}, Cuintmax_t, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(u),
            pointer(rows), length(rows), col, _gb_pointer(desc)
            )
        )
    nothing
end

function _assign!(A::GBMatrix, value, rows, cols; mask=NULL, accum=NULL, desc=NULL)
    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end
    
    GrB_assign(A, value, rows, cols, mask, accum, desc)
end

function _assign_matrix!(A::GBMatrix, B::GBMatrix, rows::Union{Vector{I},GAllTypes}, cols::Union{Vector{I},GAllTypes}; mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    if accum !== NULL
        accum = _get(accum)
    end

    if mask === NULL
        mask = g_operators.mask
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Matrix_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(B),
            pointer(rows), length(rows), pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
    nothing
end

function _free(A::GBMatrix)
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_free"),
            Cint,
            (Ptr{Cvoid},),
            pointer_from_objref(A)
            )
)
end
  
_gb_pointer(m::GBMatrix) = m.p
