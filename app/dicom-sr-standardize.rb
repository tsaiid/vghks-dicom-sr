require 'ruby-units'

def standardize_site(site)
  return "kidney" if ["Kidney", "Renal L"].include? site
  return "spleen" if ["Spleen", "Splenic L"].include? site
  site
end

def standardize_side(side)
  return "left" if ["Left", "Lt"].include? side
  return "left" if ["Right", "Rt"].include? side
  side
end

def standardize_value(site, value, unit)
  preferred_unit_by_site = {
    "kidney" => "centimeters",
    "spleen" => "centimeters",
    "CBD" => "millimeters"
  }

  Unit(value + unit).convert_to(preferred_unit_by_site[site]).round(1).to_s
end

def standardize_result(results)
  standardized_result = []
  results.each do |r|
    std_site = standardize_site(r[:site])
    standardized_result << {
      site: std_site,
      side: standardize_side(r[:side]),
      value: standardize_value(std_site, r[:value], r[:unit])
    }
  end
  return standardized_result.empty? ? nil : standardized_result
end
