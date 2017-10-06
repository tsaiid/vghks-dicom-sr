require 'rubygems'
require 'bundler/setup'

require 'yaml'
require 'json'
require 'tempfile'
require_relative 'app/parse-dcm.rb'
require_relative 'app/get-dcm-by-acc.rb'
require_relative 'app/format-result.rb'

# set server info
cfg = YAML.load_file('config/config.yaml')
srvcfg = {
  'pacs' => cfg['pacs'],
  'wado' => cfg['wado']
}

# Change the log level so that only error messages are displayed:
DICOM.logger.level = Logger::ERROR

acc_no = ARGV[0]

# Check if SR exists by AccNo
status, dcms = get_dcm_by_acc_no(acc_no, "SR", 0, srvcfg)

# parse dcm
dcm_parser_status, result = parse_dcm(dcms)

# format result
result_text = format_result(dcms, result)

# merge status
status = dcm_parser_status unless dcm_parser_status.nil?

puts ({ status: status, result: result }.to_json)