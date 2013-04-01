class Airport < ActiveRecord::Base
  # attr_accessible :title, :body
  acts_as_mappable :default_units => :kms,
    :default_formula => :sphere,
    :lat_column_name => :latitude,
    :lng_column_name => :longitude
end
