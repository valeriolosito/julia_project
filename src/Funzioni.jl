module Funzioni
using SuiteSparseGraphBLAS, LinearAlgebra

export createM2, createM1, getMatrixVV, getMatrixVE, getMatrixVF, getMatrixEV, getMatrixEE, getMatrixEF, getMatrixFV, getMatrixFE, getMatrixFF

"""
    createM2(l, t)

Create an M2 matrix that has the faces on the rows and the vertices on the columns.
    
# Arguments:
- `l`: the faces list of object
- `t`: the number of vertices.
    
# Examples:
```julia-repl
julia> createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)
6×8 Array{Int64,2}:
    1  0  1  0  1  0  1  0
    0  0  1  1  0  0  1  1
    0  0  0  0  1  1  1  1
    0  1  0  1  0  1  0  1
    1  1  1  1  0  0  0  0
    1  1  0  0  1  1  0  0
```
"""
 function createM2(listFaces, tot::Int64)
   matrix = zeros(Int64, length(listFaces), tot)
   for i in 1:length(listFaces)
     vector = zeros(Int64,tot)
     currentList = listFaces[i]
     for j in 1:length(currentList)
      value = currentList[j]
      vector[value] = 1
     end
     matrix[i,:] = vector
   end
   return matrix
  end
  
"""
    createM1(m)

Create an M1 matrix that has the edges on the rows and the vertices on the columns.
    
# Arguments:
- `m`: the M2 matrix of faces
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> createM1(matrixM2)
12×8 Array{Int64,2}:
     0  0  1  0  0  0  1  0
     0  0  0  0  1  0  1  0
     1  0  1  0  0  0  0  0
     1  0  0  0  1  0  0  0
     0  0  0  0  0  0  1  1
     0  0  0  1  0  0  0  1
     0  0  1  1  0  0  0  0
     0  0  0  0  0  1  0  1
     0  0  0  0  1  1  0  0
     0  1  0  1  0  0  0  0
     0  1  0  0  0  1  0  0
     1  1  0  0  0  0  0  0
```
"""
  function createM1(matrixM2)
   size2 = size(matrixM2)[1]
   vectorEdges = Any[]
   matrixA2 = matrixM2 * transpose(matrixM2)
   for i in 1:size2
    for j in 2:size2
     if(i<j && matrixA2[i,j] >= 2)
      row_i = matrixM2[i,:]
      row_j = matrixM2[j,:]
      intersect = intersection(row_i, row_j) 
      push!(vectorEdges, intersect)
     end
    end
   end   
   matrix = zeros(Int64, length(vectorEdges), length(vectorEdges[1]))
   for i in 1:length(vectorEdges)
    matrix[i, :] = vectorEdges[i]
   end
   return matrix
  end
  
  function intersection(row_i, row_j)
   if(length(row_i) == length(row_j))
    size = length(row_i)
    result = zeros(Int64,size)
    for i in 1:size
     value_i = row_i[i]
     value_j = row_j[i]
     if(value_i == value_j)
      if(value_i > 1)
       result[i] = 1
      else
       result[i] = value_i
      end
     end
    end
    return result     
   end
  end
  
  function filteringProcedure(leftMatrix, resultMatrix)
    count = size(leftMatrix,1)
    for i in 1:count
     row = leftMatrix[i, :]
     k = getK(row)     
     for j in 1:size(resultMatrix,2)
      if(resultMatrix[i,j] == k)
       resultMatrix[i,j] = 1
      else
       resultMatrix[i,j] = 0
      end
     end     
    end
    return resultMatrix
  end
   
  function getK(row)
    count = 0
    for i in 1:length(row)
     count = count + row[i]
    end
    return count
  end
  
"""
    getMatrixVV(m)
Create a VV `GBMatrix` that has the vertices on the rows and the vertex on the columns from an M1 matrix.
    
# Arguments:
- `m`: the M1 matrix of edges
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> matrixM1 = createM1(matrixM2)

julia> getMatrixVV(matrixM1) 
8x8 GBMatrix{Int64} with 32 stored entries:
  [1, 1] = 1
  [1, 2] = 0
  [1, 3] = 0
  [1, 4] = 0
  [1, 5] = 0
  [1, 6] = 0
  [1, 7] = 0
  [1, 8] = 0
  [2, 1] = 0
  [2, 2] = 1
  [2, 3] = 0
  [2, 4] = 0
  [2, 5] = 0
  [2, 6] = 0
  [2, 7] = 0
  [2, 8] = 0
  ⋮

  [6, 8] = 0
  [7, 1] = 0
  [7, 2] = 0
  [7, 3] = 0
  [7, 4] = 0
  [7, 5] = 0
  [7, 6] = 0
  [7, 7] = 1
  [7, 8] = 0
  [8, 1] = 0
  [8, 2] = 0
  [8, 3] = 0
  [8, 4] = 0
  [8, 5] = 0
  [8, 6] = 0
  [8, 7] = 0
  [8, 8] = 1
```
"""  
  function getMatrixVV(M1)
  	transposeM1 = transpose(M1)
 	result = mxm(from_matrix(transposeM1), from_matrix(M1))
 	return filteringProcedure(transposeM1,result)
  end

