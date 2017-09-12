let map;
let canvas;
let cursorOverPoint = null;
let cursorOverSegment = null;
let selectedSegment = null;
let isDragging = false;
let viewOnly = true;
let segmentMode = false;
let popup;
let showingLayer;
let cursorClass;
let tileServerUrl;
let paintDict = {};
let hoverPaintDict = {};
let activePaintDict = {};
let selectedPaintDict = {};

if (location.host === "localhost:9000") {
    tileServerUrl = "http://localhost:8080"
} else {
    tileServerUrl = "https://tiles.roadquality.org"
}

let surfaceLayer = {
    "id": "SurfaceQuality",
    "type": "line",
    "source": {
        type: "vector",
        tiles: [tileServerUrl + "/surface_quality/{z}/{x}/{y}.pbf"]
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
        tiles: [tileServerUrl + "/traffic/{z}/{x}/{y}.pbf"]
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

// ELM PORTS

app.ports.storeSession.subscribe(function(session) {
    localStorage.session = session;
});

window.addEventListener("storage", function(event) {
    if (event.storageArea === localStorage && event.key === "session") {
        app.ports.onSessionChange.send(event.newValue);
    }
}, false);

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
        let url = "https://maps.googleapis.com/maps/api/geocode/json?address=" +
            city + ",+" + province + ",+" + country +
            "&key=AIzaSyAzfXJoOAt7m6C4ocTX_-odOj739BqtXts";
        fetch(url).then(function(response) {
            return response.json();
        }).then(function(data) {
            let coords = data.results[0].geometry.location;
            setupMap(coords);
        });
    }, 100);
});

app.ports.down.subscribe(function() {
    if (map) {
        map.remove();
        map = null;
    }
});

app.ports.setLayer.subscribe(function(layer) {
    if (showingLayer === layer) {
        return;
    } else if (map.getLayer(layer)) {
        map.setLayoutProperty(showingLayer, "visibility", "none");
        map.setLayoutProperty(layer, "visibility", "visible");
    }
    showingLayer = layer;
});

app.ports.refreshLayer.subscribe(function(layer) {
    map.removeLayer(layer);
    map.removeSource(layer);
    if (layer === "SurfaceQuality") {
        let dirtySurfaceLayer = Object.assign({}, surfaceLayer);
        dirtySurfaceLayer.source.tiles[0] += "?dirty=" + Math.random();
        map.addLayer(dirtySurfaceLayer);
        map.moveLayer(layer, "TrafficSafety");
    } else {
        let dirtyTrafficLayer = Object.assign({}, trafficLayer);
        dirtyTrafficLayer.source.tiles[0] += "?dirty=" + Math.random();
        map.addLayer(dirtyTrafficLayer);
        map.moveLayer(layer, "SurfaceQuality");
    }
});

app.ports.isRouting.subscribe(function(routing) {
    if (routing === "SegmentsMode" && !segmentMode) {
        map.on("mousedown", segmentMouseDown);
        map.on("click", segmentClick);
        map.off("click", click);
        map.off("contextmenu", contextMenu);
    } else if (routing === "CreateMode" && segmentMode) {
        map.on("click", click);
        map.on("contextmenu", contextMenu);
        map.off("mousedown", segmentMouseDown);
        map.off("click", segmentClick);
    } else if (routing === "") {
        map.off("mousedown", segmentMouseDown);
        map.off("click", segmentClick);
        map.off("click", click);
        map.off("contextmenu", contextMenu);
        for (let property in paintDict[selectedSegment]) {
            map.setPaintProperty(
                selectedSegment,
                property,
                paintDict[selectedSegment][property]
            );
        }
        selectedSegment = null;
    }
    viewOnly = routing === "";
    segmentMode = routing === "SegmentsMode";
});

app.ports.hideSources.subscribe(function(keys) {
    let emptySource = {
        "type": "FeatureCollection",
        "features": []
    };
    for (let i = 0; i < keys.length; i++) {
        map.getSource(keys[i]).setData(emptySource);
    }
});

app.ports.addSource.subscribe(function(values) {
    let key = values[0];
    let layerType = values[1];
    let coords = [];
    let geomType;
    let paint = values[3];
    let hoverPaint, activePaint, selectedPaint;
    if (values[4]) {
        hoverPaint = values[4][0];
        activePaint = values[4][1];
        selectedPaint = values[4][2];
    }
    if (values[2].length === 1) {
        coords = [values[2][0][0], values[2][0][1]];
        geomType = "Point";
    } else {
        for (let i = 0; i < values[2].length; i++) {
            coords.push([values[2][i][1], values[2][i][0]]);
        }
        geomType = "LineString";
    }
    let source = makeSource(geomType, coords);
    if (map.getSource(key)) {
        map.getSource(key).setData(source);
    } else {
        map.addSource(key, {
            "type": "geojson",
            "data": source
        });
        map.addLayer({
            "id": key,
            "type": layerType,
            "source": key,
            "paint": paint
        });
        if (geomType === "Point") {
            map.on("mouseenter", key, mouseEnter(key));
            map.on("mouseleave", key, mouseLeave);
        }
        if (hoverPaint || activePaint || selectedPaint) {
            paintDict[key] = paint;
            hoverPaintDict[key] = hoverPaint;
            activePaintDict[key] = activePaint;
            selectedPaintDict[key] = selectedPaint;
            map.on("mouseenter", key, mouseEnterSegment(key));
            map.on("mouseleave", key, mouseLeaveSegment(key));
        }
    }
    if (geomType === "LineString" && !hoverPaint) {
        map.moveLayer(key, "startMarker");
    }
});

