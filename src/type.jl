import Base: pointer, length

struct GType{T}
    jtype::DataType
    gbtype::Ptr{Cvoid}
    name::String

    GType{T}(name) where T = new{T}(T, load_global("GrB_" * name), name)
    GType() = new{Nothing}(Nothing, C_NULL, "NULL")
end

struct GAllTypes
    p::Ptr{Cvoid}
end

_gb_pointer(t::GType) = t.gbtype
_gb_pointer(t::GAllTypes) = t.p

function load_gbtypes()

    global BOOL = GType{Bool}("BOOL")
    global INT8 = GType{Int8}("INT8")
    global INT16 = GType{Int16}("INT16")
    global INT32 = GType{Int32}("INT32")
    global INT64 = GType{Int64}("INT64")
    global UINT8 = GType{UInt8}("UINT8")
    global UINT16 = GType{UInt16}("UINT16")
    global UINT32 = GType{UInt32}("UINT32")
    global UINT64 = GType{UInt64}("UINT64")
    global FP32 = GType{Float32}("FP32")
    global FP64 = GType{Float64}("FP64")
    global NULL = GType()

    global ALL = GAllTypes(load_global("GrB_ALL"))

    global str2gtype = Dict("BOOL"=>BOOL, "INT8"=>INT8, "INT16"=>INT16, "INT32"=>INT32, "INT64"=>INT64,
                        "UINT8"=>UINT8, "UINT16"=>UINT16, "UINT32"=>UINT32, "UINT64"=>UINT64,
                        "FP32"=>FP32, "FP64"=>FP64)

end

_gb_type(::Type{Bool}) = BOOL
_gb_type(::Type{Int8}) = INT8
_gb_type(::Type{Int16}) = INT16
_gb_type(::Type{Int32}) = INT32
_gb_type(::Type{Int64}) = INT64
_gb_type(::Type{UInt8}) = UINT8
_gb_type(::Type{UInt16}) = UINT16
_gb_type(::Type{UInt32}) = UINT32
_gb_type(::Type{UInt64}) = UINT64
_gb_type(::Type{Float32}) = FP32
_gb_type(::Type{Float64}) = FP64
_gb_type(_) = NULL

pointer(t::GAllTypes) = t.p
length(t::GAllTypes) = 0     # dummy length

# function suffix(T::DataType)
#     if T == Bool
#         return "BOOL"
#     elseif T == Int8
#         return "INT8"
#     elseif T == UInt8
#         return "UINT8"
#     elseif T == Int16
#         return "INT16"
#     elseif T == UInt16
#         return "UINT16"
#     elseif T == Int32
#         return "INT32"
#     elseif T == UInt32
#         return "UINT32"
#     elseif T == Int64
#         return "INT64"
#     elseif T == UInt64
#         return "UINT64"
#     elseif T == Float32
#         return "FP32"
#     else
#         return "FP64"
#     end
# end

# function jtype(T::String)
#     if T == "BOOL"
#         return Bool
#     elseif T == "INT8"
#         return Int8
#     elseif T == "UINT8"
#         return UInt8
#     elseif T == "INT16"
#         return Int16
#     elseif T == "UINT16"
#         return UInt16
#     elseif T == "INT32"
#         return Int32
#     elseif T == "UINT32"
#         return UInt32
#     elseif T == "INT64"
#         return Int64
#     elseif T == "UINT64"
#         return UInt64
#     elseif T == "FP32"
#         return Float32
#     else
#         return Float64
#     end
# end

# function str2gtype(T::String)
#     if T == "BOOL"
#         return BOOL
#     elseif T == "INT8"
#         return INT8
#     elseif T == "UINT8"
#         return UINT8
#     elseif T == "INT16"
#         return INT16
#     elseif T == "UINT16"
#         return UINT16
#     elseif T == "INT32"
#         return INT32
#     elseif T == "UINT32"
#         return UINT32
#     elseif T == "INT64"
#         return INT64
#     elseif T == "UINT64"
#         return UINT64
#     elseif T == "FP32"
#         return FP32
#     else
#         return FP64
#     end
# end

# function j2gtype(T)
#     return str2gtype(suffix(T))
# end