import Base: show

"""
    semiring(add, mult; [name])

Create a `Semiring` from the commutative and associative `Monoid` `add` and the `Binary Operator` `mult`.
If a `name` is provided, the `Semiring` is inserted in the global variable `Semirings`.

# Examples
```julia-repl
julia> semiring = semiring(Monoids.LAND, Binaryop.EQ, name=:USER_DEFINED);

julia> semiring === Semirings.USER_DEFINED
true
```
"""
function semiring(add::Monoid, mult::BinaryOperator; name::Union{Symbol, Nothing} = nothing)
    if name !== nothing
        if hasproperty(Semirings, name)
            sem = getproperty(Semirings, name)
        else
            sem = Semiring(add, mult, string(name))
            @eval(Semirings, $name = $sem)
            @eval(Semirings, export $name)
        end
    else
        sem = Semiring(add, mult, string(name))
    end
    return sem
end

function _get(semiring::Semiring, types...)
    ztype, xtype, ytype = types
    index = findfirst(sem -> sem.xtype == xtype && sem.ytype == ytype && sem.ztype == ztype, semiring.impl)
    if index === nothing
        # create a semiring with given types
        if semiring.monoid !== nothing && semiring.binaryop !== nothing
            # user defined semiring
            bop = _get(semiring.binaryop, ztype, xtype, ytype)
            mon = _get(semiring.monoid, ztype)

            sem = _semiring_new(mon, bop)
            push!(semiring.impl, sem)
            return sem
        end
    else
        return semiring.impl[index]
    end
    error("cannot use semiring with xtype=$xtype, ytype=$ytype, ztype=$ztype")
end

function load_builtin_semiring()

    function load(lst; ztype = NULL)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype[string(bpn[end])]
            
            semiring_name = Symbol(join(bpn[2:end-1], "_"))

            if hasproperty(Semirings, semiring_name)
                semiring = getproperty(Semirings, semiring_name)
            else
                semiring = Semiring(string(semiring_name))
                @eval(Semirings, $semiring_name = $semiring)
                @eval(Semirings, export $semiring_name)
            end
            
            push!(semiring.impl, GrB_Semiring(op, type, type, ztype == NULL ? type : ztype))
        end
    end

    gxb_alltype = compile(["GxB"],
    ["MIN", "MAX", "PLUS", "TIMES"],
    ["FIRST", "SECOND", "MIN", "MAX", "PLUS", "MINUS", "TIMES", "DIV", "ISEQ", "ISNE", "ISGT", "ISLT", "ISGE", "ISLE", "LOR", "LAND", "LXOR"],
    ["UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_comp = compile(["GxB"],
    ["LOR", "LAND", "LXOR", "EQ"],
    ["EQ", "NE", "GT", "LT", "GE", "LE"],
    ["UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_bool = compile(["GxB"],
    ["LOR", "LAND", "LXOR", "EQ"],
    ["FIRST", "SECOND", "LOR", "LAND", "LXOR", "EQ", "GT", "LT", "GE", "LE"],
    ["BOOL"])

    load(gxb_alltype)
    load(gxb_comp, ztype = BOOL)
    load(gxb_bool)
        
end

# create a GrB_Semiring
function _semiring_new(monoid::GrB_Monoid, binary_op::GrB_BinaryOp)
    semiring = GrB_Semiring()
    semiring.xtype = binary_op.xtype
    semiring.ytype = binary_op.ytype
    semiring.ztype = binary_op.ztype
    
    semiring_ptr = pointer_from_objref(semiring)

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Semiring_new"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            semiring_ptr, _gb_pointer(monoid), _gb_pointer(binary_op)
            )
        )
    return semiring
end

function __enter__(sem::Semiring)
    global g_operators
    old = g_operators.semiring
    g_operators = Base.setindex(g_operators, sem, :semiring)
    return (semiring=old,)
end

show(io::IO, sem::Semiring) = print(io, "Semiring($(sem.name))")

baremodule Semirings
    # to fill with built in and user defined semirings
end