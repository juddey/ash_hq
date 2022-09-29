defmodule AshHq.Repo.Migrations.MigrateResources5 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:libraries) do
      add(:description, :text)
    end

    alter table(:guides) do
      modify(:category, :text, null: false)
    end
  end

  def down do
    alter table(:guides) do
      modify(:category, :text, null: true)
    end

    alter table(:libraries) do
      remove(:description)
    end
  end
end
