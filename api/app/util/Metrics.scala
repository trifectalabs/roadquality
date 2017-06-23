package util

import com.codahale.metrics._
import nl.grons.metrics.scala.InstrumentedBuilder
import java.util.concurrent.TimeUnit

trait Metrics extends Instrumented {
  val response = metrics.timer("response")
}

trait Instrumented extends InstrumentedBuilder {
  val metricRegistry = Application.metricRegistry

  val reporter: ConsoleReporter = ConsoleReporter
    .forRegistry(metricRegistry)
    .convertRatesTo(TimeUnit.SECONDS)
    .convertDurationsTo(TimeUnit.MILLISECONDS)
    .build()

  reporter.start(1, TimeUnit.SECONDS);
}

object Application {
  val metricRegistry = new com.codahale.metrics.MetricRegistry()
}
