use rumqttc::{MqttOptions, AsyncClient, QoS};
use serde::Serialize;
use std::time::Duration;
use tokio::time;
use tokio::task;
use rand::prelude::*;
use rand::rngs::StdRng;
use rand::SeedableRng;
use chrono::Utc;
use std::env;
use std::sync::Arc;
use log::{info, error};

#[derive(Debug, Serialize, Clone)]
struct DialysisDeviceData {
    device_id: String,
    timestamp: String,
    mode: String,
    status: String,
    time_in_alarm: Option<i32>,
    time_in_treatment: i32,
    time_remaining: i32,
    dfv: f32,
    dfr: f32,
    ufv: f32,
    ufr: f32,
    bfr: i32,
    ap: i32,
    vp: i32,
    ep: i32,
}

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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();
    info!("Starting high-performance IoT device simulator");

    // Configuration - make these environment variables for easier control
    let config = SimulationConfig {
        speed_multiplier: env::var("SPEED_MULTIPLIER")
            .unwrap_or_else(|_| "10.0".to_string())
            .parse::<f32>()
            .unwrap_or(10.0),
        message_interval_ms: env::var("MESSAGE_INTERVAL_MS")
            .unwrap_or_else(|_| "100".to_string())
            .parse::<u64>()
            .unwrap_or(100),
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
    
    let mut mqtt_options = MqttOptions::new(
        "iot_device_simulator", 
        mqtt_host, 
        1883
    );
    
    // Connection optimization
    mqtt_options.set_keep_alive(Duration::from_secs(30));
    mqtt_options.set_clean_session(true);
    mqtt_options.set_max_packet_size(10 * 1024 * 1024, 10 * 1024 * 1024); // Allow larger packets for batching
    mqtt_options.set_inflight(100); // Increase in-flight messages
    
    // Create client with larger capacities
    let (client, mut eventloop) = AsyncClient::new(mqtt_options, 1000);
    let client = Arc::new(client);
    
    // Process eventloop in a separate task
    tokio::spawn(async move {
        loop {
            match eventloop.poll().await {
                Ok(event) => {
                    if let rumqttc::Event::Incoming(rumqttc::Incoming::ConnAck(_)) = event {
                        info!("Successfully connected to MQTT broker!");
                    }
                },
                Err(e) => {
                    error!("Error from eventloop: {}", e);
                    time::sleep(Duration::from_millis(100)).await;
                }
            }
        }
    });

    // Wait for connection to establish
    time::sleep(Duration::from_secs(1)).await;
    
    // Device configurations
    let dialysis_devices = ["dialysis_001", "dialysis_002", "dialysis_003", 
                          "dialysis_004", "dialysis_005", "dialysis_006", 
                          "dialysis_007", "dialysis_008", "dialysis_009", "dialysis_010"];
    let bp_devices = ["bp_001", "bp_002", "bp_003", 
                     "bp_004", "bp_005", "bp_006", 
                     "bp_007", "bp_008", "bp_009", "bp_010"];
    let modes = ["HD", "HDF", "HF"];
    let statuses = ["normal", "warning", "critical"];

    // Simulate all devices in parallel
    let mut device_tasks = Vec::new();
    
    // Launch dialysis device simulators
    for device_id in &dialysis_devices {
        let client_clone = client.clone();
        let device_id = device_id.to_string();
        let modes = modes.to_vec();
        let statuses = statuses.to_vec();
        let config_clone = config.clone();
        
        let handle = task::spawn(async move {
            simulate_dialysis_device(client_clone, device_id, modes, statuses, config_clone).await;
        });
        device_tasks.push(handle);
    }
    
    // Launch BP device simulators
    for device_id in &bp_devices {
        let client_clone = client.clone();
        let device_id = device_id.to_string();
        let modes = modes.to_vec();
        let statuses = statuses.to_vec();
        let config_clone = config.clone();
        
        let handle = task::spawn(async move {
            simulate_bp_device(client_clone, device_id, modes, statuses, config_clone).await;
        });
        device_tasks.push(handle);
    }
    
    // Wait for all device simulators (they will run forever)
    for task in device_tasks {
        if let Err(e) = task.await {
            error!("Device simulation task failed: {}", e);
        }
    }
    
    Ok(())
}