"""
    getMatrixVE(m)
Create a VE `GBMatrix` that has the vertices on the rows and the edges on the columns from an M1 matrix.
    
# Arguments:
- `m`: the M1 matrix of edges
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> matrixM1 = createM1(matrixM2)

julia> getMatrixVE(matrixM1) 
8x12 GBMatrix{Int64} with 24 stored entries:
  [1, 3] = 1
  [1, 4] = 1
  [1, 12] = 1
  [2, 10] = 1
  [2, 11] = 1
  [2, 12] = 1
  [3, 1] = 1
  [3, 3] = 1
  [3, 7] = 1
  [4, 6] = 1
  [4, 7] = 1
  [4, 10] = 1
  [5, 2] = 1
  [5, 4] = 1
  [5, 9] = 1
  [6, 8] = 1
  [6, 9] = 1
  [6, 11] = 1
  [7, 1] = 1
  [7, 2] = 1
  [7, 5] = 1
  [8, 5] = 1
  [8, 6] = 1
  [8, 8] = 1
```
""" 
  function getMatrixVE(M1) 
 	return from_matrix(transpose(M1))
  end

"""
    getMatrixVF(m)
Create a VF `GBMatrix` that has the vertices on the rows and the faces on the columns from an M2 matrix.
    
# Arguments:
- `m`: the M2 matrix of faces
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> getMatrixVF(matrixM2)
8x6 GBMatrix{Int64} with 24 stored entries:
  [1, 1] = 1
  [1, 5] = 1
  [1, 6] = 1
  [2, 4] = 1
  [2, 5] = 1
  [2, 6] = 1
  [3, 1] = 1
  [3, 2] = 1
  [3, 5] = 1
  [4, 2] = 1
  [4, 4] = 1
  [4, 5] = 1
  [5, 1] = 1
  [5, 3] = 1
  [5, 6] = 1
  [6, 3] = 1
  [6, 4] = 1
  [6, 6] = 1
  [7, 1] = 1
  [7, 2] = 1
  [7, 3] = 1
  [8, 2] = 1
  [8, 3] = 1
  [8, 4] = 1
```
"""  
  function getMatrixVF(M2) 
 	return from_matrix(transpose(M2))
  end
  
"""
    getMatrixEV(m) 
Create a EV `GBMatrix` that has the edges on the rows and the vertices on the columns from an M1 matrix.
    
# Arguments:
- `m`: the M1 matrix of edges
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> matrixM1 = createM1(matrixM2)

julia> getMatrixEV(matrixM1)
12x8 GBMatrix{Int64} with 24 stored entries:
  [ 1, 3] = 1
  [ 1, 7] = 1
  [ 2, 5] = 1
  [ 2, 7] = 1
  [ 3, 1] = 1
  [ 3, 3] = 1
  [ 4, 1] = 1
  [ 4, 5] = 1
  [ 5, 7] = 1
  [ 5, 8] = 1
  [ 6, 4] = 1
  [ 6, 8] = 1
  [ 7, 3] = 1
  [ 7, 4] = 1
  [ 8, 6] = 1
  [ 8, 8] = 1
  [ 9, 5] = 1
  [ 9, 6] = 1
  [10, 2] = 1
  [10, 4] = 1
  [11, 2] = 1
  [11, 6] = 1
  [12, 1] = 1
  [12, 2] = 1
```
""" 
  function getMatrixEV(M1) 
 	return from_matrix(M1)
  end

"""
    getMatrixEE(m)
Create a EE `GBMatrix` that has the edges on the rows and columns from an M1 matrix.
    
# Arguments:
- `m`: the M1 matrix of edges
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> matrixM1 = createM1(matrixM2)

julia> getMatrixEE(matrixM1)
12x12 GBMatrix{Int64} with 60 stored entries:
  [ 1,  1] = 1
  [ 1,  2] = 0
  [ 1,  3] = 0
  [ 1,  4] = 0
  [ 1,  5] = 0
  [ 1,  6] = 0
  [ 1,  7] = 0
  [ 1,  8] = 0
  [ 1,  9] = 0
  [ 1, 10] = 0
  [ 1, 11] = 0
  [ 1, 12] = 0
  [ 2,  1] = 0
  [ 2,  2] = 1
  [ 2,  3] = 0
  [ 2,  4] = 0
  ⋮

  [11,  8] = 0
  [11,  9] = 0
  [11, 10] = 0
  [11, 11] = 1
  [11, 12] = 0
  [12,  1] = 0
  [12,  2] = 0
  [12,  3] = 0
  [12,  4] = 0
  [12,  5] = 0
  [12,  6] = 0
  [12,  7] = 0
  [12,  8] = 0
  [12,  9] = 0
  [12, 10] = 0
  [12, 11] = 0
  [12, 12] = 1
```
"""  
  function getMatrixEE(M1)
 	transposeM1 = transpose(M1)
 	result = mxm(from_matrix(M1), from_matrix(transposeM1))
 	return filteringProcedure(M1,result)
  end

