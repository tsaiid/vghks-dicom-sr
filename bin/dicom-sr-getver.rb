require 'dicom'
include DICOM
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
    model = dcm[MMN].value
    ver = dcm[SV].value

    p "#{file} #{manufacturer} #{model} #{ver}"

  end

  #p dcm[M].value + "::" + dcm[MMN].value
end