import Base: show

@enum DescriptorField outp mask inp0 inp1
@enum DescriptorValue default replace scmp tran

function descriptor(values...)
    desc = Descriptor()
    _descriptor_new(desc)

    # set descriptor fields
    for (field, value) in values
        _descriptor_set(desc, field, value)
    end

    finalizer(_free, desc)
    return desc
end

function _descriptor_new(desc::Descriptor)
    desc_ptr = pointer_from_objref(desc)

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Descriptor_new"),
            Cint,
            (Ptr{Cvoid},),
            desc_ptr
            )
        )
end

"""
    GrB_Descriptor_set(desc, field, val)

Set the content for a field for an existing descriptor.
"""
function _descriptor_set(desc::Descriptor, field::DescriptorField, val::DescriptorValue)
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Descriptor_set"),
            Cint,
            (Ptr{Cvoid}, Cint, Cint),
            _gb_pointer(desc), field, val
            )
        )
end

function _descriptor_get(desc::Descriptor, field)
    element = Ref(Int64(0))
    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Desc_get"),
            Cint,
            (Ptr{Cvoid}, Cint, Ptr{Cvoid}),
            _gb_pointer(desc), field, element,
            )
        )

    return element[]
end

function _free(A::Descriptor)
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Descriptor_free"),
            Cint,
            (Ptr{Cvoid},),
            pointer_from_objref(A)
            )
        )
end

Base.show(io::IO, x::Descriptor) = print(io, "Descriptor")

function Base.show(io::IO, m::MIME"text/plain", desc::Descriptor)
    print(io, "Descriptor:\n")
    
    for field in 0:DescriptorField.size-1
        print(io, "\t$(DescriptorField(field)) => $(DescriptorValue(_descriptor_get(desc, field)))")
        if field != DescriptorField.size-1
            println()
        end
    end
end