use chrono::Utc;
use dashmap::DashMap;
use log::{error, info};
use rand::SeedableRng;
use rand::prelude::*;
use rand::rngs::StdRng;
use rumqttc::{AsyncClient, MqttOptions, QoS};
use serde::Serialize;
use std::env;
use std::sync::Arc;
use std::time::Duration;
use tokio::task;
use tokio::time;

// #[derive(Debug, Serialize, Clone)]
// struct DialysisDeviceData {
//     device_id: String,
//     timestamp: String,
//     mode: String,
//     status: String,
//     time_in_alarm: Option<i32>,
//     time_in_treatment: i32,
//     time_remaining: i32,
//     dfv: f32,
//     dfr: f32,
//     ufv: f32,
//     ufr: f32,
//     bfr: i32,
//     ap: i32,
//     vp: i32,
//     ep: i32,
// }

#[derive(Debug, Serialize, Clone)]
struct BPDeviceData {
    device_id: String,
    timestamp: String,
    mode: String,
    status: String,
    systolic: i32,
    diastolic: i32,
    heart_rate: i32,
    mean_arterial_pressure: i32,
    pulse_pressure: i32,
    irregular_heartbeat: bool,
}

#[derive(Clone)]
struct SimulationConfig {
    speed_multiplier: f32,
    message_interval_ms: u64,
    batch_size: usize,
}

#[derive(Debug, serde::Deserialize, Clone)]
enum Scenario {
    Normal,
    HighSystolic,
    LowDiastolic,
    IrregularHeartbeat,
    HighVP,
    LowBFR,
}

#[derive(Debug, serde::Deserialize)]
struct DeviceConfig {
    device_id: String,
    scenario: String, // We'll just use a string for simplicity for now
}

#[derive(Debug, serde::Deserialize)]
#[serde(untagged)] // Allows us to parse different command types
enum SimulatorCommand {
    Start {
        start_simulations: Vec<DeviceConfig>,
    },
    Stop {
        stop_simulations: Vec<String>,
    },
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();
    info!("Starting high-performance IoT device simulator");

    // Configuration - make these environment variables for easier control
    let config = SimulationConfig {
        speed_multiplier: env::var("SPEED_MULTIPLIER")
            .unwrap_or_else(|_| "1.0".to_string())
            .parse::<f32>()
            .unwrap_or(1.0),
        message_interval_ms: env::var("MESSAGE_INTERVAL_MS")
            .unwrap_or_else(|_| "2000".to_string())
            .parse::<u64>()
            .unwrap_or(2000),
        batch_size: env::var("BATCH_SIZE")
            .unwrap_or_else(|_| "10".to_string())
            .parse::<usize>()
            .unwrap_or(10),
    };

    info!("Speed multiplier: {}", config.speed_multiplier);
    info!("Message interval: {}ms", config.message_interval_ms);
    info!("Batch size: {}", config.batch_size);

    let mqtt_host = env::var("MQTT_HOST").unwrap_or_else(|_| "mqtt".to_string());
    info!("Connecting to MQTT broker at {}", mqtt_host);

    let mut mqtt_options = MqttOptions::new("iot_device_simulator", mqtt_host, 1883);

    // Connection optimization
    mqtt_options.set_keep_alive(Duration::from_secs(30));
    mqtt_options.set_clean_session(true);
    mqtt_options.set_max_packet_size(10 * 1024 * 1024, 10 * 1024 * 1024); // Allow larger packets for batching
    mqtt_options.set_inflight(100); // Increase in-flight messages

    // Create client with larger capacities
    let (client, mut eventloop) = AsyncClient::new(mqtt_options, 1000);
    let client = Arc::new(client);

    client
        .subscribe("simulator/control", QoS::AtLeastOnce)
        .await?;
    info!("Subscribed to simulator/control topic.");

    let running_simulations: Arc<DashMap<String, task::JoinHandle<()>>> = Arc::new(DashMap::new());

