defmodule HamsterTravelWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children =
      [
        # Telemetry poller will execute the given period measurements
        # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
        {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      ] ++ reporters()

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      distribution("phoenix.endpoint.stop.duration",
        tags: [:env, :service],
        unit: {:native, :millisecond}
      ),
      distribution("phoenix.router_dispatch.stop.duration",
        tags: [:route, :env, :service],
        unit: {:native, :millisecond}
      ),

      # LiveView Metrics
      distribution("phoenix.live_view.mount.stop.duration",
        tags: [:env, :service, :uri],
        unit: {:native, :millisecond}
      ),
      distribution("phoenix.live_view.handle_params.stop.duration",
        tags: [:env, :service, :uri],
        unit: {:native, :millisecond}
      ),
      distribution("phoenix.live_view.handle_event.stop.duration",
        tags: [:env, :service, :event],
        unit: {:native, :millisecond}
      ),
      distribution("phoenix.live_component.handle_event.stop.duration",
        tags: [:env, :service, :event, :component],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      distribution("hamster_travel.repo.query.total_time",
        tags: [:env, :service],
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      distribution("hamster_travel.repo.query.decode_time",
        tags: [:env, :service],
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      distribution("hamster_travel.repo.query.query_time",
        tags: [:env, :service],
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      distribution("hamster_travel.repo.query.queue_time",
        tags: [:env, :service],
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      distribution("hamster_travel.repo.query.idle_time",
        tags: [:env, :service],
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # VM Metrics
      summary("vm.memory.total",
        tags: [:env, :service],
        unit: {:byte, :kilobyte}
      ),
      summary("vm.total_run_queue_lengths.total", tags: [:env, :service]),
      summary("vm.total_run_queue_lengths.cpu", tags: [:env, :service]),
      summary("vm.total_run_queue_lengths.io", tags: [:env, :service])
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {HamsterTravelWeb, :count_users, []}
    ]
  end

  defp reporters do
    if Application.fetch_env!(:hamster_travel, __MODULE__)[:report_metrics] do
      [
        {TelemetryMetricsStatsd,
         metrics: metrics(),
         global_tags: [env: "fly", service: "hamster_travel"],
         host: "ddagent.internal",
         inet_address_family: :inet6,
         formatter: :datadog}
      ]
    else
      []
    end
  end
end