// EVENT HANDLERS

function click(e) {
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
    let shiftedMapPosX =
        mapMinX + (mapMaxX - mapMinX) / windowMaxX * shiftedWindowPosX;
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

function contextMenu(e) {
    if (cursorOverPoint !== null && cursorOverPoint !== "startMarker") {
        if (popup) {
            popup.remove();
        }
        popup = new mapboxgl.Popup()
            .setLngLat(e.lngLat)
            .setHTML("<span style='cursor: pointer' onClick='removeMarker(\"" + 
                cursorOverPoint + "\")'>Delete Point</span>")
            .addTo(map);
    }
}

function mouseUp(e) {
    if (!isDragging) {
        removeClass(canvas, cursorClass);
        cursorClass = "default-cursor";
        addClass(canvas, cursorClass);
    } else {
        let coords = e.lngLat;
        app.ports.movedAnchor.send([cursorOverPoint, coords.lng, coords.lat]);
        isDragging = false;
        map.off("mousemove", mouseMove);
    }
}

function mouseDown(e) {
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
    map.on("mousemove", mouseMove);
}

function mouseMove(e) {
    if (!isDragging) return;
    removeClass(canvas, cursorClass);
    cursorClass = "grabbing-cursor";
    addClass(canvas, cursorClass);
    let coords = [e.lngLat.lng, e.lngLat.lat];
    map.getSource(cursorOverPoint).setData(makeSource("Point", coords));
}

function mouseEnter(id) {
    return function() {
        removeClass(canvas, cursorClass);
        cursorClass = "grab-cursor";
        addClass(canvas, cursorClass);
        cursorOverPoint = id;
        map.dragPan.disable();
    }
}

function mouseLeave() {
    if (isDragging) return;
    removeClass(canvas, cursorClass);
    cursorClass = "default-cursor";
    addClass(canvas, cursorClass);
    cursorOverPoint = null;
    map.dragPan.enable();
}

function segmentClick(e) {
    previousSelection = selectedSegment;
    selectedSegment = cursorOverSegment;
    app.ports.selectSegment.send(selectedSegment);
    if (selectedSegment) {
        for (let property in selectedPaintDict[selectedSegment]) {
            map.setPaintProperty(
                selectedSegment,
                property,
                selectedPaintDict[selectedSegment][property]
            );
        }
    }
    if (previousSelection) {
        for (let property in paintDict[previousSelection]) {
            map.setPaintProperty(
                previousSelection,
                property,
                paintDict[previousSelection][property]
            );
        }
    }
}

function mouseEnterSegment(key) {
    return function() {
        cursorOverSegment = key;
        removeClass(canvas, cursorClass);
        cursorClass = "pointer-cursor";
        addClass(canvas, cursorClass);
        for (let property in hoverPaintDict[key]) {
            map.setPaintProperty(key, property, hoverPaintDict[key][property]);
        }
    }
}

function segmentMouseDown(e) {
    if (!cursorOverSegment) return;
    let paint = activePaintDict[cursorOverSegment]
    for (let property in paint) {
        map.setPaintProperty(cursorOverSegment, property, paint[property]);
    }
}

function mouseLeaveSegment(key) {
    return function() {
        cursorOverSegment = null;
        removeClass(canvas, cursorClass);
        cursorClass = "default-cursor";
        addClass(canvas, cursorClass);
        let paint;
        if (key === selectedSegment) {
            paint = selectedPaintDict[key];
        } else {
            paint = paintDict[key];
        }
        for (let property in paint) {
            map.setPaintProperty(key, property, paint[property]);
        }
    }
}

// HELPER FUNCTIONS

function setupMap(coords) {
    if (map) {
        return;
    }

    mapboxgl.accessToken =
        "pk.eyJ1Ijoia2lhbWJvZ28iLCJhIjoiY2l2MWVqdWdpMDBiMDJ5bXB5aXdyY3JrdyJ9.oqpLQhZcd0yOzBKdSxyk2w";

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
    map.on("mousedown", mouseDown);
    map.on("mouseup", mouseUp);
    map.on("move", getBounds);
    map.on("moveend", function() {
        if (!viewOnly && segmentMode) app.ports.loadSegments.send(null);
    });
    map.on("zoomend", function() { app.ports.zoomLevel.send(map.getZoom()); });

    showingLayer = "SurfaceQuality";
    let hiddenLayer = Object.assign({}, trafficLayer);
    hiddenLayer.layout = { visibility: "none" };
    map.on("load", function () {
        map.addLayer(Object.assign({}, surfaceLayer));
        map.addLayer(hiddenLayer);
        getBounds();
    });
}

function getBounds() {
    let bounds = map.getBounds();
    app.ports.mapBounds.send([[bounds._sw, bounds._ne], viewOnly, segmentMode]);
}

function makeSource(geomType, coords) {
    return {
        "type": "FeatureCollection",
        "features": [{
            "type": "Feature",
            "geometry": {
                "type": geomType,
                "coordinates": coords
            }
        }]
    };
}

function removeMarker(key) {
    if (popup) {
        popup.remove();
    }
    map.getSource(key).setData({
        "type": "FeatureCollection",
        "features": []
    });
    app.ports.removedAnchor.send(key);
}

// UTIL FUNCTIONS

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
