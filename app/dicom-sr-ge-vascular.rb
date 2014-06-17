# get first
def gev_find_code_value_item(items, code_value)
  items.each_item do |item|
    return item if item[CNCS] && item[CNCS].items[0][CV].value == code_value
  end

  nil
end

# get all
def gev_find_code_value_items(items, code_value)
  results = []
  items.each_item do |item|
    results << item if item[CNCS] && item[CNCS].items[0][CV].value == code_value
  end

  results.empty? ? nil : results
end

def gev_get_side(cs_items)
  side_item = gev_find_code_value_item(cs_items, "G-C171")
  side = side_item.nil? ? nil : side_item[CCS].items[0][CM].value
end

def gev_get_measurement(cs_items)
  site_items = gev_find_code_value_items(cs_items, "33868-1")
  #p site_items
  results = []
  side = gev_get_side(cs_items).downcase
  #p side
  site_items.each do |item|
    site = item[CNCS].items[0][CM].value
    phase = item[CS].items[0][CCS].items[0][CM].value.downcase
    value = item[MVS].items[0][NV].value

    results << { site: site, side: side, phase: phase, value: value }
    #p results
  end
  results
end

def gev_get_all_measurements(items)
  results = []
  unless items.nil?
    items.each_item do |item|
      is_finding = (item[CNCS].items[0][CV].value == '121070')
      if is_finding
        result = gev_get_measurement(item[CS])
        results += result
        #p results
      end
    end
  end

  standardized_result = {}
  results.each do |r|
    standardized_result[r[:site]] = {} unless standardized_result[r[:site]]
    standardized_result[r[:site]][r[:side]] = { phase: r[:phase], value: r[:value].to_f.round(2) }
    #p standardized_result
  end
  standardized_result[:debug] = results

  standardized_result.empty? ? nil : standardized_result
end
