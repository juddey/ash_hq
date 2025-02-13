defmodule AshHq.Docs do
  @moduledoc """
  Handles documentation data.
  """
  use Ash.Api,
    extensions: [
      AshGraphql.Api,
      AshAdmin.Api
    ]

  admin do
    show? true
    default_resource_page :primary_read
  end

  execution do
    timeout 30_000
  end

  resources do
    registry AshHq.Docs.Registry
  end
end
