class CreateRoutes < ActiveRecord::Migration
  def change
    create_table "routes", :id => false, :force => true do |t|
      t.string  "airline",           :limit => 2
      t.string  "airline_id",        :limit => 5
      t.string  "source_airport",    :limit => 3
      t.string  "source_airport_id", :limit => 4
      t.string  "dest_airport",      :limit => 3
      t.string  "dest_airport_id",   :limit => 4
      t.string  "codeshare",         :limit => 1
      t.integer "stops"
      t.string  "equipment",         :limit => 15
    end
  end
end
