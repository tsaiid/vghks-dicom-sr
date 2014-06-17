require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'dicom'
include DICOM
require 'yaml'
require 'json'
require_relative 'app/dicom-sr-constrants.rb'
require_relative 'app/dicom-sr-philips.rb'
require_relative 'app/dicom-sr-ge.rb'
require_relative 'app/dicom-sr-ge-r3.1.2.rb'
require_relative 'app/dicom-sr-standardize.rb'
require_relative 'app/dicom-sr-get-dcm-by-acc.rb'

class DicomSR < Sinatra::Base

  configure do
    # read config file
    cfg = YAML.load_file('../../shared/config.yaml') # production env
    #cfg = YAML.load_file('app/config.yaml') # development env

    # set server info
    set :pacs_ip => cfg['pacs']['ip'], :pacs_port => cfg['pacs']['port'], :pacs_ae => cfg['pacs']['ae']
    set :wado_ip => cfg['wado']['ip'], :wado_port => cfg['wado']['port'], :wado_path => cfg['wado']['path']
  end

  get '/:acc_no' do
    # "Hello #{params[:name]}!"
    acc_no = params[:acc_no]

    # Check if SR exists by AccNo
    status, dcm = get_sr_dcm_by_acc_no(acc_no)

    # parse dcm
    if dcm
      manufacturer = dcm[Ma].value

      case manufacturer
      when "Philips Medical Systems"
        fi_item = pms_find_findings_item(dcm)
        ud_item = pms_find_user_defined_concepts_item(dcm)
        result = pms_get_measurements(fi_item) + pms_get_user_defined_measurements_calculations(ud_item)
      when "GE Medical Systems"
        result = gms_get_all_measurements(dcm[CS])
      when "GE Healthcare"
        result = gh_get_all_measurements(dcm[CS])
      else
        status = { error: "1", message: "#{manufacturer} is not supported yet." }
      end
    end

    content_type :json
    { status: status, result: standardize_result(result) }.to_json
  end
end
