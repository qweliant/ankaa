use rumqttc::{MqttOptions, AsyncClient, QoS};
use serde::Serialize;
use std::time::Duration;
use tokio::time;
use rand::Rng;
use chrono::Utc;
use std::env;
use log::{info, error};

#[derive(Debug, Serialize)]
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

#[derive(Debug, Serialize)]
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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();
    info!("Starting IoT device simulator");

    let mqtt_host = env::var("MQTT_HOST").unwrap_or_else(|_| "mqtt".to_string());
    info!("Connecting to MQTT broker at {}", mqtt_host);
    
    let mut mqtt_options = MqttOptions::new(
        "iot_device_simulator", 
        mqtt_host, 
        1883
    );
    
    // Increase timeouts to give more time for connection establishment
    mqtt_options.set_keep_alive(Duration::from_secs(30));
    mqtt_options.set_clean_session(true);
    
    // Uncomment if your broker requires authentication
    // mqtt_options.set_credentials("user", "password");
    
    // Create client with smaller event loop capacity to prevent overwhelming
    let (client, mut eventloop) = AsyncClient::new(mqtt_options, 100);
    
    let client_clone = client.clone();
    
    // Device configurations
    let dialysis_devices = ["dialysis_001", "dialysis_002", "dialysis_003"];
    let bp_devices = ["bp_001", "bp_002", "bp_003"];
    let modes = ["HD", "HDF", "HF"];
    let statuses = ["normal", "warning", "critical"];

    // Process eventloop in the main task to ensure we handle events properly
    // before attempting to publish
    tokio::spawn(async move {
        loop {
            match eventloop.poll().await {
                Ok(event) => {
                    info!("Event: {:?}", event);
                    if let rumqttc::Event::Incoming(rumqttc::Incoming::ConnAck(_)) = event {
                        info!("Successfully connected to MQTT broker!");
                    }
                },
                Err(e) => {
                    error!("Error from eventloop: {}", e);
                    // Add some delay before retrying to prevent tight loops
                    time::sleep(Duration::from_secs(1)).await;
                }
            }
        }
    });

    // Wait a bit for connection to establish before publishing
    time::sleep(Duration::from_secs(3)).await;
    
    let mut interval = time::interval(Duration::from_secs(3));
    let mut rng = rand::rng();

    loop {
        interval.tick().await;

        if rand::random::<bool>() {
            // Generate dialysis device data
            let device_idx = rng.random_range(0..dialysis_devices.len());
            let mode_idx = rng.random_range(0..modes.len());
            let status_idx = rng.random_range(0..statuses.len());
            let device_id = dialysis_devices[device_idx];
            
            let data = DialysisDeviceData {
                device_id: device_id.to_string(),
                timestamp: Utc::now().to_rfc3339(),
                mode: modes[mode_idx].to_string(),
                status: statuses[status_idx].to_string(),
                time_in_alarm: if statuses[status_idx] == "normal" { None } else { Some(rng.random_range(1..60)) },
                time_in_treatment: rng.random_range(0..240),
                time_remaining: rng.random_range(0..240),
                dfv: rng.random_range(0.0..100.0),
                dfr: rng.random_range(0.0..500.0),
                ufv: rng.random_range(0.0..10.0),
                ufr: rng.random_range(0.0..1000.0),
                bfr: rng.random_range(50..500),
                ap: rng.random_range(-200..200),
                vp: rng.random_range(-200..200),
                ep: rng.random_range(-200..200),
            };

            let topic = format!("devices/{}/telemetry", device_id);
            let payload = serde_json::to_string(&data)?;

            match client_clone.publish(topic, QoS::AtLeastOnce, false, payload).await {
                Ok(_) => info!("Published dialysis data from {}", device_id),
                Err(e) => {
                    error!("Failed to publish dialysis data: {}", e);
                    // Add a small delay to prevent tight error loops
                    time::sleep(Duration::from_millis(500)).await;
                }
            }
        } else {
            // Generate BP device data
            let device_idx = rng.random_range(0..bp_devices.len());
            let mode_idx = rng.random_range(0..modes.len());
            let status_idx = rng.random_range(0..statuses.len());
            let device_id = bp_devices[device_idx];
            
            let systolic = rng.random_range(90..180);
            let diastolic = rng.random_range(60..120);
            let heart_rate = rng.random_range(40..120);
            let mean_arterial_pressure = ((2 * diastolic) + systolic) / 3;
            let pulse_pressure = systolic - diastolic;
            
            let data = BPDeviceData {
                device_id: device_id.to_string(),
                timestamp: Utc::now().to_rfc3339(),
                mode: modes[mode_idx].to_string(),
                status: statuses[status_idx].to_string(),
                systolic,
                diastolic,
                heart_rate,
                mean_arterial_pressure,
                pulse_pressure,
                irregular_heartbeat: rand::random::<f32>() < 0.1,
            };

            let topic = format!("devices/{}/telemetry", device_id);
            let payload = serde_json::to_string(&data)?;

            match client_clone.publish(topic, QoS::AtLeastOnce, false, payload).await {
                Ok(_) => info!("Published BP data from {}", device_id),
                Err(e) => {
                    error!("Failed to publish BP data: {}", e);
                    // Add a small delay to prevent tight error loops
                    time::sleep(Duration::from_millis(500)).await;
                }
            }
        }
    }
}