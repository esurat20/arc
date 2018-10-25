defmodule Arc.Validator do
  def validate_number(struct, value, opts, validators) do 
    struct = 
      Enum.reduce opts, struct, fn({key, target_value}, struct) ->
        case Map.fetch(validators, key) do
          {:ok, {func, message, measure}} -> 
            validate_number(struct, func, value, target_value, message, measure)
          :error ->
            raise ArgumentError, "unknown option #{inspect key} given to validate_number/4"
        end
      end
    struct
  end
  
  defp validate_number(struct, func, value, target_value, message, measure) do
    case apply(func, [value, target_value]) do
      true  ->
        struct
      false -> 
        %{struct | valid?: false, errors: ["#{message} #{target_value} #{measure}" | struct.errors]}
    end
  end
end
