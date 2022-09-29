defmodule AshHq.Repo.Migrations.MigrateResources1 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:options, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)
      add(:name, :text, null: false)
      add(:type, :text, null: false)
      add(:doc, :text, null: false, default: "")
      add(:doc_html, :text)
      add(:required, :boolean, null: false, default: false)
      add(:default, :text)
      add(:path, {:array, :text})
      add(:order, :bigint, null: false)
      add(:dsl_id, :uuid, null: false)
      add(:library_version_id, :uuid, null: false)
      add(:extension_id, :uuid, null: false)
    end

    create table(:modules, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)
      add(:name, :text, null: false)
      add(:doc, :text, null: false, default: "")
      add(:doc_html, :text)
      add(:order, :bigint, null: false)
      add(:library_version_id, :uuid, null: false)
      add(:extension_id, :uuid, null: false)
    end

    create table(:library_versions, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)
    end

    alter table(:modules) do
      modify(
        :library_version_id,
        references(:library_versions,
          column: :id,
          name: "modules_library_version_id_fkey",
          type: :uuid
        )
      )
    end

    alter table(:library_versions) do
      add(:version, :text, null: false)
      add(:data, :map)
      add(:doc, :text, null: false, default: "")
      add(:doc_html, :text)
      add(:processed, :boolean, default: false)
      add(:library_id, :uuid, null: false)
    end

    create table(:libraries, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)
    end

    alter table(:library_versions) do
      modify(
        :library_id,
        references(:libraries,
          column: :id,
          name: "library_versions_library_id_fkey",
          type: :uuid
        )
      )
    end

    create unique_index(:library_versions, [:library_id, :version],
             name: "library_versions_unique_version_for_library_index"
           )

    alter table(:libraries) do
      add(:name, :text, null: false)
      add(:display_name, :text, null: false)
      add(:track_branches, {:array, :text}, default: [])
    end

    create table(:guides, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)
      add(:order, :bigint, null: false)
      add(:name, :text, null: false)
      add(:text, :text, null: false, default: "")
      add(:text_html, :text)

      add(
        :library_version_id,
        references(:library_versions,
          column: :id,
          name: "guides_library_version_id_fkey",
          type: :uuid
        ),
        null: false
      )
    end

    create table(:functions, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)
      add(:name, :text, null: false)
      add(:arity, :bigint, null: false)
      add(:type, :text, null: false)
      add(:heads, {:array, :text}, default: [])
      add(:doc, :text, null: false, default: "")
      add(:doc_html, :text)
      add(:order, :bigint, null: false)

      add(
        :library_version_id,
        references(:library_versions,
          column: :id,
          name: "functions_library_version_id_fkey",
          type: :uuid
        ),
        null: false
      )

      add(:extension_id, :uuid, null: false)
      add(:module_id, :uuid, null: false)
    end

    create table(:extensions, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)
    end

    alter table(:modules) do
      modify(
        :extension_id,
        references(:extensions, column: :id, name: "modules_extension_id_fkey", type: :uuid)
      )
    end

    alter table(:functions) do
      modify(
        :extension_id,
        references(:extensions, column: :id, name: "functions_extension_id_fkey", type: :uuid)
      )
    end

    alter table(:functions) do
      modify(
        :module_id,
        references(:modules, column: :id, name: "functions_module_id_fkey", type: :uuid)
      )
    end

    alter table(:extensions) do
      add(:name, :text, null: false)
      add(:target, :text)
      add(:default_for_target, :boolean, default: false)
      add(:doc, :text, null: false, default: "")
      add(:doc_html, :text)
      add(:type, :text, null: false)
      add(:order, :bigint, null: false)

      add(
        :library_version_id,
        references(:library_versions,
          column: :id,
          name: "extensions_library_version_id_fkey",
          type: :uuid
        ),
        null: false
      )
    end

    create unique_index(:extensions, [:library_version_id, :name],
             name: "extensions_unique_name_by_library_version_index"
           )

    create table(:dsls, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("uuid_generate_v4()"), primary_key: true)
    end

    alter table(:options) do
      modify(:dsl_id, references(:dsls, column: :id, name: "options_dsl_id_fkey", type: :uuid))
    end

    alter table(:options) do
      modify(
        :library_version_id,
        references(:library_versions,
          column: :id,
          name: "options_library_version_id_fkey",
          type: :uuid
        )
      )
    end

    alter table(:options) do
      modify(
        :extension_id,
        references(:extensions, column: :id, name: "options_extension_id_fkey", type: :uuid)
      )
    end

    alter table(:dsls) do
      add(:name, :text, null: false)
      add(:doc, :text, null: false, default: "")
      add(:doc_html, :text)
      add(:examples, {:array, :text})
      add(:args, {:array, :text})
      add(:path, {:array, :text})
      add(:recursive_as, :text)
      add(:order, :bigint, null: false)
      add(:type, :text, null: false)

      add(
        :library_version_id,
        references(:library_versions,
          column: :id,
          name: "dsls_library_version_id_fkey",
          type: :uuid
        ),
        null: false
      )

      add(
        :extension_id,
        references(:extensions, column: :id, name: "dsls_extension_id_fkey", type: :uuid),
        null: false
      )

      add(:dsl_id, references(:dsls, column: :id, name: "dsls_dsl_id_fkey", type: :uuid))
    end
  end

  def down do
    drop(constraint(:dsls, "dsls_dsl_id_fkey"))

    drop(constraint(:dsls, "dsls_extension_id_fkey"))

    drop(constraint(:dsls, "dsls_library_version_id_fkey"))

    alter table(:dsls) do
      remove(:dsl_id)
      remove(:extension_id)
      remove(:library_version_id)
      remove(:type)
      remove(:order)
      remove(:recursive_as)
      remove(:path)
      remove(:args)
      remove(:examples)
      remove(:doc_html)
      remove(:doc)
      remove(:name)
    end

    drop(constraint(:options, "options_extension_id_fkey"))

    alter table(:options) do
      modify(:extension_id, :uuid)
    end

    drop(constraint(:options, "options_library_version_id_fkey"))

    alter table(:options) do
      modify(:library_version_id, :uuid)
    end

    drop(constraint(:options, "options_dsl_id_fkey"))

    alter table(:options) do
      modify(:dsl_id, :uuid)
    end

    drop(table(:dsls))

    drop_if_exists(
      unique_index(:extensions, [:library_version_id, :name],
        name: "extensions_unique_name_by_library_version_index"
      )
    )

    drop(constraint(:extensions, "extensions_library_version_id_fkey"))

    alter table(:extensions) do
      remove(:library_version_id)
      remove(:order)
      remove(:type)
      remove(:doc_html)
      remove(:doc)
      remove(:default_for_target)
      remove(:target)
      remove(:name)
    end

    drop(constraint(:functions, "functions_module_id_fkey"))

    alter table(:functions) do
      modify(:module_id, :uuid)
    end

    drop(constraint(:functions, "functions_extension_id_fkey"))

    alter table(:functions) do
      modify(:extension_id, :uuid)
    end

    drop(constraint(:modules, "modules_extension_id_fkey"))

    alter table(:modules) do
      modify(:extension_id, :uuid)
    end

    drop(table(:extensions))

    drop(constraint(:functions, "functions_library_version_id_fkey"))

    drop(table(:functions))

    drop(constraint(:guides, "guides_library_version_id_fkey"))

    drop(table(:guides))

    alter table(:libraries) do
      remove(:track_branches)
      remove(:display_name)
      remove(:name)
    end

    drop_if_exists(
      unique_index(:library_versions, [:library_id, :version],
        name: "library_versions_unique_version_for_library_index"
      )
    )

    drop(constraint(:library_versions, "library_versions_library_id_fkey"))

    alter table(:library_versions) do
      modify(:library_id, :uuid)
    end

    drop(table(:libraries))

    alter table(:library_versions) do
      remove(:library_id)
      remove(:processed)
      remove(:doc_html)
      remove(:doc)
      remove(:data)
      remove(:version)
    end

    drop(constraint(:modules, "modules_library_version_id_fkey"))

    alter table(:modules) do
      modify(:library_version_id, :uuid)
    end

    drop(table(:library_versions))

    drop(table(:modules))

    drop(table(:options))
  end
end
