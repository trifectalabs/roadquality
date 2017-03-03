package controllers

import play.api.mvc.{Action, Controller}
import play.api.libs.json.Json

import com.trifectalabs.road.quality.v0.models.Segment

class Segments extends Controller {

	def getBySegmentId(segment_id: String) = Action {
		Ok("")
	}

	def post() = Action {
		Ok("")
	}

}
