let map;
let canvas;
let markerCount = 0;
let markers = {};
let startMarker = "startMarker";
let startMarkerUnused = false;
let unusedMarkers = [];
let routes = {};
let unusedRoutes = [];
let polylines = {};
let cursorOverPoint = null;
let isDragging = false;
let viewOnly = true;
let popup;

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
        if (map) {
            return;
        }

        mapboxgl.accessToken = "pk.eyJ1Ijoia2lhbWJvZ28iLCJhIjoiY2l2MWVqdWdpMDBiMDJ5bXB5aXdyY3JrdyJ9.oqpLQhZcd0yOzBKdSxyk2w";

        map = new mapboxgl.Map({
            container: "MainView",
            style: "mapbox://styles/mapbox/light-v9",
            center: [-79.412190, 43.667632],
            zoom: 10
        });

        canvas = map.getCanvasContainer();
        canvas.style.cursor = "default";
        map.on("load", createBounds);
        map.on("mousedown", onMapMouseDown);
        map.on("mouseup", onMapMouseUp);
    }, 100);
});

app.ports.routeCreate.subscribe(function() {
    viewOnly = false;
    map.on("click", onMapClick);
    map.on("contextmenu", onMapRightClick);
});

function onMapMouseUp(e) {
    canvas.style.cursor = "default";
}

function onMapMouseDown(e) {
    if (cursorOverPoint === null || viewOnly) {
        canvas.style.cursor = "move";
        return;
    }
    isDragging = true;
    canvas.style.cursor = "grabbing";
    map.on("mousemove", onMoveMarker);
    map.once("mouseup", onDropMarker);
}

function onMoveMarker(e) {
    if (!isDragging) return;
    canvas.style.cursor = "grabbing";
    let coords = e.lngLat;
    markers[cursorOverPoint].features[0].geometry.coordinates = [coords.lng, coords.lat];
    map.getSource(cursorOverPoint).setData(markers[cursorOverPoint]);
}

function onDropMarker(e) {
    if (!isDragging) return;
    let coords = e.lngLat;
    app.ports.moveAnchor.send([cursorOverPoint, coords.lat, coords.lng]);

    canvas.style.cursor = "default";
    isDragging = false;

    map.off("mousemove", onMoveMarker);
}

function onMapClick(e) {
    if (cursorOverPoint !== null || isDragging) return;
    let id;
    if (unusedMarkers.length > 0 || startMarkerUnused) {
        if (startMarkerUnused) {
            id = startMarker;
            startMarkerUnused = false;
        } else {
            id = unusedMarkers.pop();
        }
        markers[id].features = [{
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [e.lngLat.lng, e.lngLat.lat]
            }
        }];
        map.getSource(id).setData(markers[id]);
    } else {
        if (markerCount === 0) {
            id = startMarker;
        } else {
            id = Math.random().toString(36).substr(2, 10);
        }
        let markerSource = {
            "type": "FeatureCollection",
            "features": [{
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [e.lngLat.lng, e.lngLat.lat]
                }
            }]
        };
        map.addSource(id, {
            "type": "geojson",
            "data": markerSource
        });
        markers[id] = markerSource;

        if (markerCount === 0) {
            map.addLayer({
                "id": id,
                "type": "circle",
                "source": id,
                "paint": {
                    "circle-radius": 7,
                    "circle-color": "#40B34F",
                    "circle-stroke-color": "#FFFFFF",
                    "circle-stroke-width": 2
                }
            });
        } else {
            map.addLayer({
                "id": id,
                "type": "circle",
                "source": id,
                "paint": {
                    "circle-radius": 4,
                    "circle-color": "#FFFFFF",
                    "circle-stroke-width": 2
                }
            });
        }
    }

    map.on("mouseenter", id, function() {
        canvas.style.cursor = "grab";
        cursorOverPoint = id;
        map.dragPan.disable();
    });

    map.on("mouseleave", id, function() {
        if (isDragging) return;
        canvas.style.cursor = "default";
        cursorOverPoint = null;
        map.dragPan.enable();
    });

    let maxDistX = window.innerWidth / 2;
    let posX = Math.abs(e.originalEvent.x - maxDistX);
    let panX = 0.6 * posX / maxDistX + 0.25;
    let maxDistY = window.innerHeight / 2;
    let posY = Math.abs(e.originalEvent.y - maxDistY);
    let panY = 0.6 * posY / maxDistY + 0.25;
    let panDuration = Math.max(panX, panY) * 1000;
    map.panTo(e.lngLat, { duration: panDuration });

    markerCount++;
    app.ports.setAnchor.send([id, e.lngLat.lat, e.lngLat.lng]);
}

