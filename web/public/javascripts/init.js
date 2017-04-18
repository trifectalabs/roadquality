let node = document.getElementById("elm-content");
let app = Elm.App.embed(node);

let mymap;
let markers = {};
let polyline;
let icon = L.icon({
  iconUrl: '/assets/img/marker.png',
  iconSize: [10, 10],
  iconAnchor: [5, 5]
});

// SETUP MAP
app.ports.up.subscribe(function() {
  myMap = L.map("MainView").setView([43.48,-80.51], 13);

  L.tileLayer("http://{s}.tile.osm.org/{z}/{x}/{y}.png", {
    attribution: "&copy; <a href='http://osm.org/copyright'>OpenStreetMap</a> contributors"
  }).addTo(myMap);

  function onMapClick(e) {
    var marker = L.marker([e.latlng.lat, e.latlng.lng], {draggable: true, icon: icon}).addTo(e.target);
    app.ports.setAnchor.send([marker._leaflet_id, e.latlng.lat, e.latlng.lng]);
    marker.on("dragend", onMarkerDrop);
    markers[marker._leaflet_id] = marker;
  }

  myMap.on("click", onMapClick);
});

function onMarkerDrop(e) {
  app.ports.setAnchor.send([e.target._leaflet_id, e.target._latlng.lat, e.target._latlng.lng]);
}

// SNAP ANCHOR
app.ports.snapAnchor.subscribe(function(values) {
    let pointId = values[0];
    let point = values[1];
    let anchor = markers[pointId];
    anchor.setLatLng(L.latLng(point.lat, point.lng));
});

// PLOT ROUTE
app.ports.displayRoute.subscribe(function(line) {
    if (polyline) {
        polyline.remove();
    }
    polyline = L.polyline(line, {color: 'red'});
    polyline.addTo(myMap);
});

// CLEAR ROUTE
app.ports.clearRoute.subscribe(function() {
  for (let key in markers) {
    markers[key].remove();
  }
  for (j = 0; j < markers.length; j++) {
    polylines[j].remove();
  }
});
