class AddNameToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :name, :string
  end
end
