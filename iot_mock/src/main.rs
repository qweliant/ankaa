use rumqttc::{MqttOptions, AsyncClient, QoS};
use serde::{Serialize, Deserialize};
use std::time::Duration;
use tokio::time;
use rand::Rng;
use chrono::Utc;

// Structs matching your Elixir schemas
#[derive(Debug, Serialize)]
struct DialysisDeviceData {
    device_id: String,
    timestamp: String,  // ISO8601 format
    fluid_level: i32,
    flow_rate: i32,
    clot_detected: bool,
}

#[derive(Debug, Serialize)]
struct BPDeviceData {
    device_id: String,
    timestamp: String,  // ISO8601 format
    systolic: f32,
    diastolic: f32,
    heart_rate: i32,
    risk_level: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // MQTT connection setup
    let mut mqtt_options = MqttOptions::new(
        "iot_device_simulator", 
        "localhost",  // Replace with your MQTT broker address
        1883
    );
    mqtt_options.set_keep_alive(Duration::from_secs(5));

    let (client, mut eventloop) = AsyncClient::new(mqtt_options, 10);

    // Simulate multiple devices
    let dialysis_device_ids = ["dialysis_001", "dialysis_002", "dialysis_003"];
    let bp_device_ids = ["bp_001", "bp_002", "bp_003"];

    // Start publishing data
    let mut interval = time::interval(Duration::from_secs(5));  // Send data every 5 seconds

    loop {
        interval.tick().await;

        // Randomly choose a device to simulate
        let device_type = rand::random::<bool>();

        if device_type {
            // Simulate dialysis device
            let device_id = dialysis_device_ids[rand::thread_rng().gen_range(0..dialysis_device_ids.len())];
            let data = DialysisDeviceData {
                device_id: device_id.to_string(),
                timestamp: Utc::now().to_rfc3339(),
                fluid_level: rand::thread_rng().gen_range(0..100),
                flow_rate: rand::thread_rng().gen_range(50..300),
                clot_detected: rand::random::<f32>() < 0.1,  // 10% chance of clot
            };

            let topic = format!("devices/{}/telemetry", device_id);
            let payload = serde_json::to_string(&data)?;
            
            client.publish(topic, QoS::AtLeastOnce, false, payload).await?;
            println!("Published dialysis data: {:?}", data);
        } else {
            // Simulate BP device
            let device_id = bp_device_ids[rand::thread_rng().gen_range(0..bp_device_ids.len())];
            let risk_levels = ["low", "medium", "high"];
            
            let data = BPDeviceData {
                device_id: device_id.to_string(),
                timestamp: Utc::now().to_rfc3339(),
                systolic: rand::thread_rng().gen_range(90.0..180.0),
                diastolic: rand::thread_rng().gen_range(60.0..120.0),
                heart_rate: rand::thread_rng().gen_range(40..120),
                risk_level: risk_levels[rand::thread_rng().gen_range(0..risk_levels.len())].to_string(),
            };

            let topic = format!("devices/{}/telemetry", device_id);
            let payload = serde_json::to_string(&data)?;
            
            client.publish(topic, QoS::AtLeastOnce, false, payload).await?;
            println!("Published BP data: {:?}", data);
        }

        // Check for MQTT events (not strictly needed for publishing)
        if let Ok(event) = eventloop.poll().await {
            println!("MQTT Event: {:?}", event);
        }
    }
}