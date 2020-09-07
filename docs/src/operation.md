```@docs
from_type(::DataType, ::Int64, ::Int64)
from_lists(::Vector, ::Vector, ::Vector)
from_matrix
identity
Matrix(::GBMatrix)
square
size(::GBMatrix)
findnz(::GBMatrix)
==(::GBMatrix, ::GBMatrix)
nnz(::GBMatrix)
clear!(::GBMatrix)
copy(::GBMatrix)
lastindex(::GBMatrix)
mxm
mxv
emult(::GBMatrix, ::GBMatrix)
eadd(::GBMatrix, ::GBMatrix)
apply(::GBMatrix)
apply!(::GBMatrix)
select(::GBMatrix, ::SelectOperator)
reduce_vector
reduce_scalar
transpose
kron
```
