require 'dicom'
include DICOM
require './dicom-sr-philips.rb'
require './dicom-sr-ge.rb'
require './dicom-sr-ge-r3.1.2.rb'
require './dicom-sr-constrants.rb'

DICOM.logger.level = Logger::ERROR

# for fix ruby-dicom gem 0.9.5
require 'json'
require 'yaml'


# read file
dcm_path = "/Users/tsaiid/Dropbox/dcm"
#dcm = DObject.read(dcm_path)

Dir.glob(dcm_path + "/*.dcm").each do |file|
  dcm = DObject.read(file)

  if dcm[Mo].value == "SR"
    manufacturer = dcm[Ma].value

    p file

    case manufacturer
    when "Philips Medical Systems"
      fi_item = pms_find_findings_item(dcm)
      ud_item = pms_find_user_defined_concepts_item(dcm)
      p pms_get_measurements(fi_item) + pms_get_user_defined_measurements_calculations(ud_item)
    when "GE Medical Systems"
      p gms_get_all_measurements(dcm[CS])
    when "GE Healthcare"
      p gh_get_all_measurements(dcm[CS])
    else
      p "#{manufacturer} is not supported yet."
    end
  end

  #p dcm[M].value + "::" + dcm[MMN].value
end