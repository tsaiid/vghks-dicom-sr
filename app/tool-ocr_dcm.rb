require 'rtesseract'

def real_tag(ocr_text)
  case ocr_text
  when "V0"
    "VO"
  when "00"
    "OC"
  when "03"
    "O3"
  when "05"
    "O5"
  else
    ocr_text
  end
end

def ocr_dcm(path)

  image = RTesseract.new(path) do |img|
    img = img.white_threshold(10)
    img = img.quantize(256,Magick::GRAYColorspace)
  end

  ocr_result = image.to_s.split(/\n/).keep_if {|v| v =~ /=/}

  rt = {}
  lt = {}
  ocr_result.each do |r|
    r.match(/(\w+)\s+=.+?([\d\.]{3,6}).+?([\d\.]{3,6})$/) do |m|
      rt[real_tag(m[1])] = m[2]
      lt[real_tag(m[1])] = m[3]
    end
  end

  p path
  p rt
  p lt
end

# if given a file, parse it only, else parse the whole directory
if ARGV.first.nil?
  # read file
  dcm_path = "/Users/tsaiid/Dropbox/dcm"

  Dir.glob(dcm_path + "/*.dcm").each do |file|
    ocr_dcm(file)
  end
else
  ocr_dcm(ARGV.first)
end