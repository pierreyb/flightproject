class CreateAirlines < ActiveRecord::Migration
  def change
    create_table :airlines do |t|

      t.timestamps
    end
  end
end
