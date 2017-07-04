let map;
let canvas;
let cursorOverPoint = null;
let isDragging = false;
let viewOnly = true;
let popup;
let showingLayer;
let cursorClass;

let emptySource = {
    "type": "FeatureCollection",
    "features": []
};

let markerSource = function(coords) {
    return {
        "type": "FeatureCollection",
        "features": [{
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": coords
            }
        }]
    };
}

let surfaceLayer = {
    "id": "SurfaceQuality",
    "type": "line",
    "source": {
        type: "vector",
        tiles: ["https://tiles.roadquality.org/surface_quality/{z}/{x}/{y}.pbf"]
    },
    "source-layer": "surface_mini_segments",
    "paint": {
        "line-color": {
            "type": "identity",
            "property": "colour"
        },
        "line-width": 2
    }
};

let trafficLayer = {
    "id": "TrafficSafety",
    "type": "line",
    "source": {
        type: "vector",
        tiles: ["https://tiles.roadquality.org/traffic/{z}/{x}/{y}.pbf"]
    },
    "source-layer": "traffic_mini_segments",
    "paint": {
        "line-color": {
            "type": "identity",
            "property": "colour"
        },
        "line-width": 2
    }
};

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
app.ports.up.subscribe(function(location) {
    // TODO: there must be a better way :(
    setTimeout(function() {
        if (map) {
            return;
        } else if (location === null) {
            setupMap(location);
            return;
        }

        let city = location[0];
        let province = location[1];
        let country = location[2];
        let url = "https://maps.googleapis.com/maps/api/geocode/json?address=" + city + ",+" + province + ",+" + country + "&key=AIzaSyAzfXJoOAt7m6C4ocTX_-odOj739BqtXts";
        fetch(url).then(function(response) {
            return response.json();
        }).then(function(data) {
            let coords = data.results[0].geometry.location;
            setupMap(coords);
        });
    }, 100);
});

function setupMap(coords) {
    if (map) {
        return;
    }

    mapboxgl.accessToken = "pk.eyJ1Ijoia2lhbWJvZ28iLCJhIjoiY2l2MWVqdWdpMDBiMDJ5bXB5aXdyY3JrdyJ9.oqpLQhZcd0yOzBKdSxyk2w";

    let center, zoom;
    if (coords) {
        center = [coords.lng, coords.lat];
        zoom = 11;
    } else {
        center = [-75.93432, 51.46046];
        zoom = 4;
    }

    map = new mapboxgl.Map({
        container: "MainView",
        style: "mapbox://styles/mapbox/light-v9",
        center: center,
        zoom: zoom,
        maxZoom: 17
    });

    canvas = map.getCanvasContainer();
    cursorClass = "default-cursor";
    addClass(canvas, cursorClass);
    map.dragRotate.disable();
    map.touchZoomRotate.disableRotation();
    map.on("mousedown", onMapMouseDown);
    map.on("mouseup", onMapMouseUp);
    map.on("zoomend", function() { app.ports.zoomLevel.send(map.getZoom()); });

    showingLayer = "SurfaceQuality";
    map.on("load", function () {
        map.addLayer(Object.assign({}, surfaceLayer));
    });
}

app.ports.setLayer.subscribe(function(layer) {
    if (showingLayer === layer) {
        return;
    } else if (map.getLayer(layer)) {
        map.setLayoutProperty(showingLayer, "visibility", "none");
        map.setLayoutProperty(layer, "visibility", "visible");
    } else if (layer === "TrafficSafety") {
        map.setLayoutProperty(showingLayer, "visibility", "none");
        map.addLayer(Object.assign({}, trafficLayer));
    }
    showingLayer = layer;
});

app.ports.refreshLayer.subscribe(function(layer) {
    map.removeLayer(layer);
    map.removeSource(layer);
    if (layer === "SurfaceQuality") {
        let dirtySurfaceLayer = Object.assign({}, surfaceLayer);
        dirtySurfaceLayer.dirty = Math.random();
        dirtySurfaceLayer.source.tiles[0] += "?dirty=" + Math.random();
        map.addLayer(dirtySurfaceLayer);
    } else {
        let dirtyTrafficLayer = Object.assign({}, trafficLayer);
        dirtyTrafficLayer.dirty = Math.random();
        dirtyTrafficLayer.source.tiles[0] += "?dirty=" + Math.random();
        map.addLayer(dirtyTrafficLayer);
    }
});

app.ports.routeCreate.subscribe(function() {
    viewOnly = false;
    map.on("click", onMapClick);
    map.on("contextmenu", onMapRightClick);
});

function onMapMouseUp(e) {
    removeClass(canvas, cursorClass);
    cursorClass = "default-cursor";
    addClass(canvas, cursorClass);
}

function onMapMouseDown(e) {
    if (e.originalEvent.which !== 1) return;
    if (cursorOverPoint === null || viewOnly) {
        removeClass(canvas, cursorClass);
        cursorClass = "move-cursor";
        addClass(canvas, cursorClass);
        return;
    }
    isDragging = true;
    removeClass(canvas, cursorClass);
    cursorClass = "grabbing-cursor";
    addClass(canvas, cursorClass);
    map.on("mousemove", onMoveMarker);
    map.once("mouseup", onDropMarker);
}

