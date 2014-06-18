def phv_get_laterality(items)
  items.each_item do |item|
    return item[CCS].items[0][CM].value if item[CNCS].items[0][CM].value == "Laterality"
  end
  nil
end



def phv_find_code_value_item(items, code_value)
  items.each_item do |item|
    return item if item[CNCS] && item[CNCS].items[0][CV].value == code_value
  end

  nil
end

def phv_get_measurement(cs_items)
  results = []
  cs_items.each_item do |item|
    site = phv_find_code_value_item(item[CS], "T9900-04")[TV].value
    side = phv_get_laterality(item[CS]).downcase
    value = phv_find_code_value_item(item[CS], "T9900-05")[MVS].items[0][NV].value

    results << { site: site, side: side, value: value }
  end

  results
end

def phv_get_all_measurements(items)
  results = []
  unless items.nil?
    items.each_item do |item|
#      is_finding = (item[CNCS].items[0][CV].value == '121070')
      is_user_defined = (item[CNCS].items[0][CM].value == 'User-defined concepts')
      if is_user_defined
        result = phv_get_measurement(item[CS])
        results += result
        #p results
      end
    end
  end

  standardized_result = {}
  results.each do |r|
    standardized_result[r[:site]] = {} unless standardized_result[r[:site]]
    standardized_result[r[:site]][r[:side]] = r[:value].to_f.round(1)
    #p standardized_result
  end
  standardized_result[:debug] = results

  standardized_result.empty? ? nil : standardized_result
end

