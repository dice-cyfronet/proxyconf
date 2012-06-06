# Extends core Array class
class Array
  # Extracts specific key from array of hashes.
  def extract(sym)
    map { |e| e[sym] }
  end
  
  # Calculates sum of array elements
  def sum                  
    return nil if size == 0    
    reduce(:+)
  end
  
  # Calculates average of array elements
  def avg                  
    return nil if size == 0    
    sum.to_f / size
  end
  
  # Calculates deviation over array
  def stddev
    return nil if size == 0    
    a = avg
    Math::sqrt(map { |v| (v - a)**2 }.sum/size)  
  end 
  
  # Calculates median of array members
  def median
    return nil if size == 0
    sorted = sort
    med_norm = sorted[size/2]
    med_even = sorted[size/2-1]
    size % 2 ? (med_norm + med_even)/2 : med_norm
  end
end
