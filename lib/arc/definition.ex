defmodule Arc.Definition do
  defmacro __using__(_options) do
    quote do
      use Arc.Definition.Versioning
      use Arc.Definition.Storage

      use Arc.Actions.Store
      use Arc.Actions.Delete
      use Arc.Actions.Url

      use Arc.Type.Image

      def validate_content_type(_), do: true

      defoverridable [validate_content_type: 1]

      @before_compile Arc.Definition
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def put_meta(_, file), do: file
    end
  end
end
