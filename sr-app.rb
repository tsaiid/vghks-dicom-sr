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
require_relative 'app/dicom-sr-ge-vascular.rb'
require_relative 'app/dicom-sr-ph-vascular.rb'
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
      study = dcm[SD].value

      case study
      when 'Sono & Doppler, Carotid art.-PCU' # vascular
        case manufacturer
        when "Philips Medical Systems"
          result = phv_get_all_measurements(dcm[CS])
        else
          result = gev_get_all_measurements(dcm[CS])
        end
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

      if result.nil?
        status = {
          error: 1,
          message: "No fetchable data in this SR."
        }
      end
    end

    content_type :json
    { status: status, result: result }.to_json
  end


end
