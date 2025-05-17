class CreateQuotes < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
    create_table :quotes, id: :uuid do |t|
      t.string :path
      t.string :name
      t.text :md
      t.jsonb :structured
      t.string :reference_url

      t.timestamps
    end
  end
end
