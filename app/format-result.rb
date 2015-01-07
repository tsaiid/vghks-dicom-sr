require 'dicom'
include DICOM
require 'date'
require_relative 'dicom-sr-constrants.rb'

def format_result(dcms, parsed_hash)
  dcm = dcms.to_a.first
  if dcm
    study = dcm.value(SD)
    case study
    when "Sono, Upper abdomen", "Sono, Lower abdomen"
      return format_upper_lower_abdomen(parsed_hash)
    when /^Bone densitometry/
      return format_bone_density(dcm, parsed_hash)
    end
  end
  parsed_hash.to_s
end

def format_upper_lower_abdomen(result_hash)
  str = ""

  cbd = result_hash['CBD']
  kidney = result_hash['kidney']
  spleen = result_hash['spleen']
  prostate = result_hash['Prostate Vol']

  if kidney
    if (kidney['right'] && kidney['left'])
      str += "The right kidney is about #{kidney['right']} and the left about #{kidney['left']} in longitudinal length.\n"
    elsif kidney['right']
      str += "The right kidney is about #{kidney['right']} in longitudinal length.\n"
    else
      str += "The left kidney is about #{kidney['left']} in longitudinal length.\n"
    end
  end

  if spleen
    str += "The spleen is about #{spleen} in longitudinal length.\n"
  end

  if cbd
    str += "The diameter of CBD is about #{cbd}.\n"
  end

  if prostate
    p_l = result_hash['Prostate L']
    p_h = result_hash['Prostate H']
    p_w = result_hash['Prostate W']
    str += "The size of prostate is about #{p_l} x #{p_h} x #{p_w}; the volume is about #{prostate}.\n"
  end

  str
end

def format_bd_general(t_or_z, percent_str, score)
  percent = percent_str.sub(" ", "")

  case t_or_z
  when "T"
    str = "and is about #{percent} of the mean of young reference value (T-score = #{score})."
  when "Z"
    str = "the age matched percentage was about #{percent} (Z-score = #{score})."
  end

  str += "\n\n"
end

def format_bd_spine(t_or_z, level, bmd, percent, score)
  str = "Average bone mineral density (BMD) of #{level} is #{bmd}, " + format_bd_general(t_or_z, percent, score)
end

def format_bd_femur(t_or_z, side, bmd, percent, score)
  str = "The BMD of #{side.downcase} proximal femur is #{bmd}, " + format_bd_general(t_or_z, percent, score)
end

def format_bd_forearm(t_or_z, side, bmd, percent, score)
  str = "The BMD of #{side.downcase} 1/3 forearm is #{bmd}, " + format_bd_general(t_or_z, percent, score)
end

def format_bd_conclusion(t_or_z, lowest_score)
  category = ""
  str = "Conclusion:\n"

  case t_or_z
  when "T"
    if lowest_score <= -2.5
      category = "osteoporosis"
    elsif lowest_score < -1.0
      category = "low bone mass"
    else
      category = "normal limit"
    end
    str += "The BMD meets the criteria of #{category}, according to the WHO (World Health Organization) classification."
  when "Z"
    category = (lowest_score <= -2 ? "below" : "within")
    str += "The BMD meets the criteria was #{category} the expected range of age, according to 2007 ISCD (the International Society for Clinical Densitometry) combined official positions.\n\n(Z-score of -2.0 or lower is defined as 'below the expected range for age', and a Z-score above -2.0 is 'within the expected range for age')"
  end
end

def determine_t_or_z(dcm_first, mp_age)
  if dcm_first
    age = (Date.parse(dcm_first[StudyDate].value) - Date.parse(dcm_first[PBD].value)).to_i / 365.25
    sex = dcm_first[PatientSex].value

    case sex
    when "M"
      age > 50 ? "T" : "Z"
    when "F"
      # menopause_age = 45  # for debug now.
      mp_age || age > 55 ? "T" : "Z"
    else
      "T" # default return "T"
    end

  end
end

def format_bone_density(dcm, result_hash)
  str = ""
  t_or_z = determine_t_or_z(dcm, result_hash[:mp_age])
  sides = ["Right", "Left"]
  key_map = { score: {
                "T" => "BMD_TSCORE",
                "Z" => "BMD_ZSCORE" },
              percent: {
                "T" => "BMD_PYA",
                "Z" => "BMD_PAM"} }
  all_scores = []

  # AP Spine
  tmp_hash = result_hash["AP Spine"]
  if tmp_hash
    max_delta = 0
    max_level = nil
    max_val = nil
    tmp_hash.each do |level, val|
      level.match('L(\d)-L(\d)') do |m|
        delta = m[2].to_i - m [1].to_i
        if (delta > max_delta)
          max_delta = delta
          max_level = level
          max_val = val
        end
      end
    end

    if max_level
      bmd = max_val["BMD"]
      score = max_val[key_map[:score][t_or_z]]
      percent = max_val[key_map[:percent][t_or_z]]

      str += format_bd_spine(t_or_z, max_level, bmd, percent, score)
      all_scores << score.to_f
    end
  end

  # DualFemur
  tmp_hash = result_hash["DualFemur"]
  if tmp_hash
    sides.each do |side|
      if (tmp_hash["Neck #{side}"] && tmp_hash["Total #{side}"])
        neck_score = tmp_hash["Neck #{side}"][key_map[:score][t_or_z]].to_f
        neck_percent = tmp_hash["Neck #{side}"][key_map[:percent][t_or_z]]
        neck_bmd = tmp_hash["Neck #{side}"]["BMD"]
        total_score = tmp_hash["Total #{side}"][key_map[:score][t_or_z]].to_f
        total_percent = tmp_hash["Total #{side}"][key_map[:percent][t_or_z]]
        total_bmd = tmp_hash["Total #{side}"]["BMD"]

        # for debug if missing sr data.
        if (neck_score.nil? || neck_percent.nil? || neck_bmd.nil? ||
            total_score.nil? || total_percent.nil? || total_bmd.nil? )
          p result_hash
        end

        if neck_score < total_score
          femur_score = neck_score
          femur_bmd = neck_bmd
          femur_percent = neck_percent
        elsif neck_score == total_score
          if neck_percent < total_percent
            femur_score = neck_score
            femur_bmd = neck_bmd
            femur_percent = neck_percent
          else
            femur_score = total_score
            femur_bmd = total_bmd
            femur_percent = total_percent
          end
        else
          femur_score = total_score
          femur_bmd = total_bmd
          femur_percent = total_percent
        end

        str += format_bd_femur(t_or_z, side, femur_bmd, femur_percent, femur_score)
        all_scores << femur_score.to_f
      end
    end
  end

  # Forearm
  sides.each do |side|
    tmp_hash = result_hash["#{side} Forearm"]
    if tmp_hash
      radius_33_score = tmp_hash["Radius 33%"][key_map[:score][t_or_z]].to_f
      radius_33_percent = tmp_hash["Radius 33%"][key_map[:percent][t_or_z]]
      radius_33_bmd = tmp_hash["Radius 33%"]["BMD"]

      str += format_bd_forearm(t_or_z, side, radius_33_bmd, radius_33_percent, radius_33_score)
      all_scores << radius_33_score.to_f
    end
  end

  # Conclusion
  str += format_bd_conclusion(t_or_z, all_scores.min)
end