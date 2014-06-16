require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'

class MyFileHandler < FileHandler
  def self.save_file(path_prefix, dcm, transfer_syntax)
      # File name is set using the SOP Instance UID:
      file_name = dcm.value(AN) || "missing_accession_no"
      extension = ".dcm"
      folders = Array.new(2)
      folders[0] = ".."
      folders[1] = "tmp"
      local_path = folders.join(File::SEPARATOR) + File::SEPARATOR + file_name
      full_path = path_prefix + File::SEPARATOR + local_path + extension
      # Save the DICOM object to disk:
      dcm.write(full_path, :transfer_syntax => transfer_syntax)
      message = [:info, "DICOM file saved to: #{full_path}"]
      return message
  end
end

script_path = File.dirname(__FILE__)
DServer.run(3104, script_path) do |s|
  s.timeout = 100
  s.file_handler = MyFileHandler
end