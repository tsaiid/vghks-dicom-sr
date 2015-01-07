require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'
require_relative 'dicom-sr-philips.rb'
require_relative 'dicom-sr-ge.rb'
require_relative 'dicom-sr-ge-r3.1.2.rb'
require_relative 'dicom-sr-standardize.rb'
require_relative 'dicom-sr-ge-vascular.rb'
require_relative 'dicom-sr-ph-vascular.rb'
require_relative 'dicom-sr-ge-lunar.rb'

def parse_dcm(dcms)
  result = {}
  tmp_result = [] # for debug
  dcms.to_a.each do |dcm|
    manufacturer = dcm[Ma].value
    study = dcm[SD].value

    case study
    when 'Sono & Doppler, Carotid art.-PCU' # vascular
      case manufacturer
      when "Philips Medical Systems"
        result = phv_get_all_measurements(dcm[CS])
      else
        result = gev_get_all_measurements(dcm[CS])
      end
    when /^Bone densitometry/
      result = result.merge(gelunar_all_measurements(dcm[CS])) do |key, v1, v2|
        # Dirty Hack
        ## The output of shorter hash will miss data, choose the longer for merging.
        ## Better solution: may need recursive merge
        if (v1.is_a?(Hash) && v2.is_a?(Hash))
          v1.length > v2.length ? v1 : v2
        else
          v2
        end
      end
      if (dcm[PatientSex].value == "F" && result[:mp_age].nil?)
        result[:mp_age] = gelunar_get_mp_age(dcm)
      end

      # for debug
      tmp_result << gelunar_all_measurements(dcm[CS])
    else  # others
      case manufacturer
      when "Philips Medical Systems"
        result = pms_get_all_measurements(dcm)
      when "GE Medical Systems"
        result = gms_get_all_measurements(dcm[CS])
      when "GE Healthcare"
        result = gh_get_all_measurements(dcm[CS])
      else
        status = { error: "1", message: "#{manufacturer} is not supported yet." }
      end

      result = standardize_result(result)
    end
  end

  # for debug
  unless tmp_result.empty?
    result[:debug] = tmp_result
  end

  if result.nil?
    status = {
      error: 1,
      message: "No fetchable data in this SR."
    }
  end

  return status, result
end