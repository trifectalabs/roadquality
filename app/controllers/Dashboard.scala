package controllers

import play.api.mvc.{Action, Controller}

class Dashboard extends Controller {
  def get() = Action {
    Ok("")
  }
}
