require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'

def format_result(dcms, parsed_hash)
  dcm = dcms.first
  if dcm
    study = dcm.value(SD)
    case study
    when "Sono, Upper abdomen", "Sono, Lower abdomen"
      return format_upper_lower_abdomen(parsed_hash)
    end
  end
  parsed_hash.to_s
end

def format_upper_lower_abdomen(result_hash)
  str = ""

  cbd = result_hash['CBD']
  kidney = result_hash['kidney']
  spleen = result_hash['spleen']
  prostate = result_hash['Prostate Vol']

  if kidney
    if (kidney['right'] && kidney['left'])
      str += "The right kidney is about #{kidney['right']} and the left about #{kidney['left']} in longitudinal length.\n"
    elsif kidney['right']
      str += "The right kidney is about #{kidney['right']} in longitudinal length.\n"
    else
      str += "The left kidney is about #{kidney['left']} in longitudinal length.\n"
    end
  end

  if spleen
    str += "The spleen is about #{spleen} in longitudinal length.\n"
  end

  if cbd
    str += "The diameter of CBD is about #{cbd}.\n"
  end

  if prostate
    p_l = result_hash['Prostate L']
    p_h = result_hash['Prostate H']
    p_w = result_hash['Prostate W']
    str += "The size of prostate is about #{p_l} x #{p_h} x #{p_w}; the volume is about #{prostate}.\n"
  end

  str
end