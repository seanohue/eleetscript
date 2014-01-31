class Enumerable
  [] do |name|
    cname = class_name
    Errors < "Class %cname has not implemented [] which is required for Enumerable"
  end

  []= do |name, value|
    cname = class_name
    Errors < "Class %cname has not implemented []= which is required for Enumerable"
  end

  length do |name, value|
    cname = class_name
    Errors < "Class %cname has not implemented length which is required for Enumerable"
  end

  each do |iter|
    if lambda? and iter.kind_of?(Lambda)
      i = 0
      while i < self.length
        iter.call(self[i], i)
        i += 1
      end
    end
  end

  map do |iter|
    if lambda? and iter.kind_of?(Lambda)
      arr = []
      each -> { |item, key|
        arr < iter.call(item, key)
      }
    end
    arr
  end
end