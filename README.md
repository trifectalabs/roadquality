# Road Quality
## Crowdsourced road quality data for cyclists

[roadquality.org](http://www.roadquality.org)

### Development
To compile server components:

    sbt api/compile

To run server locally:

    sbt "api/run -Dhttp.port=9001"
    sbt web/run

To compile web assets:

    cd web/
    elm make src/Main.elm --output=public/javascripts/main.js
    elm-css src/Stylesheets.elm --output=public/stylesheets/main.css
