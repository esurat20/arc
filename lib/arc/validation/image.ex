defmodule Arc.Validation.Image do
  import Arc.Validator
 
  @image_width_validators %{
    max_width:     {&<=/2, "image width must be less than or equal to", "px"},
    min_width:     {&>=/2, "image width must be greater than or equal to", "px"},
  }

  @image_height_validators %{
    max_height:    {&<=/2, "image height must be less than or equal to", "px"},
    min_height:    {&>=/2, "image height must be greater than or equal to", "px"},
  }

  def validate_image_format(%{meta: meta} = file, allowed_formats) do
    if Enum.member?(allowed_formats, meta.format) do
      file
    else
      %{file | valid?: false, errors: ["has invalid format, supports #{allowed_formats} files" | file.errors]}
    end  
  end
 
  def validate_image_width(%{meta: meta} = file, opts) do
    validate_number(file, meta.width, opts, @image_width_validators)
  end

  def validate_image_height(%{meta: meta} = file, opts) do
    validate_number(file, meta.height, opts, @image_height_validators)
  end
end