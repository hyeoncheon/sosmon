class CreateTests < ActiveRecord::Migration
  def change
    create_table :tests do |t|
      t.string :name, :null => false
      t.references :service, :null => false
      t.string :check_url, :null => false
      t.string :uuid
      t.boolean :enabled, :default => true
      t.string :tags
      t.string :opmode
      t.string :status

      t.timestamps
    end
    add_index :tests, :service_id
  end
end
