use rumqttc::{MqttOptions, AsyncClient, QoS, Event, Incoming};
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
    
    let mut mqtt_options = MqttOptions::new(
        "iot_device_simulator", 
        mqtt_host, 
        1883
    );
    mqtt_options.set_keep_alive(Duration::from_secs(5));

    let (client, mut eventloop) = AsyncClient::new(mqtt_options, 10);

    // Device configurations
    let dialysis_devices = ["dialysis_001", "dialysis_002", "dialysis_003"];
    let bp_devices = ["bp_001", "bp_002", "bp_003"];
    let risk_levels = ["low", "medium", "high"];

    // Spawn a task to handle MQTT events
    tokio::spawn(async move {
        while let Ok(event) = eventloop.poll().await {
            match event {
                Event::Incoming(Incoming::Publish(p)) => {
                    info!("Received message on topic {}: {:?}", p.topic, p.payload);
                }
                Event::Incoming(Incoming::ConnAck(_)) => {
                    info!("Successfully connected to MQTT broker");
                }
                Event::Incoming(Incoming::SubAck(_)) => {
                    info!("Subscription acknowledged");
                }
                e => {
                    info!("MQTT event: {:?}", e);
                }
            }
        }
    });

    let mut interval = time::interval(Duration::from_secs(3));

    loop {
        interval.tick().await;

        if rand::random::<bool>() {
            // Generate dialysis device data
            let device_id = dialysis_devices[rand::rng().random_range(0..dialysis_devices.len())];
            let data = DialysisDeviceData {
                device_id: device_id.to_string(),
                timestamp: Utc::now().to_rfc3339(),
                fluid_level: rand::rng().random_range(0..100),
                flow_rate: rand::rng().random_range(50..300),
                clot_detected: rand::random::<f32>() < 0.1,
            };

            let topic = format!("devices/{}/telemetry", device_id);
            let payload = serde_json::to_string(&data)?;

            if let Err(e) = client.publish(topic, QoS::AtLeastOnce, false, payload).await {
                error!("Failed to publish dialysis data: {}", e);
            } else {
                info!("Published dialysis data from {}", device_id);
            }
        } else {
            // Generate BP device data
            let device_id = bp_devices[rand::rng().random_range(0..bp_devices.len())];
            let data = BPDeviceData {
                device_id: device_id.to_string(),
                timestamp: Utc::now().to_rfc3339(),
                systolic: rand::rng().random_range(90.0..180.0),
                diastolic: rand::rng().random_range(60.0..120.0),
                heart_rate: rand::rng().random_range(40..120),
                risk_level: risk_levels[rand::rng().random_range(0..risk_levels.len())].to_string(),
            };

            let topic = format!("devices/{}/telemetry", device_id);
            let payload = serde_json::to_string(&data)?;

            if let Err(e) = client.publish(topic, QoS::AtLeastOnce, false, payload).await {
                error!("Failed to publish BP data: {}", e);
            } else {
                info!("Published BP data from {}", device_id);
            }
        }
    }
}