async fn simulate_dialysis_device(
    client: Arc<AsyncClient>,
    device_id: String,
    modes: Vec<&str>,
    statuses: Vec<&str>,
    config: SimulationConfig,
) {
    let mut rng = StdRng::seed_from_u64(device_id.as_bytes().iter().map(|&b| b as u64).sum());
    
    let topic = format!("devices/{}/telemetry", device_id);
    let mut interval = time::interval(Duration::from_millis(config.message_interval_ms));
    let mut batch = Vec::with_capacity(config.batch_size);
    
    // Initial states
    let mut mode_idx = rng.random_range(0..modes.len());
    let mut status_idx = rng.random_range(0..statuses.len());
    let mut mode = modes[mode_idx].to_string();
    let mut status = statuses[status_idx].to_string();
    let mut time_in_treatment = rng.random_range(0..240);
    
    loop {
        interval.tick().await;
        
        // Occasionally change mode or status to simulate real device behavior
        if rng.random_range(0.0..1.0) < 0.05 {
            mode_idx = rng.random_range(0..modes.len());
            mode = modes[mode_idx].to_string();
        }
        if rng.random_range(0.0..1.0) < 0.03 {
            status_idx = rng.random_range(0..statuses.len());
            status = statuses[status_idx].to_string();
        }
        
        // Update time values to make them change realistically
        let increment = (rng.random_range(1..3) as f32 * config.speed_multiplier) as i32;
        time_in_treatment += increment;
        let time_remaining = 240 - (time_in_treatment % 240);
        
        let data = DialysisDeviceData {
            device_id: device_id.clone(),
            timestamp: Utc::now().to_rfc3339(),
            mode: mode.clone(),
            status: status.clone(),
            time_in_alarm: if status == "normal" { None } else { Some(rng.random_range(1..60)) },
            time_in_treatment,
            time_remaining,
            dfv: rng.random_range(0.0..100.0),
            dfr: rng.random_range(0.0..500.0),
            ufv: rng.random_range(0.0..10.0),
            ufr: rng.random_range(0.0..1000.0),
            bfr: rng.random_range(50..500),
            ap: rng.random_range(-200..200),
            vp: rng.random_range(-200..200),
            ep: rng.random_range(-200..200),
        };

        let payload = serde_json::to_string(&data).unwrap_or_default();
        
        batch.push((topic.clone(), payload));
        
        // When batch is full, publish all messages
        if batch.len() >= config.batch_size {
            for (topic, payload) in batch.drain(..) {
                if let Err(e) = client.publish(&topic, QoS::AtLeastOnce, false, payload).await {
                    error!("Failed to publish dialysis data: {}", e);
                }
            }
            info!("Published batch of {} dialysis messages from {}", config.batch_size, device_id);
        }
    }
}

async fn simulate_bp_device(
    client: Arc<AsyncClient>,
    device_id: String,
    modes: Vec<&str>,
    statuses: Vec<&str>,
    config: SimulationConfig,
) {
    let mut rng = StdRng::seed_from_u64(device_id.as_bytes().iter().map(|&b| b as u64).sum());
    
    let topic = format!("devices/{}/telemetry", device_id);
    let mut interval = time::interval(Duration::from_millis(config.message_interval_ms));
    let mut batch = Vec::with_capacity(config.batch_size);
    
    // Initial states
    let mut mode_idx = rng.random_range(0..modes.len());
    let mut status_idx = rng.random_range(0..statuses.len());
    let mut mode = modes[mode_idx].to_string();
    let mut status = statuses[status_idx].to_string();
    let mut systolic_base = rng.random_range(110..140);
    let mut diastolic_base = rng.random_range(70..90);
    let mut heart_rate_base = rng.random_range(60..80);
    
    loop {
        interval.tick().await;
        
        // Occasionally change mode or status
        if rng.random_range(0.0..1.0) < 0.05 {
            mode_idx = rng.random_range(0..modes.len());
            mode = modes[mode_idx].to_string();
        }
        if rng.random_range(0.0..1.0) < 0.03 {
            status_idx = rng.random_range(0..statuses.len());
            status = statuses[status_idx].to_string();
        }
        
        // Smooth transitions in vitals to simulate real measurements
        systolic_base += rng.random_range(-3..4);
        systolic_base = systolic_base.clamp(90, 180);
        
        diastolic_base += rng.random_range(-2..3);
        diastolic_base = diastolic_base.clamp(60, 120);
        
        heart_rate_base += rng.random_range(-2..3);
        heart_rate_base = heart_rate_base.clamp(40, 120);
        
        // Add small variations around base values
        let systolic = systolic_base + rng.random_range(-5..6);
        let diastolic = diastolic_base + rng.random_range(-3..4);
        let heart_rate = heart_rate_base + rng.random_range(-2..3);
        
        let mean_arterial_pressure = ((2 * diastolic) + systolic) / 3;
        let pulse_pressure = systolic - diastolic;
        
        let data = BPDeviceData {
            device_id: device_id.clone(),
            timestamp: Utc::now().to_rfc3339(),
            mode: mode.clone(),
            status: status.clone(),
            systolic,
            diastolic,
            heart_rate,
            mean_arterial_pressure,
            pulse_pressure,
            irregular_heartbeat: rng.random_range(0.0..1.0) < 0.1,
        };

        let payload = serde_json::to_string(&data).unwrap_or_default();
        
        batch.push((topic.clone(), payload));
        
        // When batch is full, publish all messages
        if batch.len() >= config.batch_size {
            for (topic, payload) in batch.drain(..) {
                if let Err(e) = client.publish(&topic, QoS::AtLeastOnce, false, payload).await {
                    error!("Failed to publish BP data: {}", e);
                }
            }
            info!("Published batch of {} BP messages from {}", config.batch_size, device_id);
        }
    }
}