defmodule Arc.Validation.File do
  import Arc.Validator

  @file_size_validators %{
    min:    {&>=/2, "file size must be greater than or equal to", "byte"},
    max:    {&<=/2, "file size must be less than or equal to", "byte"},
  }
  
  def validate_file_format(file, allowed_formats) do
    format = String.slice(Path.extname(String.downcase(file.file_name)), 1..20)
    if Enum.member?(allowed_formats, format) do
      file
    else
      %{file | error: ["has invalid format, supports #{allowed_formats} files" | file.error]}
    end
  end

  def validate_file_size(%{path: path} = file, opts) do
    {:ok, %{size: file_size}} = File.stat(path)
    validate_number(file, file_size, opts, @file_size_validators)
  end
  def validate_file_size(%{binary: binary} = file, opts) do
    binary_size = IO.iodata_length(binary)
    validate_number(file, binary_size, opts, @file_size_validators)
  end
end