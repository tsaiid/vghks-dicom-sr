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
MMN = "0008,1090"         # manufacturer model name
VT = "0040,A170"          # Value Type
M = "0008,0070"           # manufacturer

# read file
dcm_path = "2.dcm"
dcm = DObject.read(dcm_path)
=end

# 43128: measured value
# 43130: side
# 43133: site

def gms_find_code_value_item(items, code_value)
  items.each_item do |item|
    return item if item[CNCS] && item[CNCS].items[0][CV].value == code_value
  end

  nil
end

def gms_get_side(cs_items)
  side_item = gms_find_code_value_item(cs_items, "43130")
  side = side_item.nil? ? nil : side_item[TV].value[5..-1]
end

def gms_get_site(cs_items)
  site_item = gms_find_code_value_item(cs_items, "43133")
  site = site_item.nil? ? nil : site_item[TV].value
end

def gms_get_measurement(cs_items)
  m_item = gms_find_code_value_item(cs_items, "43128")
  value = m_item.nil? ? nil : m_item[MVS].items[0][NV].value
  unit = m_item.nil? ? nil : m_item[MVS].items[0][MUCS].items[0][CV].value
  { value: value, unit: unit }
end

def gms_get_all_measurements(items)
  results = []
  unless items.nil?
    items.each_item do |item|
      has_content = item[CS].nil?
      unless has_content
        side = gms_get_side(item[CS])
        site = gms_get_site(item[CS])
        measure = gms_get_measurement(item[CS])

        if site
          result = {
            side:     side,
            site:     site,
            value:    measure[:value],
            unit:     measure[:unit]
          }

          results.push(result) unless results.include?(result)
        end
      end
    end
  end

  results.empty? ? nil : results
end

=begin
# output
p get_all_measurements(dcm[CS])
=end