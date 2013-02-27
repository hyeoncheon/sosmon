class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :name
      t.string :portfolio
      t.string :tags
      t.references :client
      t.text :desc

      t.timestamps
    end
    add_index :services, :client_id
  end
end
