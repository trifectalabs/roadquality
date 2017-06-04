let myMap;
let markers = {};
let polyline;
let icon = L.icon({
  iconUrl: '/assets/img/marker.png',
  iconSize: [10, 10],
  iconAnchor: [5, 5]
});

// STORE SESSION
app.ports.storeSession.subscribe(function(session) {
    localStorage.session = session;
});

// SESSION CHANGE
window.addEventListener("storage", function(event) {
    if (event.storageArea === localStorage && event.key === "session") {
        app.ports.onSessionChange.send(event.newValue);
    }
}, false);

// SETUP MAP
app.ports.up.subscribe(function(authed) {
    // TODO: there must be a better way :(
    setTimeout(function() {
        myMap = L.map("MainView", {
            center: [43.652684, -79.397991],
            zoom: 13,
            zoomControl: false
        });

        L.tileLayer("https://tiles.roadquality.org/roadquality/{z}/{x}/{y}.png", {
            attribution: "&copy; <a href='https://trifectalabs.com'>Trifecta Labs</a> & <a href='http://osm.org/copyright'>OpenStreetMap</a> contributors"
        }).addTo(myMap);

        L.control.zoom({position: "bottomright"}).addTo(myMap);
        createBounds();

        function onMapClick(e) {
            var marker = L.marker([e.latlng.lat, e.latlng.lng], {draggable: true, icon: icon}).addTo(e.target);
            app.ports.setAnchor.send([marker._leaflet_id, e.latlng.lat, e.latlng.lng]);
            marker.on("dragend", onMarkerDrop);
            markers[marker._leaflet_id] = marker;
        }

        if (authed) {
            myMap.on("click", onMapClick);
        }
    }, 100);
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
  polyline.remove();
});

// ROUTING BOUNDS
function createBounds() {
  var pointA = new L.LatLng(43.753963, -79.632868);
  var pointB = new L.LatLng(43.561912, -79.632868);
  var pointC = new L.LatLng(43.561912, -79.194903);
  var pointD = new L.LatLng(43.753963, -79.194903);
  var pointList = [pointA, pointB, pointC, pointD, pointA];

  var firstpolyline = new L.Polyline(pointList, {
      color: 'red',
      weight: 3,
      opacity: 0.5,
      smoothFactor: 1
  });
  firstpolyline.addTo(myMap);
}
