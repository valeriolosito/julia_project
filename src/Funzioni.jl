module Funzioni
using SuiteSparseGraphBLAS, LinearAlgebra

export createM2, createM1, getMatrixVV, getMatrixVE, getMatrixVF, getMatrixEV, getMatrixEE, getMatrixEF, getMatrixFV, getMatrixFE, getMatrixFF

"""
    createM2(listFaces, tot::Int64)
   Create matrix M2`.
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
  
  # M1 è la matrice degli spigoli
  function getMatrixVV(M1)
  	transposeM1 = transpose(M1)
 	result = mxm(from_matrix(transposeM1), from_matrix(M1),)
 	return result
  end
  
  # M1 è la matrice degli spigoli
  function getMatrixVE(M1) 
 	return from_matrix(transpose(M1))
  end
  
  # M2 è la matrice delle facce
  function getMatrixVF(M2) 
 	return from_matrix(transpose(M2))
  end
  
  # M1 è la matrice degli spigoli
  function getMatrixEV(M1) 
 	return from_matrix(M1)
  end
  
  # M1 è la matrice degli spigoli
  function getMatrixEE(M1)
 	transposeM1 = transpose(M1)
 	result = mxm(from_matrix(M1), from_matrix(transposeM1))
 	return result
  end
  
  # M1 è la matrice degli spigoli, M2 è la matrice delle facce
  function getMatrixEF(M1,M2)
 	transposeM2 = transpose(M2)
 	result = mxm(from_matrix(M1), from_matrix(transposeM2))
 	return result
  end

  # M2 è la matrice delle facce
  function getMatrixFV(M2)
 	return from_matrix(M2)
  end

  # M1 è la matrice degli spigoli, M2 è la matrice delle facce
  function getMatrixFE(M1,M2)
 	transposeM1 = transpose(M1)
 	result = mxm(from_matrix(M2), from_matrix(transposeM1))
 	return result
  end

  # M2 è la matrice delle facce
  function getMatrixFF(M2) 
	 transposeM2 = transpose(M2)
	 result = mxm(from_matrix(M2), from_matrix(transposeM2))
	 return result
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
    
   
    #matrixM2 = createM2(listFaces, tot)
    #numRow = size(matrixM2)[1]
    matrixM3 = zeros(Int64, 6, 8)
    matrixM3[1,:] = [1 1 0 0 0 0 1 1]
    matrixM3[2,:] = [1 0 1 0 1 0 1 0]
    matrixM3[3,:] = [0 0 0 0 1 1 1 1]
    matrixM3[4,:] = [0 1 0 1 0 1 0 1]
    matrixM3[5,:] = [0 0 1 1 1 1 0 0]
    matrixM3[6,:] = [1 1 1 1 0 0 0 0]
    
    println("qui" , matrixM3)
    
    matrixM1 = createM1(matrixM3)
    println("M1 ->")
    println(matrixM1)  
  
    matrixVV = getMatrixVV(matrixM1)
    println("matrixVV")
    println(Matrix(matrixVV))
    println(matrixVV)
    
    matrixVE = getMatrixVE(matrixM1)
    println("matrixVE")
    #println( Matrix(matrixVE))
    println( matrixVE)
    
    matrixVF = getMatrixVF(matrixM2)
    println("matrixVF")
    #println(Matrix(matrixVF))
    println(matrixVF)
    
    matrixEV = getMatrixEV(matrixM1)
    println("matrixEV")
    #println( Matrix(matrixEV))
    println(matrixEV)
    
    matrixEE = getMatrixEE(matrixM1)
    println("matrixEE")
    #println(Matrix(matrixEE))
    println(matrixEE)
    
    matrixEF = getMatrixEF(matrixM1, matrixM2)
    println("matrixEF")
    #println(Matrix(matrixEF))
    println(matrixEF)
    
    matrixFV = getMatrixFV(matrixM2)
    println("matrixFV")
    #println(Matrix(matrixFV))
    println(matrixFV)
    
    matrixFE = getMatrixFE(matrixM1, matrixM2)
    println("matrixFE")
    #println(Matrix(matrixFE))
    println(matrixFE)
    
    matrixFF = getMatrixFF(matrixM2)
    println("matrixFF")
    #println(Matrix(matrixFF))
    println(matrixFF)    
  end

end
