defmodule HamsterTravel.EctoNameSlug do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      module = Keyword.get(opts, :module)

      use EctoAutoslugField.Slug, from: :name, to: :slug, always_change: true

      import Ecto.Query

      alias HamsterTravel.Repo

      def build_slug(sources, changeset) do
        sources |> super(changeset) |> ensure_unique_slug(0)
      end

      defp ensure_unique_slug(slug, attempts) do
        slug_to_try = next_slug(slug, attempts)

        if Repo.exists?(from e in unquote(module), where: e.slug == ^slug_to_try) do
          ensure_unique_slug(slug, attempts + 1)
        else
          slug_to_try
        end
      end

      defp next_slug(slug, 0), do: slug
      defp next_slug(slug, attempts), do: "#{slug}-#{attempts}"
    end
  end
end
