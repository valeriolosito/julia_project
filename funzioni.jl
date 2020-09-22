module Funzioni

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
   size = length(list)
   for i in 1:size-1
    currentList = list[i]
    for j in i+1: size
     nextList = list[j]
     sumVector = sumBetweenList(currentList, nextList)
     if (2 in sumVector)
      edge = createEdge(sumVector)
      println("Edge da inserire", edge)
      #Massimo -> va inserito edge in matrix
     end
    end
   end
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
    
    #createM2(listFaces, tot)
    
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
    createM1(list)
  end

main()
end
