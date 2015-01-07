require 'rubygems'
require 'bundler/setup'

require 'dicom'
include DICOM
require_relative 'dicom-sr-constrants.rb'
require 'yaml'

if ARGV.first.nil?
  p "need path."
  exit
end

path = ARGV.first

# convert to yaml
dcm = DObject.read(path)
fname = dcm.value(AN) + ".yaml"
File.open(fname, "w") do |f|
  f.write dcm.to_yaml
end