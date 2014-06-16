# 43128: measured value
# G-A101: side
# T-71000: site

def gh_find_code_value_item(items, code_value)
  items.each_item do |item|
    return item if item[CNCS] && item[CNCS].items[0][CV].value == code_value
  end

  nil
end

def gh_get_side(cs_items)
  side_item = gh_find_code_value_item(cs_items, "G-C171")
  side = side_item.nil? ? nil : side_item[CCS].items[0][CM].value
end

def gh_get_abdomen_measurements(cs_item)
  results = []
  cs_item.each_item do |item|
    has_content = !item[CS].nil?
    if has_content
      item[CS].each_item do |i|
        has_measure = !i[MVS].nil?
        if has_measure
          is_custom_measure = (!i[CS].items[0][TV].nil? && i[CS].items[0][CNCS].items[0][CV].value == "GEU-1005-5")
          results.push({
            site: is_custom_measure ? i[CS].items[0][TV].value : item[CNCS].items[0][CM].value,
            value: i[MVS].items[0][NV].value,
            unit: i[MVS].items[0][MUCS].items[0][CV].value
          })
        end
      end
    end
  end

  results
end

def gh_get_kidney_measurements(cs_item)
  results = []
  side = gh_get_side(cs_item)
  cs_item.each_item do |item|
    has_content = !item[CS].nil?
    if has_content
      item[CS].each_item do |i|
        has_measure = !i[MVS].nil?
        if has_measure
          results.push({
            site: item[CNCS].items[0][CM].value,
            side: side,
            value: i[MVS].items[0][NV].value,
            unit: i[MVS].items[0][MUCS].items[0][CV].value
          })
        end
      end
    end
  end

  results
end

def gh_get_all_measurements(items)
  results = []
  unless items.nil?
    items.each_item do |item|
      is_finding = (item[CNCS].items[0][CV].value == "121070")  # code meaning == Findings
      if is_finding
        category = item[CS].items[0][CCS].items[0][CV].value

        case category
        when "T-46002"  # Artery of Abdomen
          result = gh_get_abdomen_measurements(item[CS])
        when "T-71019"  # Vascular Structure Of Kidney
          result = gh_get_kidney_measurements(item[CS])
        end

        results += result unless results.include?(result)
      end
    end
  end

  results.empty? ? nil : results
end