module Funzioni
using SuiteSparseGraphBLAS, LinearAlgebra

export createM2

 function createM2(listFaces, tot::Int64)
 
   matrix = zeros(Int64, length(listFaces), tot)
   #println("Matrix --> ", matrix)
   println("-------INIZIO-----METODO----CREATE------M2------")
   
   for i in 1:length(listFaces)
     vector = zeros(Int64,tot)
     #println("Faccia ", i , " --> ", vector)
     currentList = listFaces[i]
     #println("CurrentList --> ", currentList)
     for j in 1:length(currentList)
      #println("Elemento J --> ", j)
      value = currentList[j]
      #println("Value --> ", value)
      vector[value] = 1
     end
     #println("Vector Finale --> ", vector)
     #println()
     #println()
     matrix[i,:] = vector
     #println("Matrix Finael --> ", matrix)
     #println("-----------")
   end
   println("Matrix Finale --> ", matrix)
   println("-------FINE-----METODO----CREATE------M2------")
   return matrix
  end
  
  function createEdge(vectorSum)
   size = length(vectorSum)
   for i in 1:size
    if(vectorSum[i] != 2)
     vectorSum[i] = 0
    else
     vectorSum[i] = 1
    end
   end
   return vectorSum
  end
  
  
  function sumBetweenList(first, second)
   if(length(first) != length(second))
    return "I due vettori hanno lunghezze diverse"
   end
   size = length(first)
   index = 1
   resultSum = zeros(Int64,size)
   while index <= size
    resultSum[index] = first[index] + second[index]
    index += 1
   end
   return resultSum
  end
  
  
  function createM1(list)
   #Massimo -> va definita la matrice matrix
   
   #controllare lunghezza di tutti gli elementi di list
      
   size = length(list)
   vectorEdges = Any[]

   for i in 1:size-1
    currentList = list[i]
    for j in i+1: size
     nextList = list[j]
     sumVector = sumBetweenList(currentList, nextList)
     if (2 in sumVector)
      edge = createEdge(sumVector)
      push!(vectorEdges, edge)
      #println("Edge da inserire", edge)
      
      #Massimo -> va inserito edge in matrix
      #println("Vector Edge Parziale --> ", vectorEdges)
     end
    end
   end

   matrix = zeros(Int64, length(vectorEdges), length(vectorEdges[1]))
   for i in 1:length(vectorEdges)
   	matrix[i, :] = vectorEdges[i]
   end

   println("Matrix Finale --> ", matrix)
   println("-------FINE-----METODO----CREATE------M1------")
   return matrix
  end
  
  # M1 è la matrice degli spigoli
  function getMatrixVV(M1)
  	transposeM1 = transpose(M1)
 	result = emult(transposeM1, M1, operator = Binaryop.PLUS)
 	return result
  end
  
  # M1 è la matrice degli spigoli
  function getMatrixVE(M1) 
 	return transpose(M1)
  end
  
  # M2 è la matrice delle facce
  function getMatrixVF(M2) 
 	return transpose(M2)
  end
  
  # M1 è la matrice degli spigoli
  function getMatrixEV(M1) 
 	return M1
  end
  
  # M1 è la matrice degli spigoli
  function getMatrixEE(M1)
 	transposeM1 = transpose(M1)
 	result = emult(M1, transposeM1, operator = Binaryop.PLUS)
 	return result
  end
  
  # M1 è la matrice degli spigoli, M2 è la matrice delle facce
  function getMatrixEF(M1,M2)
 	transposeM2 = transpose(M2)
 	result = emult(M1, transposeM2, operator = Binaryop.PLUS)
 	return result
  end

  # M2 è la matrice delle facce
  function getMatrixFV(M2)
 	return M2
  end

  # M1 è la matrice degli spigoli, M2 è la matrice delle facce
  function getMatrixFE(M1,M2)
 	transposeM1 = transpose(M1)
 	result = emult(M2, transposeM1, operator = Binaryop.PLUS)
 	return result
  end

  # M2 è la matrice delle facce
  function getMatrixFF(M2) 
	 transposeM2 = transpose(M2)
	 result = emult(M2, transposeM2, operator = Binaryop.PLUS)
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
    println("Metodo Main")
    println("f1 = ", f1)
    println("f2 = ", f2)
    println("f3 = ", f3)
    println("f4 = ", f4)
    println("f5 = ", f5)
    println("f6 = ", f6)
    println()
    println("listFaces = ", listFaces)
    tot = 8
    #println("Tot = ", tot)
    
    matrixM2 = createM2(listFaces, tot)
    
    #first = [ 1, 0, 1, 0, 1, 0, 1, 0]
    #second = [ 0, 0, 1, 1, 0, 0, 1, 1]
    #println("Soluzione corretta")
    #result = sumBetweenList(first,second)
    #println("Risultato --> ", result)
    #if (2 in result)
    #   result = createEdge(result)
    # 	println("Risultato Edge--> ", result)
    #end
 	
    
    #println("--------------------------------")
    #first = [ 1, 0, 0, 0, 1, 0, 0, 0]
    #second = [ 0, 0, 1, 1, 0, 0, 1, 1]
    #result = sumBetweenList(first,second)
    #println("sumBetweenList --> ", result)
    #if (2 in result)
    # result = createEdge(result)
    # println("Risultato Edge--> ", result)
    #end
    
    f1 = [1, 0, 1, 0, 1, 0, 1, 0]
    f2 = [0, 0, 1, 1, 0, 0, 1, 1]
    f3 = [0, 0, 0, 0, 1, 1, 1, 1]
    f4 = [0, 1, 0, 1, 0, 1, 0, 1]
    f5 = [1, 1, 1, 1, 0, 0, 0, 0]
    f6 = [1, 1, 0, 0, 1, 1, 0, 0]
    list = [f1, f2, f3, f4, f5, f6]

    matrixM1 = createM1(list)
    
    matrixVV = getMatrixVV(from_matrix(matrixM1))
    println("matrixVV --> ", matrixVV)
    
    matrixVE = getMatrixVE(matrixM1)
    println("matrixVE --> ", matrixVE)
    
    matrixVF = getMatrixVF(matrixM2)
    println("matrixVF --> ", matrixVF)
    
    matrixEV = getMatrixEV(matrixM1)
    println("matrixEV --> ", matrixEV)
    
    matrixEE = getMatrixEE(from_matrix(matrixM1))
    println("matrixEE --> ", matrixEE)
    
    matrixEF = getMatrixEF(from_matrix(matrixM1), from_matrix(matrixM2))
    println("matrixEF --> ", matrixEF)
    
    matrixFV = getMatrixFV(matrixM2)
    println("matrixFV --> ", matrixFV)
    
    matrixFE = getMatrixFE(from_matrix(matrixM1), from_matrix(matrixM2))
    println("matrixFE --> ", matrixFE)
    
    matrixFF = getMatrixFF(from_matrix(matrixM2))
    println("matrixFF --> ", matrixFF)
    
  end

main()
end
