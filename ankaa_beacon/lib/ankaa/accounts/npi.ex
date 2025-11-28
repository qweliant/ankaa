defmodule Ankaa.Accounts.NPI do
  @moduledoc """
  Handles NPI (National Provider Identifier) Registry lookups.
  """
  require Logger

  @base_url "https://npiregistry.cms.hhs.gov/api/"

  def lookup(number) do
    # API requires version 2.1
    params = [version: "2.1", number: number]

    case Req.get(@base_url, params: params) do
      {:ok, %{status: 200, body: %{"results" => [result | _]}}} ->
        parse_result(result)
      {:ok, %{status: 200, body: %{"Errors" => _}}} ->
        {:error, :not_found}
      {:error, _reason} ->
        {:error, :request_failed}
      _ ->
        {:error, :not_found}
    end
  end

  defp parse_result(data) do
    basic = data["basic"] || %{}
    address = List.first(data["addresses"] || []) || %{}

    {:ok, %{
      first_name: basic["first_name"],
      last_name: basic["last_name"],
      credential: basic["credential"], # e.g. "M.D.", "R.N."
      taxonomy_desc: get_taxonomy_desc(data),
      practice_state: address["state"]

    }}
  end

  defp get_taxonomy_desc(data) do
    taxonomies = data["taxonomies"] || []
    primary = Enum.find(taxonomies, &(&1["primary"] == true)) || List.first(taxonomies)
    primary["desc"] || "Healthcare Provider"
  end
end
