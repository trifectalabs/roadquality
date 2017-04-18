# Road Quality
## Crowdsourced road quality data for cyclists

[https://roadquality.org]()

### Development
To compile server components:

    sbt api/compile

To compile web assets:

    cd web/
    elm make src/App.elm --output=public/javascripts/main.js
    elm-css src/Stylesheets.elm --output=public/stylesheets/main.css
