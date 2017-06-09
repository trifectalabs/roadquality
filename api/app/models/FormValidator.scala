package models

import com.trifectalabs.roadquality.v0.models._
import com.trifectalabs.polyline.Polyline

object FormValidator {
  def validateSegmentCreateForm(segForm: SegmentCreateForm): Seq[FormError] = {
  { segForm.polylines.flatMap { polyline =>
      Polyline.decode(polyline).map { p =>
          if (p.lat > 180 || p.lat < -180 || p.lng > 180 || p.lng < -180) Some(FormError(s"$p out of bounds"))
          else None
      }
    } :+
      (if (segForm.surfaceRating > 5 || segForm.surfaceRating < 0) Some(FormError(s"Surface Rating > 5 or < 0")) else None) :+
      (if (segForm.trafficRating > 5 || segForm.trafficRating < 0) Some(FormError(s"Traffic Rating > 5 or < 0")) else None)
    }.flatten
  }

  def validateSegmentUpdateForm(segForm: SegmentUpdateForm): Seq[FormError] = {
    Seq(
      (if (segForm.surfaceRating.map(sR => sR > 5 || sR < 0).getOrElse(false)) Some(FormError(s"Surface Rating > 5 or < 0")) else None),
      (if (segForm.trafficRating.map(tR => tR > 5 || tR < 0).getOrElse(false)) Some(FormError(s"Traffic Rating > 5 or < 0")) else None),
      (if (segForm.surface.map(s => !SurfaceType.all.contains(s)).getOrElse(false)) Some(FormError(s"Surface is not one of ${SurfaceType.all}")) else None),
      (if (segForm.pathType.map(s => !PathType.all.contains(s)).getOrElse(false)) Some(FormError(s"PathType is not one of ${PathType.all}")) else None)
    ).flatten
  }

  def validateRatingUpdate(rating: Double): Seq[FormError] = {
    Seq((if (rating > 5 || rating < 0) Some(FormError(s"Rating > 5 or < 0")) else None)).flatten
  }

}

case class FormError(error: String)
