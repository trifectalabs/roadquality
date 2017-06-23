package util

import com.codahale.metrics._
import nl.grons.metrics.scala.{ MetricBuilder, MetricName }
import nl.grons.metrics.scala.InstrumentedBuilder
import java.util.concurrent.TimeUnit

trait Metrics extends Instrumented {
  val apiMetrics = new MetricBuilder(MetricName("api"), Application.metricRegistry)
  val webMetrics = new MetricBuilder(MetricName("web"), Application.metricRegistry)
  val dbMetrics = new MetricBuilder(MetricName("db"), Application.metricRegistry)
}

trait Instrumented extends InstrumentedBuilder {
  val metricRegistry = Application.metricRegistry

  val reporter: ConsoleReporter = ConsoleReporter
    .forRegistry(metricRegistry)
    .convertRatesTo(TimeUnit.SECONDS)
    .convertDurationsTo(TimeUnit.MILLISECONDS)
    .build()

  reporter.start(5, TimeUnit.SECONDS);
}

object Application {
  val metricRegistry = new com.codahale.metrics.MetricRegistry()
}