function onMoveMarker(e) {
    if (!isDragging) return;
    removeClass(canvas, cursorClass);
    cursorClass = "grabbing-cursor";
    addClass(canvas, cursorClass);
    let coords = [e.lngLat.lng, e.lngLat.lat];
    map.getSource(cursorOverPoint).setData(markerSource(coords));
}

function onDropMarker(e) {
    if (!isDragging) return;
    let coords = e.lngLat;
    app.ports.moveAnchor.send([cursorOverPoint, coords.lng, coords.lat]);
    isDragging = false;
    map.off("mousemove", onMoveMarker);
}

function onMapClick(e) {
    if (cursorOverPoint !== null || isDragging) return;

    app.ports.setAnchor.send([e.lngLat.lng, e.lngLat.lat]);

    // Shift LngLat for map pan to compensate for open sidebar menu
    let mapBounds = map.getBounds();
    let mapMinX = mapBounds.getWest();
    let mapMaxX = mapBounds.getEast();
    let windowMinX = 0;
    let windowMaxX = window.innerWidth;
    let mapPosX = e.lngLat.lng;
    let mapPosY = e.lngLat.lat;
    let windowPosX = windowMaxX / (mapMaxX - mapMinX) * (mapPosX - mapMinX);
    let shiftedWindowPosX = windowPosX - 200;
    let shiftedMapPosX = mapMinX + (mapMaxX - mapMinX) / windowMaxX * shiftedWindowPosX;
    let shiftedLngLat = [shiftedMapPosX, mapPosY];

    // Calculate pan duration based on distance to pan
    let maxDistX = (window.innerWidth - 400) / 2;
    let posX = Math.abs(e.originalEvent.x - 400 - maxDistX);
    let panX = 0.25 + (0.6 / maxDistX) * (posX - 400);
    let maxDistY = window.innerHeight / 2;
    let posY = Math.abs(e.originalEvent.y - maxDistY);
    let panY = 0.25 + (0.6 / maxDistY) * posY;
    let panDuration = Math.max(panX, panY) * 1000;

    map.panTo(shiftedLngLat, { duration: panDuration });
}

app.ports.addAnchor.subscribe(function(anchor) {
    let id = anchor[0];
    let coords = [anchor[1], anchor[2]];
    if (map.getSource(id)) {
        map.getSource(id).setData(markerSource(coords));
    } else {
        map.addSource(id, {
            "type": "geojson",
            "data": markerSource(coords)
        });
        if (id === "startMarker") {
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
        removeClass(canvas, cursorClass);
        cursorClass = "grab-cursor";
        addClass(canvas, cursorClass);
        cursorOverPoint = id;
        map.dragPan.disable();
    });

    map.on("mouseleave", id, function() {
        if (isDragging) return;
        removeClass(canvas, cursorClass);
        cursorClass = "default-cursor";
        addClass(canvas, cursorClass);
        cursorOverPoint = null;
        map.dragPan.enable();
    });
});

function onMapRightClick(e) {
    if (cursorOverPoint !== null && cursorOverPoint !== "startMarker") {
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
    if (popup) {
        popup.remove();
    }
    map.getSource(key).setData(emptySource);
    app.ports.removedAnchor.send(key);
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
    let coords = [values[1].lng, values[1].lat];
    map.getSource(pointId).setData(markerSource(coords));
});

app.ports.removeAnchor.subscribe(function(pointId) {
    removeMarker(pointId);
});

// PLOT ROUTE
app.ports.displayRoute.subscribe(function(line) {
    let firstPoint = line[0];
    let id = line[1];
    let lineCoords = [];
    for (let i = 0; i < line[2].length; i++) {
        lineCoords.push([line[2][i][1], line[2][i][0]]);
    }
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
    if (map.getSource(id)) {
        map.getSource(id).setData(routeSource);
    } else {
        map.addSource(id, {
            "type": "geojson",
            "data": routeSource
        });
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

app.ports.removeRoute.subscribe(function(id) {
    if (!map.getSource(id)) return;
    map.getSource(id).setData(emptySource);
});

// CLEAR ROUTE
app.ports.clearRouting.subscribe(function(sources) {
    viewOnly = true;
    map.off("click", onMapClick);
    map.off("contextmenu", onMapRightClick);
    for (let i = 0; i < sources.length; i++) {
        map.getSource(sources[i]).setData(emptySource);
    }
});

// UTIL

// from http://www.openjs.com/scripts/dom/class_manipulation.php
function hasClass(ele, cls) {
    return ele.className.match(new RegExp('(\\s|^)' + cls + '(\\s|$)'));
}

function addClass(ele, cls) {
    if (!this.hasClass(ele, cls)) ele.className += " " + cls;
}

function removeClass(ele, cls) {
    if (hasClass(ele,cls)) {
        var reg = new RegExp('(\\s|^)' + cls + '(\\s|$)');
        ele.className = ele.className.replace(reg, ' ');
    }
}
