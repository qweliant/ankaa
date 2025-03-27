defmodule AnkaaBeacon.Redis do
  use GenServer

  @moduledoc """
  A GenServer module to handle Redis connections and Pub/Sub for real-time data streaming.
  """

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initializes the Redis connection and Pub/Sub connection.
  """
  def init(opts) do
    host = Keyword.get(opts, :host, "localhost")
    port = Keyword.get(opts, :port, 6379)

    # Start Redis connection
    {:ok, conn} = Redix.start_link(host: host, port: port)

    # Start Redis Pub/Sub connection
    {:ok, pubsub} = Redix.PubSub.start_link(host: host, port: port)

    # Subscribe process to handle Redis Pub/Sub messages
    Redix.PubSub.subscribe(pubsub, "bp_readings", self())
    Redix.PubSub.subscribe(pubsub, "dialysis_readings", self())

    {:ok, %{conn: conn, pubsub: pubsub}}
  end

  @doc """
  Sends a Redis command and returns the result.
  """
  def command(command) do
    GenServer.call(__MODULE__, {:command, command})
  end

  @doc """
  Subscribes to a Redis channel for real-time updates.
  """
  def subscribe(channel) do
    GenServer.call(__MODULE__, {:subscribe, channel})
  end

  @doc """
  Publishes a message to a Redis channel.
  """
  def publish(channel, message) do
    GenServer.call(__MODULE__, {:publish, channel, message})
  end

  @doc """
  Unsubscribes from a Redis channel
  """
  def unsubscribe(channel) do
    GenServer.call(__MODULE__, {:unsubscribe, channel})
  end

  # GenServer Callbacks
  def handle_call({:command, command}, _from, %{conn: conn} = state) do
    {:reply, Redix.command(conn, command), state}
  end

  def handle_call({:subscribe, channel}, _from, %{pubsub: pubsub} = state) do
    Redix.PubSub.subscribe(pubsub, channel, self())
    {:reply, :ok, state}
  end

  def handle_call({:publish, channel, message}, _from, %{conn: conn} = state) do
    {:reply, Redix.command(conn, ["PUBLISH", channel, message]), state}
  end

  def handle_call({:unsubscribe, channel}, _from, %{pubsub: pubsub} = state) do
    Redix.PubSub.unsubscribe(pubsub, channel, self())
    {:reply, :ok, state}
  end

  # Handle Pub/Sub messages
  def handle_info({:redix_pubsub, _pubsub, _ref, :subscribed, %{channel: channel}}, state) do
    IO.puts("Subscribed to channel: #{channel}")

    {:noreply, state}
  end

  def handle_info(
        {:redix_pubsub, _pubsub, _ref, :message, %{channel: channel, payload: payload}},
        state
      ) do
    IO.puts("Received message on channel #{channel}: #{payload}")
    # Broadcast the message to all subscribers (e.g., LiveView processes)
    Phoenix.PubSub.broadcast(AnkaaBeacon.PubSub, channel, {:redix_pubsub, :message, payload})
    {:noreply, state}
  end

  def handle_info({:redix_pubsub, _pubsub, _ref, :unsubscribed, %{channel: channel}}, state) do
    IO.puts("Unsubscribed from channel: #{channel}")
    {:noreply, state}
  end
end
