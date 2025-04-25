<!-- PROJECT SHIELDS -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![Unlicense License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <h3 align="center">Ankaa</h3>

  <p align="center">
    Real-time monitoring and alert system for home hemodialysis
    <br />
    <a href="https://github.com/qweliant/ankaa"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/qweliant/ankaa/issues">Report Bug</a>
    &middot;
    <a href="https://github.com/qweliant/ankaa/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#architecture">Architecture</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

Ankaa is a proof-of-concept for a real-time monitoring and alert system designed specifically for home hemodialysis. The system focuses on detecting critical risks such as severe hypotension and blood loss, integrating with NxStage setups to provide automated emergency detection, caregiver alerts, and AI-driven anomaly detection. This ensures patient safety even without immediate medical assistance.

Key Features:

- Real-time monitoring of patient data
- Automated alert system for abnormal conditions
- Care network management
- Support for hemodialysis and blood pressure monitoring
- Web-based interface for monitoring

### Built With

- [![Elixir][Elixir-badge]][Elixir-url]
- [![Phoenix][Phoenix-badge]][Phoenix-url]
- [![Rust][Rust-badge]][Rust-url]
- [![TimescaleDB][TimescaleDB-badge]][TimescaleDB-url]
- [![PostgreSQL][PostgreSQL-badge]][PostgreSQL-url]
- [![Mosquitto][Mosquitto-badge]][Mosquitto-url]
- [![Docker][Docker-badge]][Docker-url]

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Elixir 1.14+ (for local development)
- Rust (for IoT mock development)

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/qweliant/ankaa.git
   ```
2. Start the services using Docker Compose
   ```sh
   docker-compose up -d
   ```
3. Access the web interface at `http://localhost:4000`

<!-- ARCHITECTURE -->

## Architecture

The system is built as a microservices architecture with the following components:

1. **Ankaa Beacon** (Phoenix/Elixir Application):

   - Main backend service
   - Handles data processing and business logic
   - Features real-time data processing and alert triggering

2. **IoT Mock** (Rust Application):

   - Simulates IoT devices
   - Publishes mock data to MQTT broker
   - Used for testing and development

3. **MQTT Broker** (Mosquitto):

   - Message broker for real-time communication
   - Handles pub/sub messaging between components
   - Exposed on ports 1883 (MQTT) and 9001 (WebSocket)

4. **Data Storage**:
   - PostgreSQL: General purpose database
   - TimescaleDB: Time-series database for IoT sensor data

<!-- ROADMAP -->

## Roadmap

- [x] Monorepo structure
- [x] IoT data storage in TimescaleDB
- [x] Alert triggering system
- [ ] Notification service
- [ ] Care network user management
- [x] Real-time monitoring dashboard
- [ ] AI-driven anomaly detection

See the [open issues](https://github.com/qweliant/ankaa/issues) for a full list of proposed features.

<!-- CONTRIBUTING -->

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->

## License

Distributed under the Unlicense License. See `LICENSE` for more information.

<!-- MARKDOWN LINKS & IMAGES -->

[contributors-shield]: https://img.shields.io/github/contributors/qweliant/ankaa.svg?style=for-the-badge
[contributors-url]: https://github.com/qweliant/ankaa/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/qweliant/ankaa.svg?style=for-the-badge
[forks-url]: https://github.com/qweliant/ankaa/network/members
[stars-shield]: https://img.shields.io/github/stars/qweliant/ankaa.svg?style=for-the-badge
[stars-url]: https://github.com/qweliant/ankaa/stargazers
[issues-shield]: https://img.shields.io/github/issues/qweliant/ankaa.svg?style=for-the-badge
[issues-url]: https://github.com/qweliant/ankaa/issues
[license-shield]: https://img.shields.io/github/license/qweliant/ankaa.svg?style=for-the-badge
[license-url]: https://github.com/qweliant/ankaa/blob/master/LICENSE
[Elixir-badge]: https://img.shields.io/badge/Elixir-4B275F?style=for-the-badge&logo=elixir&logoColor=white
[Elixir-url]: https://elixir-lang.org/
[Phoenix-badge]: https://img.shields.io/badge/Phoenix-FD4F00?style=for-the-badge&logo=phoenix&logoColor=white
[Phoenix-url]: https://www.phoenixframework.org/
[Rust-badge]: https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white
[Rust-url]: https://www.rust-lang.org/
[TimescaleDB-badge]: https://img.shields.io/badge/TimescaleDB-000000?style=for-the-badge&logo=timescaledb&logoColor=white
[TimescaleDB-url]: https://www.timescale.com/
[Mosquitto-badge]: https://img.shields.io/badge/Mosquitto-3C5280?style=for-the-badge&logo=eclipsemosquitto&logoColor=white
[Mosquitto-url]: https://mosquitto.org/
[Docker-badge]: https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
[Docker-url]: https://www.docker.com/
[PostgreSQL-badge]: https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white
[PostgreSQL-url]: https://www.postgresql.org/
