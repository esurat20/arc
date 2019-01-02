defmodule Arc.File do
  defstruct  path: nil,
             file_name: :string,
             binary: nil,
             type: :string,
             meta: nil,
             valid?: true,
             errors: []

  # Given a remote file
  def new(remote_path = "https" <> _), do: new({:remote_path, remote_path})
  def new(remote_path = "http" <> _), do: new({:remote_path, remote_path})

  def new({:remote_path, remote_path}) do
    uri = URI.parse(remote_path)
    filename = Path.basename(uri.path)

    case save_file(uri, filename) do
      {:ok, local_path} -> %Arc.File{path: local_path, file_name: filename}
      :error -> {:error, :invalid_file_path}
    end
  end

  # Accepts a path
  def new(path) when is_binary(path) do
    case File.exists?(path) do
      true -> %Arc.File{path: path, file_name: Path.basename(path)}
      false -> {:error, :invalid_file_path}
    end
  end

  def new(%{binary: _binary} = file) do
    write_binary(file)
  end

  # Accepts a map conforming to %Plug.Upload{} syntax
  def new(%{filename: filename, path: path}) do
    case File.exists?(path) do
      true -> %Arc.File{path: path, file_name: filename}
      false -> {:error, :invalid_file_path}
    end
  end
  
  def generate_temporary_path(file \\ nil) do
    extension = Path.extname((file && file.path) || "")

    file_name =
      :crypto.strong_rand_bytes(20)
      |> Base.encode32()
      |> Kernel.<>(extension)

    Path.join(System.tmp_dir, file_name)
  end

  def ensure_path(file = %{path: path}) when is_binary(path), do: file
  def ensure_path(file = %{binary: binary}) when is_binary(binary), do: write_binary(file)

  def identify_type(file) do
    {type, 0} =  System.cmd("file", ["-b", "--mime-type", "#{file.path}"])
  
    %{file | type: String.trim(type)}
  end

  defp write_binary(file) do
    path = generate_temporary_path(file)
    :ok = File.write!(path, file.binary)

    %__MODULE__{
      file_name: file.file_name,
      path: path
    }
  end

  defp save_file(uri, filename) do
    local_path =
      generate_temporary_path()
      |> Kernel.<>(Path.extname(filename))

    case save_temp_file(local_path, uri) do
      :ok -> {:ok, local_path}
      _ -> :error
    end
  end

  defp save_temp_file(local_path, remote_path) do
    remote_file = get_remote_path(remote_path)

    case remote_file do
      {:ok, body} -> File.write(local_path, body)
      {:error, error} -> {:error, error}
    end
  end

  # hakney :connect_timeout - timeout used when establishing a connection, in milliseconds
  # hakney :recv_timeout - timeout used when receiving from a connection, in milliseconds
  # poison :timeout - timeout to establish a connection, in milliseconds
  # :backoff_max - maximum backoff time, in milliseconds
  # :backoff_factor - a backoff factor to apply between attempts, in milliseconds
  defp get_remote_path(remote_path) do
    options = [
      follow_redirect: true,
      recv_timeout: Application.get_env(:arc, :recv_timeout, 5_000),
      connect_timeout: Application.get_env(:arc, :connect_timeout, 10_000),
      timeout: Application.get_env(:arc, :timeout, 10_000),
      max_retries: Application.get_env(:arc, :max_retries, 3),
      backoff_factor: Application.get_env(:arc, :backoff_factor, 1000),
      backoff_max: Application.get_env(:arc, :backoff_max, 30_000),
    ]
    request(remote_path, options)
  end

  defp request(remote_path, options, tries \\ 0) do
    case HTTPoison.get(remote_path, [], options) do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:error, %{reason: :timeout}} ->
        case retry(tries, options) do
          {:ok, :retry} -> request(remote_path, options, tries + 1)
          {:error, :out_of_tries} -> {:error, :timeout}
        end

      _ -> {:error, :arc_httpoison_error}
    end
  end

  defp retry(tries, options) do
    cond do
      tries < options[:max_retries] ->
        backoff = round(options[:backoff_factor] * :math.pow(2, tries - 1))
        backoff = :erlang.min(backoff, options[:backoff_max])
        :timer.sleep(backoff)
        {:ok, :retry}

      true -> {:error, :out_of_tries}
    end
  end  
end
