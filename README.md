# Ankaa

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## Todo
- [ ] make this a monrepo
- [ ] push incoming IoT data to timescale or influxDB
- [ ] build out notification service
- [ ] integrate react. LiveReact and LiveVue don't seem to be the best option for managing a complex frontend so i want to create a react app that consumes events from redis
- [ ] build out react client to handle
  - [ ] triggering alerts
  - [ ] adding people to care network
  - [ ] viewing care network realtime hemodialyis and bp. probably doesnt require a dashboard. letting users know the patient is online and providing notifications if something is wrong could be the only view
  - [ ] maybe a realtime dashboard