function onMapRightClick(e) {
    if (cursorOverPoint !== null && cursorOverPoint !== startMarker) {
        if (popup) {
            popup.remove();
        }
        popup = new mapboxgl.Popup()
            .setLngLat(e.lngLat)
            .setHTML("<span style='cursor: pointer' onClick='removeMarker(\"" + cursorOverPoint + "\")'>Delete Point</span>")
            .addTo(map);
    }
}

function removeMarker(key) {
    popup.remove();
    markers[key].features = [];
    unusedMarkers.push(key);
    map.getSource(key).setData(markers[key]);
    markerCount--;
    app.ports.removeAnchor.send(key);
}

// DROP MAP
app.ports.down.subscribe(function() {
    if (map) {
        map.remove();
        map = null;
    }
});

// SNAP ANCHOR
app.ports.snapAnchor.subscribe(function(values) {
    let pointId = values[0];
    let point = values[1];
    markers[pointId].features[0].geometry.coordinates = [point.lng, point.lat];
    map.getSource(pointId).setData(markers[pointId]);
});

// PLOT ROUTE
app.ports.displayRoute.subscribe(function(line) {
    let lineId = line[0];
    let [ firstPoint, secondPoint ] = lineId.split("_");
    let lineCoords = [];
    for (let i = 0; i < line[1].length; i++) {
        lineCoords.push([line[1][i][1], line[1][i][0]]);
    }

    let id;
    if (unusedRoutes.length > 0) {
        id = unusedRoutes.pop();
        routes[id].features = [{
            "type": "Feature",
            "geometry": {
                "type": "LineString",
                "coordinates": lineCoords
            }
        }];
        map.getSource(id).setData(routes[id]);
        polylines[lineId] = id;
    } else {
        id = Math.random().toString(36).substr(2, 10);
        let routeSource = {
            "type": "FeatureCollection",
            "features": [{
                "type": "Feature",
                "geometry": {
                    "type": "LineString",
                    "coordinates": lineCoords
                }
            }]
        };
        map.addSource(id, {
            "type": "geojson",
            "data": routeSource
        });
        routes[id] = routeSource;
        polylines[lineId] = id;
        map.addLayer({
            "id": id,
            "type": "line",
            "source": id,
            "paint": {
                "line-opacity": 0.5,
                "line-width": 5
            }
        });
    }
    map.moveLayer(id, firstPoint);
});

app.ports.removeRoute.subscribe(function(route) {
    id = polylines[route];
    routes[id].features = [];
    unusedRoutes.push(id);
    map.getSource(id).setData(routes[id]);
});

// CLEAR ROUTE
app.ports.clearRoute.subscribe(function() {
    viewOnly = true;
    map.off("click", onMapClick);
    map.off("contextmenu", onMapRightClick);
    for (let key in markers) {
        markers[key].features = [];
        if (key === startMarker) {
            startMarkerUnused = true;
        } else {
            unusedMarkers.push(key);
        }
        map.getSource(key).setData(markers[key]);
    }
    markerCount = 0;
    for (let key in polylines) {
        id = polylines[key];
        routes[id].features = [];
        unusedRoutes.push(id);
        map.getSource(id).setData(routes[id]);
    }
});

// ROUTING BOUNDS
function createBounds() {
    let geojson = {
        "type": "FeatureCollection",
        "features": [{
            "type": "Feature",
            "geometry": {
                "type": "Polygon",
                "coordinates": [[
                    [ -79.632868, 43.753963 ],
                    [ -79.632868, 43.561912 ],
                    [ -79.194903, 43.561912 ],
                    [ -79.194903, 43.753963 ],
                    [ -79.632868, 43.753963 ]
                ]]
            }
        }]
    }
    map.addSource("routingbounds", {
        "type": "geojson",
        "data": geojson
    });
    map.addLayer({
        "id": "routingbounds",
        "type": "line",
        "source": "routingbounds",
        "paint": {
            "line-color": "green",
            "line-opacity": 0.5,
            "line-width": 3
        }
    });
}
