class CreateAirlines < ActiveRecord::Migration
  def change
    create_table "airlines", :force => true do |t|
      t.string "name",     :limit => 81
      t.string "alias",    :limit => 33
      t.string "iata",     :limit => 4
      t.string "icao",     :limit => 5
      t.string "callsign", :limit => 50
      t.string "country",  :limit => 37
      t.string "active",   :limit => 1
    end
  end
end