"""
    getMatrixEF(m,n)
Create a EF `GBMatrix` that has the edges on the rows and the faces on the columns from M1 and M2 matrices.
    
# Arguments:
- `m`: the M1 matrix of edges
- `n`: the M2 matrix of faces
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> matrixM1 = createM1(matrixM2)

julia> getMatrixEF(matrixM1,matrixM2)
12x6 GBMatrix{Int64} with 48 stored entries:
  [ 1, 1] = 1
  [ 1, 2] = 1
  [ 1, 3] = 0
  [ 1, 4] = 0
  [ 1, 5] = 0
  [ 1, 6] = 0
  [ 2, 1] = 1
  [ 2, 2] = 0
  [ 2, 3] = 1
  [ 2, 4] = 0
  [ 2, 5] = 0
  [ 2, 6] = 0
  [ 3, 1] = 1
  [ 3, 2] = 0
  [ 3, 3] = 0
  [ 3, 4] = 0
  ⋮

  [10, 2] = 0
  [10, 3] = 0
  [10, 4] = 1
  [10, 5] = 1
  [10, 6] = 0
  [11, 1] = 0
  [11, 2] = 0
  [11, 3] = 0
  [11, 4] = 1
  [11, 5] = 0
  [11, 6] = 1
  [12, 1] = 0
  [12, 2] = 0
  [12, 3] = 0
  [12, 4] = 0
  [12, 5] = 1
  [12, 6] = 1
```
"""  
  function getMatrixEF(M1,M2)
 	transposeM2 = transpose(M2)
 	result = mxm(from_matrix(M1), from_matrix(transposeM2))
 	return filteringProcedure(M1,result)
  end

"""
    getMatrixFV(m)
Create a FV `GBMatrix` that has the faces on the rows and the vertices on the columns from an M2 matrix.
    
# Arguments:
- `m`: the M2 matrix of faces
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> getMatrixFV(matrixM2)
6x8 GBMatrix{Int64} with 24 stored entries:
  [1, 1] = 1
  [1, 3] = 1
  [1, 5] = 1
  [1, 7] = 1
  [2, 3] = 1
  [2, 4] = 1
  [2, 7] = 1
  [2, 8] = 1
  [3, 5] = 1
  [3, 6] = 1
  [3, 7] = 1
  [3, 8] = 1
  [4, 2] = 1
  [4, 4] = 1
  [4, 6] = 1
  [4, 8] = 1
  [5, 1] = 1
  [5, 2] = 1
  [5, 3] = 1
  [5, 4] = 1
  [6, 1] = 1
  [6, 2] = 1
  [6, 5] = 1
  [6, 6] = 1
```
"""
  function getMatrixFV(M2)
 	return from_matrix(M2)
  end

"""
    getMatrixFE(m,n)
Create a FE `GBMatrix` that has the faces on the rows and the edges on the columns from M1 and M2 matrices.
    
# Arguments:
- `m`: the M1 matrix of edges
- `n`: the M2 matrix of faces
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> matrixM1 = createM1(matrixM2)

julia> getMatrixFE(matrixM1,matrixM2)
6x12 GBMatrix{Int64} with 48 stored entries:
  [1,  1] = 0
  [1,  2] = 0
  [1,  3] = 0
  [1,  4] = 0
  [1,  5] = 0
  [1,  6] = 0
  [1,  7] = 0
  [1,  8] = 0
  [1,  9] = 0
  [1, 10] = 0
  [1, 11] = 0
  [1, 12] = 0
  [2,  1] = 0
  [2,  2] = 0
  [2,  3] = 0
  [2,  4] = 0
  ⋮

  [5,  8] = 0
  [5,  9] = 0
  [5, 10] = 0
  [5, 11] = 0
  [5, 12] = 0
  [6,  1] = 0
  [6,  2] = 0
  [6,  3] = 0
  [6,  4] = 0
  [6,  5] = 0
  [6,  6] = 0
  [6,  7] = 0
  [6,  8] = 0
  [6,  9] = 0
  [6, 10] = 0
  [6, 11] = 0
  [6, 12] = 0
```
"""
  function getMatrixFE(M1,M2)
 	transposeM1 = transpose(M1)
 	result = mxm(from_matrix(M2), from_matrix(transposeM1))
 	return filteringProcedure(M2,result)
  end

