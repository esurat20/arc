defmodule Arc.Type.Image do
  
  @verbose_regexp ~r/\b(?<format>\S+) (?<width>\d+)x(?<height>\d+)/

  defmacro __using__(_opts) do
  	quote do
      def put_meta("image/" <> _, file), do: Arc.Type.Image.put_meta(file)
    end
  end

  def put_meta(file) do
  	case verbose(file) do
  	  meta when is_map(meta) ->
  	    %{file | meta: meta} 
      {:error, _} = error ->
        error
  	end
  end

  defp verbose(image) do
    try do
      args = ~w(-verbose) ++ [image.path]
      case System.cmd "mogrify", args, stderr_to_stdout: true do
        {output, 0} ->
          @verbose_regexp
          |> Regex.named_captures(output)
          |> Enum.map(&normalize_verbose_term/1)
          |> Enum.into(%{})
        {_, 1} ->
          {:error, "attachment file is not image"}  
      end
    rescue
      ErlangError -> raise("Cannot run `identify` command. ImageMagick is not installed.")
    end
  end

  defp normalize_verbose_term({key, value}) when key in ["width", "height"] do
    {String.to_atom(key), String.to_integer(value)}
  end
  defp normalize_verbose_term({key, value}), do: {String.to_atom(key), String.downcase(value)}
end