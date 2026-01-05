#

<!-- PROJECT SHIELDS -->
[![Tests](https://github.com/qweliant/ankaa/actions/workflows/test.yml/badge.svg)](https://github.com/qweliant/ankaa/actions/workflows/test.yml)

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

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
    <li><a href="#impact--implications">Impact & Implications</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

Ankaa is a proof-of-concept for a real-time monitoring and alert system designed specifically for home hemodialysis. The system focuses on detecting critical risks such as severe hypotension and blood loss, integrating with health monitoring setups to provide automated emergency detection, and caresupport alerts. This ensures patient safety even without immediate medical assistance.

The project was born from a personal need to make home hemodialysis safer and more accessible. As someone who has experienced the challenges of home dialysis firsthand, I understand the importance of having a reliable safety net that can detect and respond to critical situations, especially when medical assistance isn't immediately available.

Key Features:

- Real-time monitoring of patient data
- Automated alert system for abnormal conditions
- Care network management
- Support for hemodialysis and blood pressure monitoring
- Web-based interface for monitoring
- Integration with existing dialysis equipment

The system aims to:

- Reduce anxiety and stress during home dialysis sessions
- Provide peace of mind for both patients and caresupports
- Enable faster response to critical situations
- Make home dialysis more accessible to those who might otherwise be hesitant
- Create a safety net that works even without immediate medical assistance

### Built With

- [![Elixir][Elixir-badge]][Elixir-url]
- [![Phoenix][Phoenix-badge]][Phoenix-url]
- [![Rust][Rust-badge]][Rust-url]
- [![PostgreSQL][PostgreSQL-badge]][PostgreSQL-url]
- [![Docker][Docker-badge]][Docker-url]

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Elixir 1.14+ (for local development)
- Rust (for IoT mock development)

### Installation

1. Clone the repo

   ````sh
   git clone https://github.com/qweliant/ankaa.git
   ```2. Start the services using Docker Compose

   ```sh
   docker-compose up -d
   ````

2. Access the web interface at `http://localhost:4000`

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

<!-- ROADMAP -->

## Roadmap

- [x] Monorepo structure
- [x] Alert triggering system
- [x] Notification service
- [x] Care network user management
- [x] Real-time monitoring dashboard

See the [open issues](https://github.com/qweliant/ankaa/issues) for a full list of proposed features.

### Impact & Implications

This project addresses several critical barriers to home dialysis adoption:

- **Safety Concerns**: By providing real-time monitoring and automated emergency detection, the system helps mitigate the primary fear of complications occurring during home treatment.

- **Accessibility**: Making home dialysis feel safer could increase adoption rates, potentially allowing more patients to benefit from the flexibility and quality of life improvements that home treatment offers.

- **Care Network Support**: The system empowers family members and caresupports to be more confident in supporting home dialysis patients, creating a stronger support network.

- **Healthcare Evolution**: This technology could influence healthcare policies and insurance coverage for home dialysis by demonstrating that remote monitoring systems can effectively enhance patient safety.

- **Patient Autonomy**: By providing a reliable safety net, patients gain more independence in managing their treatment while maintaining connection to their care network.

- **Cost Implications**: By enabling more patients to safely perform dialysis at home, this system could help reduce the overall cost of care while improving patient outcomes.

- **Quality of Life**: The combination of safety features and remote monitoring allows patients to maintain their normal routines and lifestyle while ensuring their wellbeing during treatment.

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

This project is licensed under the Business Source License 1.1. This license:

- Permits non-production use including research, experimentation, development, testing, personal projects, and non-commercial evaluation
- Does not grant the right to use the software in a production environment
- Requires that any modified works carry prominent notices of changes
- Includes a change date (2027-04-14) after which the license will change to MIT License

For full license terms, see the [LICENSE](LICENSE) file.

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
[Docker-badge]: https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
[Docker-url]: https://www.docker.com/
[PostgreSQL-badge]: https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white
[PostgreSQL-url]: https://www.postgresql.org/
