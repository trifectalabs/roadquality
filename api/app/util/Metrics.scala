package util

import javax.inject.Inject

import com.codahale.metrics._
import com.codahale.metrics.graphite._
import nl.grons.metrics.scala.{ MetricBuilder, MetricName }
import nl.grons.metrics.scala.InstrumentedBuilder

import java.util.concurrent.TimeUnit
import java.net.InetSocketAddress
import play.api.Configuration

trait Metrics extends Instrumented {
  val apiMetrics = new MetricBuilder(MetricName("api"), Application.metricRegistry)
  val webMetrics = new MetricBuilder(MetricName("web"), Application.metricRegistry)
  val dbMetrics = new MetricBuilder(MetricName("db"), Application.metricRegistry)
}

trait Instrumented extends InstrumentedBuilder {
  val metricRegistry = Application.metricRegistry

  val graphite = new Graphite(new InetSocketAddress("graphite.rq.org", 2003));
  val reporter = GraphiteReporter
    .forRegistry(metricRegistry)
    .prefixedWith("roadquality.org")
    .convertRatesTo(TimeUnit.SECONDS)
    .convertDurationsTo(TimeUnit.MILLISECONDS)
    .filter(MetricFilter.ALL)
    .build(graphite);

    reporter.start(10, TimeUnit.SECONDS)
}

object Application {
  val metricRegistry = new com.codahale.metrics.MetricRegistry()
}
