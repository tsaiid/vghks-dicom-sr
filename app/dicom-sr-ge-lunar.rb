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

def gelunar_get_mp_age(dcm)
  unless dcm.nil?
    status, dcms = get_dcm_by_acc_no(dcm[AN].value, "OT", 1)
    if dcms.length > 0
      fg = Tempfile.new('gdcm')
      fd = Tempfile.new('dcm')
      dcms.first.write(fd.path)
      `gdcmconv -w #{fd.path} #{fg.path}`
      fd.unlink

      img = Magick::Image.read(fg.path).first
      fg.unlink

      # crop
      fc = Tempfile.new(['ocr_bd_crop', '.tif'])
      img.crop(476, 203, 152, 16).scale(2).write(fc.path)
    #p fc.path
    # ocr
      txt_f = Tempfile.new('ocr_bd_txt')
      `tesseract "#{fc.path}" "#{txt_f.path}" 2>/dev/null`
    #p txt_f.path
      ocr_result = File.read(txt_f.path + ".txt").to_s
    # manipulate text
      mp_age = nil
      ocr_result.match(/Menopause Age: ([\w\d]+)/) do |m|
        mp_age = m[1]
        # correct "so" to 50
        mp_age = "50" if mp_age == "so"
      end

      txt_f.unlink
      fc.unlink
    end
  end

  mp_age.empty? ? nil : mp_age
end