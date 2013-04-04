var mapButtonOriginalEventHandler = function() { 
    initialize_map() ;
    $('#mapButton').unbind('click') ;
    $('#mapButton').bind('click',mapButtonShowMapEventHandler);
    
};

var mapButtonShowMapEventHandler = function() { 
    hide_map() ;
    $('#mapButton').unbind('click') ;
    $('#mapButton').bind('click',mapButtonHideMapEventHandler);
};


var mapButtonHideMapEventHandler = function() { 
    show_map() ;
    $('#mapButton').unbind('click') ;
    $('#mapButton').bind('click',mapButtonShowMapEventHandler);
};


$(document).ready(function () {
    $('#mapButton').bind('click',mapButtonOriginalEventHandler);
});


function initialize_map() {    
    initialize_map_orig() ;
    initialize_map_dest() ;
    
    show_map();
}

function initialize_map_orig() {
    var LatLng = new google.maps.LatLng(gon.coordinate_orig[0],gon.coordinate_orig[1]) ;
    
    var mapProp = {
        center: LatLng,
        zoom: 6,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        mapTypeControl: false,
        streetViewControl: false        
    };

    var mapOrig = new google.maps.Map(document.getElementById("mapOrig"),mapProp);
    
    var markerOrig = new google.maps.Marker({
    	position: LatLng,
    	map: mapOrig
    });
        
    var markerAiportOrig = [] ;
    
    for (i in gon.airports_orig) {
    	var AirportLatLng = new google.maps.LatLng(gon.airports_orig[i]["latitude"],gon.airports_orig[i]["longitude"]) ;
    	marker = new google.maps.Marker({
    		position: AirportLatLng,
    		map: mapOrig,
    		title: gon.airports_orig[i]["fullname"]
    	});
    	markerAiportOrig.push(marker) ;
    }
}

function initialize_map_dest() {
    var LatLng = new google.maps.LatLng(gon.coordinate_dest[0],gon.coordinate_dest[1]) ;
    
    var mapProp = {
        center: LatLng,
        zoom: 6,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        mapTypeControl: false,
        streetViewControl: false        
    };

    var mapDest=new google.maps.Map(document.getElementById("mapDest"),mapProp);

    var markerDest = new google.maps.Marker({
    	position: LatLng,
    	map: mapDest
    });
        
    var markerAiportDest = [] ;

    for (i in gon.airports_dest) {
    	var AirportLatLng = new google.maps.LatLng(gon.airports_dest[i]["latitude"],gon.airports_dest[i]["longitude"]) ;
    	marker = new google.maps.Marker({
    		position: AirportLatLng,
    		map: mapDest,
    		title: gon.airports_dest[i]["fullname"] 
    	});
    	markerAiportDest.push(marker) ;
    }

}

function hide_map() {
    $('#mapButton').text('t.site.show.map') ;    
    $('#mapOrig').hide() ;
    $('#mapDest').hide() ;
}

function show_map() {
    $('#mapButton').text('t.site.hide.map') ;
    $('#mapOrig').show() ;    
    $('#mapDest').show() ;
//$("#mapButton").unbind('click', mapButtonOriginalEventHandler).click(mapButtonShowMapEventHandler);

}

