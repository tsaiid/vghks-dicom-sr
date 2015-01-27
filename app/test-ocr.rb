require 'rtesseract'

image = RTesseract.new("spg.jpg")
image = RTesseract.new("spg.dcm")

mix_block = RTesseract::Mixed.new("seg.dcm") do |image|
  image.area(470, 870, 68, 41) # Rt ABI
  image.area(730, 870, 68, 41) # Lt ABI

  image.area(470, 1080, 150, 30) # Brachial artery
  image.area(690, 1068, 57, 25) # Rt P
  image.area(755, 1068, 57, 25) # Lt P
  #image.area(690, 1100, 57, 25) # Rt I
  #image.area(755, 1100, 57, 25) # Lt I

  image.area(457, 1190, 170, 53) # Lower Thigh
  image.area(690, 1187, 57, 25) # Rt P
  image.area(755, 1187, 57, 25) # Lt P
  #image.area(690, 1216, 57, 25) # Rt I
  #image.area(755, 1216, 57, 25) # Lt I

  image.area(457, 1250, 170, 53) # Calf
  image.area(690, 1245, 57, 25) # Rt P
  image.area(755, 1245, 57, 25) # Lt P
  #image.area(690, 1275, 57, 25) # Rt I
  #image.area(755, 1275, 57, 25) # Lt I

  image.area(457, 1310, 170, 53) # Ankle
  image.area(690, 1305, 57, 25) # Rt P
  image.area(755, 1305, 57, 25) # Lt P
  #image.area(690, 1335, 57, 25) # Rt I
  #image.area(755, 1335, 57, 25) # Lt I

end
mix_block.to_s.split(/\n+/)


mix_block = RTesseract::Mixed.new("seg.dcm") do |image|
  image.area(470, 870, 68, 41) # Rt ABI
  image.area(730, 870, 68, 41) # Lt ABI

  image.area(470, 1080, 150, 30) # Brachial artery
  image.area(690, 1068, 57, 25) # Rt P
  image.area(755, 1068, 57, 25) # Lt P

  image.area(457, 1190, 170, 53) # Lower Thigh
  image.area(690, 1187, 57, 25) # Rt P
  image.area(755, 1187, 57, 25) # Lt P

  image.area(457, 1250, 170, 53) # Calf
  image.area(690, 1245, 57, 25) # Rt P
  image.area(755, 1245, 57, 25) # Lt P

  image.area(457, 1310, 170, 53) # Ankle
  image.area(690, 1305, 57, 25) # Rt P
  image.area(755, 1305, 57, 25) # Lt P

  image.area(457, 1135, 170, 53) # Upper Thigh
  image.area(690, 1128, 57, 25) # Rt P
  image.area(755, 1128, 57, 25) # Lt P
end
mix_block.to_s.split(/\n+/)

mix_block = RTesseract::MyMixed.new("seg.dcm") do |image|
    image.labeled_area(470, 870, 68, 41, "RtABI") # Rt ABI
    image.labeled_area(730, 870, 68, 41, "LtABI") # Lt ABI

    image.labeled_area(470, 1080, 150, 30, "Brachial") # Brachial
    image.labeled_area(690, 1068, 57, 25, "RtBrachial") # Rt P
    image.labeled_area(755, 1068, 57, 25, "LtBrachial") # Lt P

    image.labeled_area(457, 1190, 170, 53, "LowerThigh") # Lower Thigh
    image.labeled_area(690, 1187, 57, 25, "RtLowerThigh") # Rt P
    image.labeled_area(755, 1187, 57, 25, "LtLowerThigh") # Lt P

    image.labeled_area(457, 1250, 170, 53, "Calf") # Calf
    image.labeled_area(690, 1245, 57, 25, "RtCalf") # Rt P
    image.labeled_area(755, 1245, 57, 25, "LtCalf") # Lt P

    image.labeled_area(457, 1310, 170, 53, "Ankle") # Ankle
    image.labeled_area(690, 1305, 57, 25, "RtAnkle") # Rt P
    image.labeled_area(755, 1305, 57, 25, "LtAnkle") # Lt P
end
mix_block.to_s_with_label


image = RTesseract.new("seg.dcm") do |img|
  img = img.white_threshold(100)
  img = img.quantize(256,Magick::GRAYColorspace)
end

image.to_s.split(/\n/)


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

ocr_result = image.to_s.split(/\n/).keep_if {|v| v =~ /=/}

rt = {}
lt = {}
ocr_result.each do |r|
  r.match(/(\w+)\s+=.+?([\d\.]{3,6}).+?([\d\.]{3,6})$/) do |m|
    rt[real_tag(m[1])] = m[2]
    lt[real_tag(m[1])] = m[3]
  end
end


require 'RMagick'
require 'dicom'
include DICOM

dcm = DObject.read("seg.dcm")
