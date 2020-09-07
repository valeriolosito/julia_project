import Base: show

"""
    monoid(bin_op, identity; [name])

Create a `Monoid` from the associative `Binary Operator` `bin_op` and the `identity` value.
If a `name` is provided, the `Monoid` is inserted in the global variable `Monoids`.

# Examples
```julia-repl
julia> binaryop = binaryop((a, b) -> a÷b);

julia> monoid = monoid(binaryop, 1, name=:DIV_MONOID);

julia> monoid === Monoids.DIV_MONOID
true
```
"""
function monoid(bin_op::BinaryOperator, identity::T; name::Union{Symbol,Nothing} = nothing) where T
    domain = _gb_type(T)
    if name !== nothing
        if hasproperty(Monoids, name)
            monoid = getproperty(Monoids, name)
        else
            monoid = Monoid(string(name))
            @eval(Monoids, $name = $monoid)
            @eval(Monoids, export $name)
        end
    else
        monoid = Monoid(string(name))
    end
    index = findfirst(mon->mon.domain == domain, monoid.impl)
    if index === nothing
        # create a new monoid
        bop = _get(bin_op, domain, domain, domain)
        mon = _monoid_new(bop, identity)
        push!(monoid.impl, mon)
    end
    return monoid
end

function _get(monoid::Monoid, types...)
    (domain,) = types
    index = findfirst(mon->mon.domain == domain, monoid.impl)
    if index === nothing
        error("monoid not find")
    end
    return monoid.impl[index]
end

function load_builtin_monoid()

    function load(lst)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype[string(bpn[end - 1])]
            
            monoid_name = Symbol(join(bpn[2:end - 2], "_"))
            if hasproperty(Monoids, monoid_name)
                monoid = getproperty(Monoids, monoid_name)
            else
                monoid = Monoid(string(monoid_name))
                @eval(Monoids, $monoid_name = $monoid)
                @eval(Monoids, export $monoid_name)
            end
            push!(monoid.impl, GrB_Monoid(op, type))
        end
    end

    grb_mon = compile(["GxB"],
    ["MIN", "MAX", "PLUS", "TIMES"],
    ["UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"],
    ["MONOID"])

    grb_mon_bool = compile(["GxB"],
    ["LOR", "LAND", "LXOR", "EQ"],
    ["BOOL"],
    ["MONOID"])

    load(cat(grb_mon, grb_mon_bool, dims = 1))

end

function _monoid_new(binary_op::GrB_BinaryOp, identity::T) where T
    monoid = GrB_Monoid()
    monoid.domain = _gb_type(T)

    monoid_ptr = pointer_from_objref(monoid)
    fn_name = "GrB_Monoid_new_" * _gb_type(T).name

    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Cintmax_t),
            monoid_ptr,
            _gb_pointer(binary_op),
            identity
            )
        )
    return monoid
end

function __enter__(mon::Monoid)
    global g_operators
    old = g_operators.monoid
    g_operators = Base.setindex(g_operators, mon, :monoid)
    return (monoid = old,)
end

show(io::IO, mon::Monoid) = print(io, "Monoid($(mon.name))")

baremodule Monoids
    # to fill with built in and user defined monoids
end