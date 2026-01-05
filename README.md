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
- [![AWS][AWS-badge]][AWS-url]

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

- Docker (Engine) and Docker Compose v2+
- Elixir 1.14+ (and a compatible Erlang/OTP)
- Rust (stable toolchain) — for IoT mock
- Node.js + npm or yarn (for Phoenix assets, only for local dev)

Clone the repo

```sh
git clone https://github.com/qweliant/ankaa.git
```

### Docker setup

Start the db, rust, inbucket, and mosquitto service using Docker Compose

```sh
docker-compose up -d --build
```

### App development

For app development, switch to the backend app and follow its README:

```sh
cd ankaa_beacon
```

See ankaa_beacon/README.md for setup and run instructions.
****
<!-- ROADMAP -->
## Roadmap

### Phase 1: Prototype Validation & Emotional Utility (Now–3 months)

- Goal: Establish that the product feels helpful, emotionally comforting, and technically credible for solo patients and caregivers.
- Milestones
  - [x] Deploy public read-only prototype (AWS)
  - [x] Publish README + LICENSE (BUSL → MIT rollover)
  - [x] Implement in-app alerts using mock thresholds
  - [x] Build session-start / session-end flow (no live chat)
  - [x] Add “sign up for updates” form on landing page
  - [ ] Collect feedback from patients, caresupports, Reddit/forums, clinicians
- Legal / Safety
  - [x] Mark system experimental and non-medical (UI + README disclaimer)

### Phase 2: Safety Layer MVP & Pre‑Revenue Clinical Demo (3–6 months)

- Focus: Integrate real device signals, reliable alerting, escalation workflows, simple audit logs for clinicians.
- Core tasks (examples)
  - [ ] Device integration (mock → limited real BP/dialysis feeds)
  - [ ] Robust alert routing (SMS, push, email)
  - [ ] Care network UX: multi-caregiver roles & confirmations
  - [ ] Data audit & export for clinicians
  - [ ] Basic privacy & security hardening (HIPAA-influenced controls)

### Phase 3: Monetization Pilot & Grant Funding (6–12 months)

- Focus: Pilots with clinics, grant applications, soft monetization experiments.
- Core tasks
  - [ ] Freemium pilot: core safety features free, premium for clinics/analytics
  - [ ] Apply for grants / research partnerships
  - [ ] Small B2B pilots with 1–2 clinics

### Sustainability (high level)

- 🏗️ Foundation & Community Trust (Months 0–6)
  - Goal: traction, validation, credibility
  - MVP: mocked data or limited BP monitoring; care network; basic customizable alerts; accessible UI; HIPAA-aware architecture
  - Design premium features early; communicate beta status

****

### Critical Factors

- Success metrics by phase (examples)
  - Phase 1 → 50+ active users, positive qualitative feedback
  - Phase 2 → 15%+ conversion to paid trial, 1+ clinic interest
  - Phase 3 → 2+ clinic partnerships, positive clinical outcome signals
- Critical success factors
  - Regulatory / HIPAA-informed compliance from day one
  - Clear clinical evidence & auditability
  - Care network feature as key differentiator
  - Ethical pricing: no life-or-death paywalls; privacy prioritized
  - Technology integration capability for enterprise value

See the [open issues](https://github.com/qweliant/ankaa/issues) for a full list of proposed features.

### Impact & Implications

This section summarizes the intended benefits, measurable outcomes, and known limitations of the project.

- Patient safety: Real‑time detection and automated alerts aim to reduce missed critical events (hypotension, bleeding) and enable faster response.
- Accessibility & adoption: Lowering perceived risk can increase willingness to choose home dialysis and expand patient options.
- Care network enablement: Structured notifications and role-based escalation help families and caresupports coordinate responses.
- Clinical integration & policy: Instrumented audit logs, exportable data, and demonstrable safety signals support clinical validation and potential reimbursement/policy adoption.
- Economic impact: Safer home care can reduce facility visits and emergency transfers, lowering system costs while improving outcomes.
- Autonomy & quality of life: Continuous monitoring provides a safety net that lets patients maintain routines with reduced anxiety.
- Risks & limitations:
  - Not a medical device: requires clear disclaimers, clinical validation, and regulatory review before clinical deployment.
  - False positives/negatives: alert tuning and human-in-the-loop escalation are required to limit harm and alarm fatigue.
  - Privacy/security: HIPAA‑aware design and strong access controls are essential prior to production use.
- Success metrics / next steps:
  - User confidence metrics, number of sessions monitored, time-to-alert, false alarm rate, and clinician auditability.
  - Priorities: clinical pilot integrations, privacy/security hardening, and UX testing with patients and carers.

This framing is aligned with the project landing and "Learn more" materials: emphasize measurable safety, clear limits, and a roadmap to clinical validation rather than clinical deployment.

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
[AWS-badge]: https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=**white**
[AWS-url]: https://aws.com