    loop {
        let notification = eventloop.poll().await?;

        if let rumqttc::Event::Incoming(rumqttc::Incoming::Publish(publish)) = notification {
            if publish.topic == "simulator/control" {
                let command: SimulatorCommand = match serde_json::from_slice(&publish.payload) {
                    Ok(cmd) => cmd,
                    Err(e) => {
                        error!("Failed to parse command JSON: {}", e);
                        continue; // Ignore malformed commands
                    }
                };

                match command {
                    SimulatorCommand::Start { start_simulations } => {
                        info!(
                            "Received START command for {} devices.",
                            start_simulations.len()
                        );
                        for device_config in start_simulations {
                            let client_clone = client.clone();
                            let config_clone = config.clone();
                            let sims_map_clone = running_simulations.clone();
                            let device_id = device_config.device_id.clone();

                            info!("Starting simulation for device: {}", &device_id);

                            let handle = task::spawn(async move {
                                // We can expand this to handle different device types
                                simulate_bp_device(client_clone, device_config, config_clone).await;
                            });

                            sims_map_clone.insert(device_id, handle);
                        }
                    }
                    SimulatorCommand::Stop { stop_simulations } => {
                        info!(
                            "Received STOP command for {} devices.",
                            stop_simulations.len()
                        );
                        for device_id in stop_simulations {
                            if let Some((_, handle)) = running_simulations.remove(&device_id) {
                                handle.abort();
                                info!("Stopped simulation for device: {}", device_id);
                            }
                        }
                    }
                }
            }
        }
    }
}

// async fn simulate_dialysis_device(
//     client: Arc<AsyncClient>,
//     device_id: String,
//     modes: Vec<&str>,
//     statuses: Vec<&str>,
//     config: SimulationConfig,
// ) {
//     let mut rng = StdRng::seed_from_u64(device_id.as_bytes().iter().map(|&b| b as u64).sum());

//     let topic = format!("devices/{}/telemetry", device_id);
//     let mut interval = time::interval(Duration::from_millis(config.message_interval_ms));
//     let mut batch = Vec::with_capacity(config.batch_size);

//     // Initial states
//     let mut mode_idx = rng.random_range(0..modes.len());
//     let mut status_idx = rng.random_range(0..statuses.len());
//     let mut mode = modes[mode_idx].to_string();
//     let mut status = statuses[status_idx].to_string();
//     let mut time_in_treatment = rng.random_range(0..240);

//     loop {
//         interval.tick().await;

//         // Occasionally change mode or status to simulate real device behavior
//         if rng.random_range(0.0..1.0) < 0.05 {
//             mode_idx = rng.random_range(0..modes.len());
//             mode = modes[mode_idx].to_string();
//         }
//         if rng.random_range(0.0..1.0) < 0.03 {
//             status_idx = rng.random_range(0..statuses.len());
//             status = statuses[status_idx].to_string();
//         }

//         // Update time values to make them change realistically
//         let increment = (rng.random_range(1..3) as f32 * config.speed_multiplier) as i32;
//         time_in_treatment += increment;
//         let time_remaining = 240 - (time_in_treatment % 240);

//         let data = DialysisDeviceData {
//             device_id: device_id.clone(),
//             timestamp: Utc::now().to_rfc3339(),
//             mode: mode.clone(),
//             status: status.clone(),
//             time_in_alarm: if status == "normal" {
//                 None
//             } else {
//                 Some(rng.random_range(1..60))
//             },
//             time_in_treatment,
//             time_remaining,
//             dfv: rng.random_range(0.0..100.0),
//             dfr: rng.random_range(0.0..500.0),
//             ufv: rng.random_range(0.0..10.0),
//             ufr: rng.random_range(0.0..1000.0),
//             bfr: rng.random_range(50..500),
//             ap: rng.random_range(-200..200),
//             vp: rng.random_range(-200..200),
//             ep: rng.random_range(-200..200),
//         };

