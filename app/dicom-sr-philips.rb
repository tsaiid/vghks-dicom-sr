=begin
require 'dicom'
include DICOM

# for fix ruby-dicom gem 0.9.5
require 'json'
require 'yaml'

# Constants
CS = "0040,A730"          # code_sequence
CNCS = "0040,A043"        # code_name_code_sequence
CM = "0008,0104"          # code_meaning
CV = "0008,0100"          # code_value
TV = "0040,A160"          # text_value
MVS = "0040,A300"         # measured_value_sequence
MUCS = "0040,08EA"        # measurement_unit_code_sequence
NV = "0040,A30A"          # numeric_value

# read file
dcm_path = "1.2.840.113663.1500.1.341633854.8.1.20140612.101117.250.dcm"
dcm = DObject.read(dcm_path)
=end

def pms_find_patient_characteristics_item(dcm)
  dcm[CS].each_item do |item|
    return item if item[CNCS].items[0][CM].value == 'Patient Characteristics'
  end
end

def pms_find_findings_item(dcm)
  dcm[CS].each_item do |item|
    return item if item[CNCS].items[0][CM].value == 'Findings'
  end

  nil
end

def pms_find_user_defined_concepts_item(dcm)
  dcm[CS].each_item do |item|
    return item if item[CNCS].items[0][CM].value == 'User-defined concepts'
  end

  nil
end


def pms_get_measurements(findings_item)
  results = []
  unless findings_item.nil?
    findings_item[CS].each_item do |item|
      has_measure = (item[CS] && item[CS].items[0][MVS])
      if has_measure
        site = item[CNCS].items[0][CM].value
        value = item[CS].items[0][MVS].items[0][NV].value
        unit = item[CS].items[0][MVS].items[0][MUCS].items[0][CM].value

        results.push({
          site:     site,
          value:    value,
          unit:     unit
        })
      end
    end
  end

  results.empty? ? nil : results
end

def pms_get_laterality(items)
  items.each_item do |item|
    case item[CNCS].items[0][CM].value
    when "Laterality"
      return item[CCS].items[0][CM].value
    when "Label"    # sometimes, the side is hidden in the Site section.
      site = item.value(TV)
      site.match(/^([LR]t) /) { |m|
        return m[1]
      }
    end
  end
  nil
end

def pms_get_value_unit(items)
  items.each_item do |item|
    if ["Distance", "Value"].include? item[CNCS].items[0][CM].value
      return item[MVS].items[0][NV].value, item[MVS].items[0][MUCS].items[0][CM].value
    end
  end
  return nil, nil
end

def pms_get_user_defined_measurements_calculations(udm_item)
  results = []
  udm_item[CS].each_item do |item|
    has_measure = (
                    item[CNCS] &&
                    item[CNCS].items[0][CM] &&
                    ["Measurement", "Calculation"].include?(item[CNCS].items[0][CM].value)
                  )
    if has_measure
      site = item[CS].items[0][TV].value
      side = pms_get_laterality(item[CS])
      value, unit = pms_get_value_unit(item[CS])
      #value = item[CS].items[1][MVS].items[0][NV].value
      #unit = item[CS].items[1][MVS].items[0][MUCS].items[0][CM].value

      results.push({
        site:     site,
        side:     side,
        value:    value,
        unit:     unit
      })
    end
  end

  results.empty? ? nil : results
end

def pms_get_all_measurements(dcm)
  fi_item = pms_find_findings_item(dcm)
  ud_item = pms_find_user_defined_concepts_item(dcm)
  fi_result = pms_get_measurements(fi_item)
  ud_result = pms_get_user_defined_measurements_calculations(ud_item)
  result = []
  result += fi_result if fi_result
  result += ud_result if ud_result
end

=begin
# get patient characteristics item
pc_item = find_patient_characteristics_item(dcm)
fi_item = find_findings_item(dcm)
ud_item = find_user_defined_concepts_item(dcm)

# output
p get_measurements(fi_item)
p get_user_defined_measurements_calculations(ud_item)
=end