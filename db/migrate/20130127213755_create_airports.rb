class CreateAirports < ActiveRecord::Migration
  def change
    create_table "airports", :force => true do |t|
      t.string  "name",      :limit => 64
      t.string  "city",      :limit => 64
      t.string  "country",   :limit => 32
      t.string  "code",      :limit => 3
      t.string  "icao",      :limit => 4
      t.decimal "latitude",                :precision => 9, :scale => 6
      t.decimal "longitude",               :precision => 9, :scale => 6
      t.integer "altitude"
      t.decimal "timezone",                :precision => 5, :scale => 2
      t.string  "dst",       :limit => 1
    end
  end
end
