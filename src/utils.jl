struct GraphBLASNoValueException <: Exception end
struct GraphBLASUninitializedObjectException <: Exception end
struct GraphBLASInvalidObjectException <: Exception end
struct GraphBLASNullPointerException <: Exception end
struct GraphBLASInvalidValueException <: Exception end
struct GraphBLASInvalidIndexException <: Exception end
struct GraphBLASDomainMismatchException <: Exception end
struct GraphBLASDimensionMismatchException <: Exception end
struct GraphBLASOutputNotEmptyException <: Exception end
struct GraphBLASOutOfMemoryException <: Exception end
struct GraphBLASInsufficientSpaceException <: Exception end
struct GraphBLASIndexOutOfBoundException <: Exception end
struct GraphBLASPanicException <: Exception end

function compile(lst...)
    res = String[]
    if length(lst) == 1
        return lst[1]
    else
        r = compile(lst[2:end]...)
        for e in r
            for l in lst[1]
                push!(res, "$(l)_$(e)")
            end
        end
        return res
    end
end

function __get_args(kwargs)
    out, operator, mask, accum, desc = NULL, NULL, NULL, NULL, NULL
    for arg in kwargs
        if arg[1] == :out
            out = arg[2]
        elseif arg[1] == :unaryop || arg[1] == :binaryop || arg[1] == :thunk ||
            arg[1] == :semiring || arg[1] == :monoid || arg[1] == :operator
            operator = arg[2]
        elseif arg[1] == :mask
            mask = arg[2]
        elseif arg[1] == :accum
            accum = arg[2]
        elseif arg[1] == :desc
            desc = arg[2]
        end
    end
    return out, operator, mask, accum, desc
end

function check(info)
    if info == 1        # NO_VALUE
        throw(GraphBLASNoValueException())
    elseif info == 2    # UNINITIALIZED_OBJECT
        throw(GraphBLASUninitializedObjectException())
    elseif info == 3    # INVALID_OBJECT
        throw(GraphBLASInvalidObjectException())
    elseif info == 4    # NULL_POINTER
        throw(GraphBLASNullPointerException())
    elseif info == 5    # GrB_INVALID_VALUE
        throw(GraphBLASInvalidValueException())
    elseif info == 6    # GrB_INVALID_INDEX
        throw(GraphBLASInvalidIndexException())
    elseif info == 7    # DOMAIN_MISMATCH
        throw(GraphBLASDomainMismatchException())
    elseif info == 8    # DIMENSION_MISMATCH
        throw(GraphBLASDimensionMismatchException())
    elseif info == 9    # OUTPUT_NOT_EMPTY
        throw(GraphBLASOutputNotEmptyException())
    elseif info == 10   # OUT_OF_MEMORY
        throw(GraphBLASOutOfMemoryException())
    elseif info == 11   # INSUFFICIENT_SPACE
        throw(GraphBLASInsufficientSpaceException())
    elseif info == 12   # INDEX_OUT_OF_BOUNDS
        throw(GraphBLASIndexOutOfBoundException())
    elseif info == 13   # PANIC
        throw(GraphBLASPanicException())
    end
end

function load_global(str)
    x = dlsym(graphblas_lib, str)
    return unsafe_load(cglobal(x, Ptr{Cvoid}))
end

function gbtype_from_jtype(T::DataType)
    return load_global("GrB_" * _gb_type(T).name)
end

function __restore__(old_op)
    global g_operators = merge(g_operators, old_op...)
    nothing
end

macro with(env, block)
    init = quote
        # change and store default operators
        old_op = []

        if !($(esc(env)) isa Tuple)
            operators = tuple($(esc(env)))
        else
            operators = $(esc(env))
        end

        for op in operators
            Base.push!(old_op, __enter__(op))
        end
        
    end

    fin = quote
        # restore default operators
        __restore__(old_op)
    end
    
    return :($init; :($$block); $fin)
end