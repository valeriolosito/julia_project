function GrB_Vector_new(v::GBVector{T}, type::GType{T}, n::Union{Int64,UInt64}) where T
    v_ptr = pointer_from_objref(v)

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_new"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t),
            v_ptr, _gb_pointer(type), n
            )
        )
end

"""
    GrB_Vector_dup(w, u)

Initialize a vector with the same domain, size, and contents as another vector.

"""
function GrB_Vector_dup(w::GBVector{T}, u::GBVector{T}) where T
    w_ptr = pointer_from_objref(w)

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_dup"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}),
            w_ptr, _gb_pointer(u)
            )
        )
end

"""
    GrB_Vector_clear(v)

Remove all the elements (tuples) from a vector.

"""
function GrB_Vector_clear(v::GBVector)
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_clear"),
            Cint,
            (Ptr{Cvoid},),
            _gb_pointer(v)
            )
        )
end

"""
    GrB_Vector_size(v)

Return the size of a vector if successful.
Else return `GrB_Info` error code.

"""
function GrB_Vector_size(v::GBVector)
    n = Ref(UInt64(0))
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_size"),
            Cint,
            (Ptr{UInt64}, Ptr{Cvoid}),
            n, _gb_pointer(v)
            )
        )
    
    return n[]
end

"""
    GrB_Vector_nvals(v)

Return the number of stored elements in a vector if successful.
Else return `GrB_Info` error code.

"""
function GrB_Vector_nvals(v::GBVector)
    nvals = Ref(UInt64(0))
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_nvals"),
            Cint,
            (Ptr{UInt64}, Ptr{Cvoid}),
            nvals, _gb_pointer(v)
            )
        )
    
    return nvals[]
end

"""
    GrB_Vector_build(w, I, X, nvals, dup)

Store elements from tuples into a vector.

"""
function GrB_Vector_build(w::GBVector{T}, I::Vector{U}, X::Vector{T}, nvals::U, dup::GrB_BinaryOp) where {T,U <: Union{Int64,UInt64}}
    I_ptr = pointer(I)
    X_ptr = pointer(X)
    fn_name = "GrB_Vector_build_" * _gb_type(T).name

    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{T}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(w), I_ptr, X_ptr, nvals, _gb_pointer(dup)
            )
        )
end

"""
    GrB_Vector_setElement(w, x, i)

Set one element of a vector to a given value, w[i] = x.

"""
function GrB_Vector_setElement(w::GBVector{T}, x::T, i::Union{Int64,UInt64}) where T
    fn_name = "GrB_Vector_setElement_" * _gb_type(T).name
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Cintmax_t, Cuintmax_t),
            _gb_pointer(w), x, i
            )
        )
end

function GrB_Vector_setElement(w::GBVector{UInt64}, x::UInt64, i::Union{Int64,UInt64})
    fn_name = "GrB_Vector_setElement_UINT64"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Cuintmax_t, Cuintmax_t),
            _gb_pointer(w), x, i
            )
        )
end

function GrB_Vector_setElement(w::GBVector{Float32}, x::Float32, i::Union{Int64,UInt64})
    fn_name = "GrB_Vector_setElement_FP32"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Cfloat, Cuintmax_t),
            _gb_pointer(w), x, i
            )
        )
end

function GrB_assign(v::GBVector{T}, x::T, i::Union{Vector{I}, GAllTypes}, mask, accum, desc) where {T, I <: Union{Int64, UInt64}}
    suffix = _gb_type(T).name
    
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_assign_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(v), _gb_pointer(mask), _gb_pointer(accum), x,
            pointer(i), length(i), _gb_pointer(desc)
            )
        )
end

function GrB_assign(v::GBVector{UInt64}, x::UInt64, i::Union{Vector{I}, GAllTypes}, mask, accum, desc) where I <: Union{Int64, UInt64}
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_assign_UINT64"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(v), _gb_pointer(mask), _gb_pointer(accum), x,
            pointer(i), length(i), _gb_pointer(desc)
            )
        )
end

function GrB_assign(v::GBVector{Float32}, x::Float32, i::Union{Vector{I}, GAllTypes}, mask, accum, desc) where I <: Union{Int64, UInt64}
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_assign_FP32"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cfloat, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(v), _gb_pointer(mask), _gb_pointer(accum), x,
            pointer(i), length(i), _gb_pointer(desc)
            )
        )
end

function GrB_assign(v::GBVector{Float64}, x::Float64, i::Union{Vector{I}, GAllTypes}, mask, accum, desc) where I <: Union{Int64, UInt64}
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_assign_FP64"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cdouble, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(v), _gb_pointer(mask), _gb_pointer(accum), x,
            pointer(i), length(i), _gb_pointer(desc)
            )
        )
end

function GrB_Vector_setElement(w::GBVector{Float64}, x::Float64, i::Union{Int64,UInt64})
    fn_name = "GrB_Vector_setElement_FP64"
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Cdouble, Cuintmax_t),
            _gb_pointer(w), x, i
            )
        )
end

"""
    GrB_Vector_extractElement(v, i)

Return element of a vector at a given index (v[i]) if successful.
Else return `GrB_Info` error code.

"""
function GrB_Vector_extractElement(v::GBVector{T}, i::Union{Int64,UInt64}) where T
    fn_name = "GrB_Vector_extractElement_" * _gb_type(T).name

    element = Ref(T(0))
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Cintmax_t),
            element, _gb_pointer(v), i
            )
        )
    
    return element[]
end

"""
    GrB_Vector_extractTuples(v,[ index_type])

Return tuples stored in a vector if successful.
Else return `GrB_Info` error code.
Returns zero based indices by default.

"""
function GrB_Vector_extractTuples(v::GBVector{T}) where T
    nvals = GrB_Vector_nvals(v)
    
    I = Vector{Int64}(undef, nvals)
    X = Vector{T}(undef, nvals)
    n = Ref(UInt64(nvals))

    fn_name = "GrB_Vector_extractTuples_" * _gb_type(T).name
    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{UInt64}, Ptr{Cvoid}),
            pointer(I), pointer(X), n, _gb_pointer(v)
            )
        )
    
    return I, X
end