"""
    getMatrixFF(m)
Create a FF `GBMatrix` that has the faces on the rows and the columns from an M2 matrix.
    
# Arguments:
- `m`: the M2 matrix of faces
    
# Examples:
```julia-repl
julia> matrixM2 = createM2([[1, 5, 7, 3], [4, 3, 7, 8], [8, 7, 5, 6],[6, 2, 4, 8],[2, 1, 3, 4],[6, 5, 1, 2]], 8)

julia> getMatrixFF(matrixM2)
6x6 GBMatrix{Int64} with 30 stored entries:
  [1, 1] = 1
  [1, 2] = 0
  [1, 3] = 0
  [1, 4] = 0
  [1, 5] = 0
  [1, 6] = 0
  [2, 1] = 0
  [2, 2] = 1
  [2, 3] = 0
  [2, 4] = 0
  [2, 5] = 0
  [2, 6] = 0
  [3, 1] = 0
  [3, 2] = 0
  [3, 3] = 1
  [3, 4] = 0
  ⋮

  [4, 2] = 0
  [4, 3] = 0
  [4, 4] = 1
  [4, 5] = 0
  [4, 6] = 0
  [5, 1] = 0
  [5, 2] = 0
  [5, 3] = 0
  [5, 4] = 0
  [5, 5] = 1
  [5, 6] = 0
  [6, 1] = 0
  [6, 2] = 0
  [6, 3] = 0
  [6, 4] = 0
  [6, 5] = 0
  [6, 6] = 1
```
"""
  function getMatrixFF(M2) 
	 transposeM2 = transpose(M2)
	 result = mxm(from_matrix(M2), from_matrix(transposeM2))
 	 return filteringProcedure(M2, result)
  end

  function main()
    f1 = [ 1, 5, 7, 3]
    f2 = [ 4, 3, 7, 8]
    f3 = [ 8, 7, 5, 6]
    f4 = [ 6, 2, 4, 8]
    f5 = [ 2, 1, 3, 4]
    f6 = [ 6, 5, 1, 2]
    listFaces = [ f1, f2, f3, f4, f5, f6]

    tot = 8
    
    matrixM2 = createM2(listFaces, tot)
 
    f1 = [1, 0, 1, 0, 1, 0, 1, 0]
    f2 = [0, 0, 1, 1, 0, 0, 1, 1]
    f3 = [0, 0, 0, 0, 1, 1, 1, 1]
    f4 = [0, 1, 0, 1, 0, 1, 0, 1]
    f5 = [1, 1, 1, 1, 0, 0, 0, 0]
    f6 = [1, 1, 0, 0, 1, 1, 0, 0]
    list = [f1, f2, f3, f4, f5, f6]
    
    #OGGETTO STRAMBO
    #=
    tot = 16

    f1 = [ 16, 2, 4]
    f2 = [ 2, 1, 3, 4]
    f3 = [ 1, 11, 3]
    f4 = [ 16, 4, 6]
    f5 = [ 4, 3, 5, 6]
    f6 = [ 3, 11, 5]
    f7 = [ 16, 6, 8]
    f8 = [ 6, 5, 7, 8]
    f9 = [ 5, 11, 7]
    f10 = [ 16, 8, 10]
    f11 = [ 8, 7, 9, 10]
    f12 = [ 7, 11, 9]
    f13 = [ 16, 10, 13]
    f14 = [ 10, 9, 12, 13]
    f15 = [ 9, 11, 12]
    f16 = [ 16, 13, 15]
    f17 = [ 13, 12, 14, 15]
    f18 = [ 12, 11, 14]
    f19 = [ 16, 15, 2]
    f20 = [ 15, 14, 1, 2]
    f21 = [ 14, 11, 1]
    
    
    listFaces = [f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15,f16,f17,f18,f19,f20,f21]
    =#
            
    matrixM1 = createM1(matrixM2) 
	
	   
    matrixVV = getMatrixVV(matrixM1)
    matrixVE = getMatrixVE(matrixM1)
    matrixVF = getMatrixVF(matrixM2)
    matrixEV = getMatrixEV(matrixM1)
    matrixEE = getMatrixEE(matrixM1)
    matrixEF = getMatrixEF(matrixM1, matrixM2)
    matrixFV = getMatrixFV(matrixM2)
    matrixFE = getMatrixFE(matrixM1, matrixM2)  
    matrixFF = getMatrixFF(matrixM2)    
   end
end
