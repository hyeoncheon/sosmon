class CreateTests < ActiveRecord::Migration
  def change
    create_table :tests do |t|
      t.string :name
      t.references :service
      t.string :check_url
      t.string :uuid
      t.boolean :enabled
      t.string :tags
      t.string :opmode
      t.string :status

      t.timestamps
    end
    add_index :tests, :service_id
  end
end
