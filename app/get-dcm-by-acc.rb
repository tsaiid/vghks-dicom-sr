require 'dicom'
include DICOM
require 'open-uri'

def get_dcm_by_acc_no(acc_no, type = "SR", want_count = 0)
  node = DClient.new(settings.pacs_ip, settings.pacs_port, { host_ae: settings.pacs_ae })
  #study = node.find_studies({"0008,0050" => acc_no})
  #series = node.find_series({"0008,0050" => acc_no, "0008,0060" => "SR"})
  images = node.find_images({"0008,0050" => acc_no, "0008,0060" => type})
  if images.empty?
    return {error: 1, message: "No #{type} object for accession number: #{acc_no}"}, nil
  end

  # get image from WADO
  dcms = []
  images.each do |image|
    #image = images.first
    wado_url = "http://#{settings.wado_ip}:#{settings.wado_port}/#{settings.wado_path}/?" +
               "&requestType=WADO" +
               "&studyUID=" + image["0020,000D"] +
               "&seriesUID=" + image["0020,000E"] +
               "&objectUID=" + image["0008,0018"]

    #p wado_url
    dcm = nil
    image_count = 0
    begin
      open(wado_url) {|f|
        dcm = DObject.parse(f.read)
        dcms << dcm
        image_count += 1
      }
    rescue OpenURI::HTTPError => error
      response = error.io
      return response.status, nil
    end

    break if (want_count > 0 && image_count >= want_count)
  end

  return {error: 0, message: ""}, dcms
end
