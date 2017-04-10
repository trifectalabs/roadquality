package models

import com.trifectalabs.roadquality.v0.models._

object FormValidator {
  def validateSegmentForm(segForm: SegmentForm): Seq[FormError] = {
    { segForm.points.map { p =>
        if (p.lat > 180 || p.lat < -180 || p.lng > 180 || p.lng < -180) Some(FormError(s"$p out of bounds"))
        else None
      } :+
      (if (segForm.surfaceRating > 5 || segForm.surfaceRating < 0) Some(FormError(s"Surface Rating > 5 or < 0")) else None) :+
      (if (segForm.trafficRating > 5 || segForm.trafficRating < 0) Some(FormError(s"Traffic Rating > 5 or < 0")) else None)
    }.flatten
  }

  def validateRatingUpdate(rating: Double): Seq[FormError] = {
    Seq((if (rating > 5 || rating < 0) Some(FormError(s"Rating > 5 or < 0")) else None)).flatten
  }

}

case class FormError(error: String)
