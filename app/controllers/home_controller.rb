class HomeController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'rexml/document'
  
  def search_routes
    
    query_orig = params[:query_orig]    
    query_dest = params[:query_dest]

    # Check that query value are present or redirect
    if (query_orig.empty? or query_dest.empty?)
      render :controller => "home", 
        :action => "index" and return
    end
    
    
    # Get latitude and longiture from departure and arrival adress
    @adress_orig = loc_search_geocoder(query_orig)    
    @adress_dest = loc_search_geocoder(query_dest)
    
    if (@adress_orig.empty? or @adress_dest.empty?)
      if (@adress_orig.empty?)
        @adress_orig.push({
          :address => "",
          :name => "",
          :suffix => ""})
      end
      if (@adress_dest.empty?)
        @adress_dest.push({
          :address => "",
          :name => "",
          :suffix => ""})
      end
      render :action => "results" and return
    end
    
    # Get list of airport near origin and adress
    adress = @adress_orig.first
    coordinate = [adress[:lat],adress[:lon]]
    gon.coordinate_orig = coordinate
    @airports_orig = airport_search_nearby(coordinate)
    
    adress = @adress_dest.first
    coordinate = [adress[:lat],adress[:lon]]
    gon.coordinate_dest = coordinate
    @airports_dest = airport_search_nearby(coordinate)

    airports_orig_id = Array.new
    @airports_orig.each do |airport|
      airports_orig_id.push(airport.id)
      airport["fullname"] = airport.name + " ( " + airport.city + ", " + airport.country + " )"
    end

    airports_dest_id = Array.new
    @airports_dest.each do |airport|
      airports_dest_id.push(airport.id)
      airport["fullname"] = airport.name + " ( " + airport.city + ", " + airport.country + " )"
    end

    # Get all routes with from orig to dest
    @routes = route_search(airports_orig_id, airports_dest_id)
    
    # Flag all the airports for which a route exist
    
    @routes.each do |route|
      # Get airline fullname
      route["airline_name"] = Airline.find(route[:airline_id]).name

      # Get original airport info
      index = @airports_orig.rindex{|airport| airport["id"] == route[:source_airport_id].to_i}
      @airports_orig[index]["used"] = "true"   
      route["orig_airport_name"] = @airports_orig[index]["name"]
      route["orig_distance"] = (@airports_orig[index][:distance]).round

      # Get finale airport info
      index = @airports_dest.rindex{|airport| airport["id"] == route[:dest_airport_id].to_i}
      @airports_dest[index]["used"] = "true"     
      route["dest_airport_name"] = @airports_dest[index]["name"]
      route["dest_distance"] = (@airports_dest[index][:distance]).round

      route["tot_distance"] = route["orig_distance"] + route["dest_distance"]
    end
    
    # Select only the airports used
    @airports_orig.select!{|airport| airport["used"] == "true"}
    @airports_dest.select!{|airport| airport["used"] == "true"}
    gon.airports_orig = @airports_orig
    gon.airports_dest = @airports_dest
    
    # Sort the destination by distance of both airport
    @routes.sort! {|r1,r2| r1["tot_distance"] <=> r2["tot_distance"]}
    render :action => "results"
    
  end
  
  private  
  
  # Localisation search tools
  def loc_search
    @query = params[:query]
    @sources = Array.new

    @query.sub(/^\s+/, "")
    @query.sub(/\s+$/, "")

    if @query.match(/^[+-]?\d+(\.\d*)?\s*[\s,]\s*[+-]?\d+(\.\d*)?$/)
      @sources.push "latlon"
    elsif @query.match(/^\d{5}(-\d{4})?$/)
      @sources.push "us_postcode"
      @sources.push "osm_nominatim"
    elsif @query.match(/^(GIR 0AA|[A-PR-UWYZ]([0-9]{1,2}|([A-HK-Y][0-9]|[A-HK-Y][0-9]([0-9]|[ABEHMNPRV-Y]))|[0-9][A-HJKS-UW])\s*[0-9][ABD-HJLNP-UW-Z]{2})$/i)
      @sources.push "uk_postcode"
      @sources.push "osm_nominatim"
    elsif @query.match(/^[A-Z]\d[A-Z]\s*\d[A-Z]\d$/i)
      @sources.push "ca_postcode"
      @sources.push "osm_nominatim"
    else
      # @sources.push "osm_nominatim" 
      # @sources.push "geonames" if defined?(GEONAMES_USERNAME) 
      @sources.push "geocoder"
    end
  end

  def loc_search_latlon
    # get query parameters
    query = params[:query]

    # create result array
    @results = Array.new

    # decode the location
    if m = query.match(/^\s*([+-]?\d+(\.\d*)?)\s*[\s,]\s*([+-]?\d+(\.\d*)?)\s*$/)
      lat = m[1].to_f
      lon = m[3].to_f
    end

    # generate results
    if lat < -90 or lat > 90
      @error = "Latitude #{lat} out of range"
      render :action => "error"
    elsif lon < -180 or lon > 180
      @error = "Longitude #{lon} out of range"
      render :action => "error"
    else
      @results.push({:lat => lat, :lon => lon,
          :zoom => POSTCODE_ZOOM,
          :name => "#{lat}, #{lon}"})

      render :action => "results"
    end
  end

  def loc_search_us_postcode
    # get query parameters
    query = params[:query]

    # create result array
    @results = Array.new

    # ask geocoder.us (they have a non-commercial use api)
    response = fetch_text("http://rpc.geocoder.us/service/csv?zip=#{escape_query(query)}")

    # parse the response
    unless response.match(/couldn't find this zip/)
      data = response.split(/\s*,\s+/) # lat,long,town,state,zip
      @results.push({:lat => data[0], :lon => data[1],
          :zoom => POSTCODE_ZOOM,
          :prefix => "#{data[2]}, #{data[3]},",
          :name => data[4]})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting rpc.geocoder.us: #{ex.to_s}"
    render :action => "error"
  end

  def loc_search_uk_postcode
    # get query parameters
    query = params[:query]

    # create result array
    @results = Array.new

    # ask npemap.org.uk to do a combined npemap + freethepostcode search
    response = fetch_text("http://www.npemap.org.uk/cgi/geocoder.fcgi?format=text&postcode=#{escape_query(query)}")

    # parse the response
    unless response.match(/Error/)
      dataline = response.split(/\n/)[1]
      data = dataline.split(/,/) # easting,northing,postcode,lat,long
      postcode = data[2].gsub(/'/, "")
      zoom = POSTCODE_ZOOM - postcode.count("#")
      @results.push({:lat => data[3], :lon => data[4], :zoom => zoom,
          :name => postcode})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting www.npemap.org.uk: #{ex.to_s}"
    render :action => "error"
  end

  def loc_search_ca_postcode
    # get query parameters
    query = params[:query]
    @results = Array.new

    # ask geocoder.ca (note - they have a per-day limit)
    response = fetch_xml("http://geocoder.ca/?geoit=XML&postal=#{escape_query(query)}")

    # parse the response
    if response.get_elements("geodata/error").empty?
      @results.push({:lat => response.get_text("geodata/latt").to_s,
          :lon => response.get_text("geodata/longt").to_s,
          :zoom => POSTCODE_ZOOM,
          :name => query.upcase})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting geocoder.ca: #{ex.to_s}"
    render :action => "error"
  end

  def loc_search_osm_nominatim
    # get query parameters
    query = params[:query]
    minlon = params[:minlon]
    minlat = params[:minlat]
    maxlon = params[:maxlon]
    maxlat = params[:maxlat]

    # get view box
    if minlon && minlat && maxlon && maxlat
      viewbox = "&viewbox=#{minlon},#{maxlat},#{maxlon},#{minlat}"
    end

    # get objects to excude
    if params[:exclude]
      exclude = "&exclude_place_ids=#{params[:exclude].join(',')}"
    end

    # ask nominatim
    response = fetch_xml("#{NOMINATIM_URL}search?format=xml&q=#{escape_query(query)}#{viewbox}#{exclude}&accept-language=#{request.user_preferred_languages.join(',')}")

    # create result array
    @results = Array.new

    # create parameter hash for "more results" link
    @more_params = params.reverse_merge({ :exclude => [] })

    # extract the results from the response
    results =  response.elements["searchresults"]

    # parse the response
    results.elements.each("place") do |place|
      lat = place.attributes["lat"].to_s
      lon = place.attributes["lon"].to_s
      klass = place.attributes["class"].to_s
      type = place.attributes["type"].to_s
      name = place.attributes["display_name"].to_s
      min_lat,max_lat,min_lon,max_lon = place.attributes["boundingbox"].to_s.split(",")
      prefix_name = t "geocoder.search_osm_nominatim.prefix.#{klass}.#{type}", :default => type.gsub("_", " ").capitalize
      prefix = t "geocoder.search_osm_nominatim.prefix_format", :name => prefix_name

      @results.push({:lat => lat, :lon => lon,
          :min_lat => min_lat, :max_lat => max_lat,
          :min_lon => min_lon, :max_lon => max_lon,
          :prefix => prefix, :name => name})
      @more_params[:exclude].push(place.attributes["place_id"].to_s)
    end

    render :action => "results"
    #  rescue Exception => ex
    #    @error = "Error contacting nominatim.openstreetmap.org: #{ex.to_s}"
    #    render :action => "error"
  end

  def loc_search_geonames
    # get query parameters
    query = params[:query]

    # create result array
    @results = Array.new

    # ask geonames.org
    response = fetch_xml("http://api.geonames.org/search?q=#{escape_query(query)}&maxRows=20&username=#{GEONAMES_USERNAME}")

    # parse the response
    response.elements.each("geonames/geoname") do |geoname|
      lat = geoname.get_text("lat").to_s
      lon = geoname.get_text("lng").to_s
      name = geoname.get_text("name").to_s
      country = geoname.get_text("countryName").to_s
      @results.push({:lat => lat, :lon => lon,
          :zoom => GEONAMES_ZOOM,
          :name => name,
          :suffix => ", #{country}"})
    end

    render :action => "results"
  rescue Exception => ex
    @error = "Error contacting ws.geonames.org: #{ex.to_s}"
    render :action => "error"
  end

  def loc_search_geocoder(query)

    # ask Geocoder
    response = Geocoder.search(query)
    
    # create result array
    @results = Array.new
    
    response.each do |geoname|
      lat = geoname.latitude
      lon = geoname.longitude
      address = geoname.address
      name = geoname.formatted_address
      country = geoname.country
      @results.push({:lat => lat, :lon => lon,
          :address => address,
          :name => name,
          :suffix => ", #{country}"})

    end
    
    return @results
    
    #  rescue Exception => ex
    #    @error = "Error contacting nominatim.openstreetmap.org: #{ex.to_s}"
    #    render :action => "error"
  end

  def fetch_text(url)
    return Net::HTTP.get(URI.parse(url))
  end

  def fetch_xml(url)
    return REXML::Document.new(fetch_text(url))
  end

  def format_distance(distance)
    return t("geocoder.distance", :count => distance)
  end

  def format_direction(bearing)
    return t("geocoder.direction.south_west") if bearing >= 22.5 and bearing < 67.5
    return t("geocoder.direction.south") if bearing >= 67.5 and bearing < 112.5
    return t("geocoder.direction.south_east") if bearing >= 112.5 and bearing < 157.5
    return t("geocoder.direction.east") if bearing >= 157.5 and bearing < 202.5
    return t("geocoder.direction.north_east") if bearing >= 202.5 and bearing < 247.5
    return t("geocoder.direction.north") if bearing >= 247.5 and bearing < 292.5
    return t("geocoder.direction.north_west") if bearing >= 292.5 and bearing < 337.5
    return t("geocoder.direction.west")
  end

  def format_name(name)
    return name.gsub(/( *\[[^\]]*\])*$/, "")
  end

  def count_results(results)
    count = 0

    results.each do |source|
      count += source[:results].length if source[:results]
    end

    return count
  end

  def escape_query(query)
    return URI.escape(query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]", false, 'N'))
  end
  
  def airport_search_nearby(coordinate)
    
    # Get default distance 
    dist = "#{AIRPORT_SEARCH_DISTANCE}"
    
       
    @airports = Array.new

    @airports = Airport.geo_scope(:origin=>coordinate, :within=>dist).order(:distance)
  end
    
  def route_search(orig_airport_id, dest_airport_id)
    
    @routes = Route.where({:source_airport_id => orig_airport_id, 
        :dest_airport_id => dest_airport_id }
    )
      
  end 
  
end
