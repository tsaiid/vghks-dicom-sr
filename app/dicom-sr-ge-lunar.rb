def gelunar_get_measurement_by_roi(roi_cs_items)
  #site_items = gelunar_find_code_value_items(cs_items, "33868-1")
  #p site_items
  results = {}
  #side = gelunar_get_side(cs_items).downcase
  #p side
  #value_type_map = { "NUM" => NV, "TEXT" => TV }
  roi_cs_items.each do |item|
    value_type = item[VT].value
    parameter = item[CNCS].items[0][CM].value
    case value_type
    when "NUM"
      value = item[MVS].items[0][NV].value
      unit = item[MVS].items[0][MUCS].items[0][CM].value
      str = "#{value} #{unit}"
    when "TEXT"
      str = item[TV].value
    else
      str = "No TV???"
    end

    results[parameter] = str
    #p results
  end
  results
end

def gelunar_all_measurements(items)
  results = {}
  unless items.nil?
    items.each_item do |item|
      is_measure = (item[CNCS].items[0][CV].value =~ /^2000/)
      if is_measure
        roi_results = {}
        exam = item[CNCS].items[0][CM].value
        item[CS].each_item do |roi|
          site = roi[CNCS].items[0][CM].value
          roi_result = gelunar_get_measurement_by_roi(roi[CS])
          roi_results[site] = roi_result
          #p results
        end
        results[exam] = roi_results
      end
    end
  end

  results.empty? ? nil : results
end
