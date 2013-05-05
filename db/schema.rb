# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "airlines", :force => true do |t|
    t.string "name",     :limit => 81
    t.string "alias",    :limit => 33
    t.string "iata",     :limit => 4
    t.string "icao",     :limit => 5
    t.string "callsign", :limit => 50
    t.string "country",  :limit => 37
    t.string "active",   :limit => 1
  end

  create_table "airlines_routes_backup", :id => false, :force => true do |t|
    t.string  "airline",           :limit => 2
    t.string  "airline_id",        :limit => 5
    t.string  "source_airport",    :limit => 3
    t.string  "source_airport_id", :limit => 4
    t.string  "dest_airport",      :limit => 3
    t.string  "dest_aiport_id",    :limit => 4
    t.string  "codeshare",         :limit => 1
    t.integer "stops"
    t.string  "equipment",         :limit => 15
  end

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

  create_table "airports_complete", :force => true do |t|
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

  create_table "desc_dst", :primary_key => "dst_id", :force => true do |t|
    t.string "dst_description", :limit => 24
  end

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
