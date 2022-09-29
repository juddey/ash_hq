defmodule AshHq.Repo.Migrations.MigrateResources27 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create unique_index(:libraries, [:name], name: "libraries_unique_name_index")
  end

  def down do
    drop_if_exists(unique_index(:libraries, [:name], name: "libraries_unique_name_index"))
  end
end