//         let payload = serde_json::to_string(&data).unwrap_or_default();

//         batch.push((topic.clone(), payload));

//         // When batch is full, publish all messages
//         if batch.len() >= config.batch_size {
//             for (topic, payload) in batch.drain(..) {
//                 if let Err(e) = client
//                     .publish(&topic, QoS::AtLeastOnce, false, payload)
//                     .await
//                 {
//                     error!("Failed to publish dialysis data: {}", e);
//                 }
//             }
//             info!(
//                 "Published batch of {} dialysis messages from {}",
//                 config.batch_size, device_id
//             );
//         }
//     }
// }

async fn simulate_bp_device(
    client: Arc<AsyncClient>,
    device_config: DeviceConfig,
    config: SimulationConfig,
) {
    let seed: u64 = device_config
        .device_id
        .as_bytes()
        .iter()
        .map(|&b| b as u64)
        .sum();
    let mut rng = StdRng::seed_from_u64(seed);
    let topic = format!("devices/{}/telemetry", device_config.device_id);
    let mut interval = time::interval(Duration::from_millis(config.message_interval_ms));

    let mut systolic_base = 120;
    let mut diastolic_base = 80;
    let mut heart_rate_base = 70;
    let mut is_irregular_rhythm = false;
    let mut status_str = "normal";

    // Set the baseline vitals based on the scenario
    let scenario =
        match serde_json::from_str::<Scenario>(&format!("\"{}\"", device_config.scenario)) {
            Ok(s) => s,
            Err(_) => Scenario::Normal,
        };

    match scenario {
        Scenario::Normal => {
            // No changes needed, we'll use the healthy defaults.
        }
        Scenario::HighSystolic => {
            info!(
                "Device {} is starting HighSystolic scenario.",
                device_config.device_id
            );
            systolic_base = 185; // Consistently high systolic pressure
            diastolic_base = 95;
            heart_rate_base = 90;
            status_str = "critical";
        }
        Scenario::LowDiastolic => {
            info!(
                "Device {} is starting LowDiastolic scenario.",
                device_config.device_id
            );
            systolic_base = 95;
            diastolic_base = 50; // Consistently low diastolic pressure
            heart_rate_base = 85; // Heart rate may increase to compensate
            status_str = "warning";
        }
        Scenario::IrregularHeartbeat => {
            info!(
                "Device {} is starting IrregularHeartbeat scenario.",
                device_config.device_id
            );
            // BP might be in the normal range, but the rhythm is the key issue.
            is_irregular_rhythm = true;
            heart_rate_base = 85; // Often slightly elevated
            status_str = "warning";
        }
        _ => {}
    }

    loop {
        interval.tick().await;

        let systolic = systolic_base + rng.random_range(-3..=3);
        let diastolic = diastolic_base + rng.random_range(-2..=2);
        let mut heart_rate = heart_rate_base + rng.random_range(-2..=2);

        let mut final_irregular_flag = is_irregular_rhythm;
        if is_irregular_rhythm && rng.random_ratio(1, 5) {
            heart_rate += rng.random_range(20..=30);
            final_irregular_flag = true;
        }

        let mean_arterial_pressure = ((2 * diastolic) + systolic) / 3;
        let pulse_pressure = systolic - diastolic;

        let data = BPDeviceData {
            device_id: device_config.device_id.clone(),
            timestamp: Utc::now().to_rfc3339(),
            mode: "Auto".to_string(),
            status: status_str.to_string(),
            systolic,
            diastolic,
            heart_rate,
            mean_arterial_pressure,
            pulse_pressure,
            irregular_heartbeat: final_irregular_flag,
        };

        let payload = serde_json::to_string(&data).unwrap_or_default();

        if let Err(e) = client
            .publish(&topic, QoS::AtLeastOnce, false, payload)
            .await
        {
            error!("Failed to publish BP data: {}", e);
        }
    }
}
