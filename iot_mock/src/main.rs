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
    fluid_level: i32,
    flow_rate: i32,
    clot_detected: bool,
}

#[derive(Debug, Serialize)]
struct BPDeviceData {
    device_id: String,
    timestamp: String,
    systolic: f32,
    diastolic: f32,
    heart_rate: i32,
    risk_level: String,
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
    let risk_levels = ["low", "medium", "high"];

    // Process eventloop in the main task to ensure we handle events properly
    // before attempting to publish
    let mut connected = false;
    let event_task = tokio::spawn(async move {
        loop {
            match eventloop.poll().await {
                Ok(event) => {
                    info!("Event: {:?}", event);
                    // Mark as connected when we receive the ConnAck
                    if let rumqttc::Event::Incoming(rumqttc::Incoming::ConnAck(_)) = event {
                        connected = true;
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
            let device_id = dialysis_devices[device_idx];
            let data = DialysisDeviceData {
                device_id: device_id.to_string(),
                timestamp: Utc::now().to_rfc3339(),
                fluid_level: rng.random_range(0..100),
                flow_rate: rng.random_range(50..300),
                clot_detected: rand::random::<f32>() < 0.1,
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
            let risk_idx = rng.random_range(0..risk_levels.len()); 
            let device_id = bp_devices[device_idx];
            let data = BPDeviceData {
                device_id: device_id.to_string(),
                timestamp: Utc::now().to_rfc3339(),
                systolic: rng.random_range(90.0..180.0),
                diastolic: rng.random_range(60.0..120.0),
                heart_rate: rng.random_range(40..120),
                risk_level: risk_levels[risk_idx].to_string(),
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

    // We won't reach this, but for completeness:
    event_task.await?;
    Ok(())
}