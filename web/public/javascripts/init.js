let myMap;
let markerCount = 0;
let markers = {};
let polylines = {};
let icon = L.icon({
  iconUrl: '/assets/img/marker.png',
  iconSize: [10, 10],
  iconAnchor: [5, 5]
});
let startIcon = L.icon({
  iconUrl: '/assets/img/start-marker.png',
  iconSize: [16, 16],
  iconAnchor: [8, 8]
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
        if (myMap) {
            return;
        }

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
    }, 100);
});

app.ports.routeCreate.subscribe(function() {
    myMap.on("click", onMapClick);
});

function onMarkerDrop(e) {
    app.ports.moveAnchor.send([e.target._leaflet_id, e.target._latlng.lat, e.target._latlng.lng]);
}

function markerPopup(marker) {
    return "<span style='cursor: pointer' onClick='removeMarker(" + marker + ")'>Delete Point</span>";
}

function onMarkerRightClick(e) {
    e.target.openPopup();
}

function removeMarker(marker) {
    markers[marker].remove();
    markerCount--;
    app.ports.removeAnchor.send(marker);
}

function onMapClick(e) {
    let maxDistX = window.innerWidth / 2;
    let posX = Math.abs(e.originalEvent.x - maxDistX);
    let panX = 0.6 * posX / maxDistX + 0.25;
    let maxDistY = window.innerHeight / 2;
    let posY = Math.abs(e.originalEvent.y - maxDistY);
    let panY = 0.6 * posY / maxDistY + 0.25;
    let panDuration = Math.max(panX, panY);

    let marker;
    if (markerCount == 0) {
        marker = L.marker(
            [e.latlng.lat, e.latlng.lng],
            { draggable: true, icon: startIcon }
        ).addTo(e.target);
    } else {
        marker = L.marker(
            [e.latlng.lat, e.latlng.lng],
            { draggable: true, icon: icon }
        ).addTo(e.target);
        marker.bindPopup(markerPopup(marker._leaflet_id));
    }
    marker.on("dragend", onMarkerDrop);
    marker.on("contextmenu", onMarkerRightClick);
    markers[marker._leaflet_id] = marker;
    markerCount++;
    myMap.panTo(e.latlng, {duration: panDuration});
    app.ports.setAnchor.send([marker._leaflet_id, e.latlng.lat, e.latlng.lng]);
}

// DROP MAP
app.ports.down.subscribe(function() {
    if (myMap) {
        myMap.remove();
        myMap = null;
    }
});

// SNAP ANCHOR
app.ports.snapAnchor.subscribe(function(values) {
    let pointId = values[0];
    let point = values[1];
    let anchor = markers[pointId];
    anchor.setLatLng(L.latLng(point.lat, point.lng));
});

// PLOT ROUTE
app.ports.displayRoute.subscribe(function(line) {
    polyline = L.polyline(line[1], {color: 'black', opacity: 0.5, weight: 5});
    polyline.addTo(myMap);
    polylines[line[0]] = polyline;
});

app.ports.removeRoute.subscribe(function(route) {
    polylines[route].remove();
});

// CLEAR ROUTE
app.ports.clearRoute.subscribe(function() {
    myMap.removeEventListener("click", onMapClick);
    for (let key in markers) {
        markers[key].remove();
    }
    markerCount = 0;
    for (let key in polylines) {
        polylines[key].remove();
    }
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
