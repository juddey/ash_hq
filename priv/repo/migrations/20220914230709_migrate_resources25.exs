defmodule AshHq.Repo.Migrations.MigrateResources25 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:options) do
      modify(:extension_id, :uuid, null: true)
      modify(:library_version_id, :uuid, null: true)
      modify(:dsl_id, :uuid, null: true)
    end

    alter table(:modules) do
      modify(:library_version_id, :uuid, null: true)
    end

    alter table(:library_versions) do
      modify(:library_id, :uuid, null: true)
    end

    alter table(:guides) do
      modify(:library_version_id, :uuid, null: true)
    end

    alter table(:functions) do
      modify(:module_id, :uuid, null: true)
      modify(:library_version_id, :uuid, null: true)
      add(:heads_html, {:array, :text})
    end

    alter table(:extensions) do
      modify(:library_version_id, :uuid, null: true)
    end

    alter table(:dsls) do
      modify(:extension_id, :uuid, null: true)
      modify(:library_version_id, :uuid, null: true)
    end
  end

  def down do
    alter table(:dsls) do
      modify(:library_version_id, :uuid, null: false)
      modify(:extension_id, :uuid, null: false)
    end

    alter table(:extensions) do
      modify(:library_version_id, :uuid, null: false)
    end

    alter table(:functions) do
      remove(:heads_html)
      modify(:library_version_id, :uuid, null: false)
      modify(:module_id, :uuid, null: false)
    end

    alter table(:guides) do
      modify(:library_version_id, :uuid, null: false)
    end

    alter table(:library_versions) do
      modify(:library_id, :uuid, null: false)
    end

    alter table(:modules) do
      modify(:library_version_id, :uuid, null: false)
    end

    alter table(:options) do
      modify(:dsl_id, :uuid, null: false)
      modify(:library_version_id, :uuid, null: false)
      modify(:extension_id, :uuid, null: false)
    end
  end
end
