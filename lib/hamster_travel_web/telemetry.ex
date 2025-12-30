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
        # every Nms. Learn more here: https://hexdocs.pm/telemetry_metrics
        {:telemetry_poller, measurements: periodic_measurements(), period: 30_000}
      ] ++ reporters()

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # LiveView Metrics
      counter("phoenix.error_rendered.duration",
        tags: [:env, :service, :status],
        unit: {:native, :millisecond}
      ),
      distribution("phoenix.live_view.mount.stop.duration",
        tags: [:env, :service, :view],
        tag_values: fn metadata ->
          view_tag_value(metadata)
        end,
        unit: {:native, :millisecond}
      ),
      counter("phoenix.live_view.mount.exception.duration",
        tags: [:env, :service, :view],
        tag_values: fn metadata ->
          view_tag_value(metadata)
        end,
        unit: {:native, :millisecond}
      ),
      distribution("phoenix.live_view.handle_params.stop.duration",
        tags: [:env, :service, :view],
        tag_values: fn metadata ->
          view_tag_value(metadata)
        end,
        unit: {:native, :millisecond}
      ),
      counter("phoenix.live_view.handle_params.exception.duration",
        tags: [:env, :service, :view],
        tag_values: fn metadata ->
          view_tag_value(metadata)
        end,
        unit: {:native, :millisecond}
      ),
      distribution("phoenix.live_view.handle_event.stop.duration",
        tags: [:env, :service, :event, :view],
        tag_values: fn metadata ->
          view_tag_value(metadata)
        end,
        unit: {:native, :millisecond}
      ),
      counter("phoenix.live_view.handle_event.exception.duration",
        tags: [:env, :service, :event, :view],
        tag_values: fn metadata ->
          view_tag_value(metadata)
        end,
        unit: {:native, :millisecond}
      ),
      distribution("phoenix.live_component.handle_event.stop.duration",
        tags: [:env, :service, :event, :component],
        unit: {:native, :millisecond}
      ),
      counter("phoenix.live_component.handle_event.exception.duration",
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
      summary("vm.total_run_queue_lengths.io", tags: [:env, :service]),

      # Custom business metrics
      counter("hamster_travel.packing.backpack.create.count", tags: [:env, :service, :source]),
      last_value("hamster_travel.accounts.users.count", tags: [:env, :service]),
      last_value("hamster_travel.packing.backpacks.count", tags: [:env, :service]),
      counter("hamster_travel.geonames.download_countries.error", tags: [:env, :service])
    ]
  end

  defp periodic_measurements do
    []
  end

  defp view_tag_value(metadata) do
    Map.put(metadata, :view, "#{inspect(metadata.socket.view)}")
  end

  defp reporters do
    []
  end
end
