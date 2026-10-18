import time
import json
import logging
import os
from datetime import datetime
from urllib.parse import urlparse

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)


def setup_mqtt_connection(iot_endpoint, use_flocli=True):
    """Set up and return MQTT connection."""
    if use_flocli:
        logger.info("Setting up MQTT connection for local Floci testing (raw awscrt plaintext TCP)")
        try:
            from awscrt import io, mqtt

            # 1. Initialize CRT event loop, host resolver, and bootstrap
            event_loop_group = io.EventLoopGroup(1)
            host_resolver = io.DefaultHostResolver(event_loop_group)
            client_bootstrap = io.ClientBootstrap(event_loop_group, host_resolver)

            # 2. Extract host from iot_endpoint and target MQTT port 1883
            if "://" in iot_endpoint:
                parsed_host = urlparse(iot_endpoint).hostname
            else:
                parsed_host = iot_endpoint.split(":")[0]

            host = os.environ.get("MQTT_HOST", parsed_host or "host.docker.internal")
            port = int(os.environ.get("MQTT_PORT", 1883))

            # 3. tls_ctx=None explicitly configures an unencrypted plaintext TCP connection
            client = mqtt.Client(client_bootstrap, tls_ctx=None)

            # 4. Create the raw MQTT connection
            mqtt_connection = mqtt.Connection(
                client=client,
                host_name=host,
                port=port,
                client_id="obd-ii-replay-engine",
                clean_session=False,
                keep_alive_secs=30
            )

            logger.info(f"Connecting via raw TCP to Floci MQTT broker at {host}:{port}...")
            connect_future = mqtt_connection.connect()
            connect_future.result()
            logger.info(f"Connected successfully to Floci MQTT broker at {host}:{port}!")
            return mqtt_connection

        except Exception as e:
            logger.exception(f"Failed to setup Floci MQTT connection: {e}")
            return None
    else:
        # Production AWS IoT Core connection logic (mutual TLS)
        use_mtls = all([
            os.environ.get('IOT_CERT_PATH'),
            os.environ.get('IOT_KEY_PATH'),
            os.environ.get('IOT_ROOT_CA_PATH')
        ])

        if not use_mtls:
            logger.warning("IoT credentials not fully configured, running in simulation mode")
            return None

        try:
            from awsiot import mqtt_connection_builder
            logger.info("Setting up MQTT connection with mutual TLS")
            mqtt_connection = mqtt_connection_builder.mtls_from_path(
                endpoint=iot_endpoint,
                cert_filepath=os.environ.get('IOT_CERT_PATH'),
                pri_key_filepath=os.environ.get('IOT_KEY_PATH'),
                ca_filepath=os.environ.get('IOT_ROOT_CA_PATH'),
                client_id="obd-ii-replay-engine",
                clean_session=False,
                keep_alive_secs=30
            )

            logger.info("Connecting to AWS IoT Core...")
            connect_future = mqtt_connection.connect()
            connect_future.result()
            logger.info("Connected to AWS IoT Core!")
            return mqtt_connection
        except ImportError:
            logger.error("AWS IoT SDK not available. Install with: pip install awsiotsdk")
            return None
        except Exception as e:
            logger.exception(f"Failed to setup MQTT connection: {e}")
            return None


def generate_telemetry_data(vehicle_id):
    """Generate realistic-looking OBD-II telemetry data for a vehicle."""
    return {
        "vehicle_id": vehicle_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "rpm": 1500 + (hash(vehicle_id + str(int(time.time()))) % 3500),  # 1500-5000 RPM
        "speed": (hash(vehicle_id + str(int(time.time()))) % 120),  # 0-120 mph
        "engine_temp": 180 + (hash(vehicle_id + str(int(time.time()))) % 20),  # 180-200°F
        "diagnostic_codes": [] if (hash(vehicle_id + str(int(time.time()))) % 10) != 0 else ["P0123", "P0456"],
        "fuel_level": 10 + (hash(vehicle_id + str(int(time.time()))) % 90),  # 10-100%
        "throttle_position": hash(vehicle_id + str(int(time.time()))) % 100  # 0-100%
    }


def publish_telemetry(mqtt_connection, mqtt_topic, telemetry_data):
    """Publish telemetry data to MQTT topic if connection is available."""
    payload = json.dumps(telemetry_data)
    if mqtt_connection is not None:
        try:
            from awscrt.mqtt import QoS
            mqtt_connection.publish(
                topic=mqtt_topic,
                payload=payload,
                qos=QoS.AT_LEAST_ONCE
            )
            logger.debug(f"Published telemetry for {telemetry_data['vehicle_id']} to {mqtt_topic}")
        except Exception as e:
            logger.exception(f"Failed to publish to MQTT: {e}")
    else:
        # In simulation mode, log every 100th vehicle to avoid excessive output
        if hash(telemetry_data['vehicle_id']) % 100 == 0:
            logger.debug(f"Generated telemetry for {telemetry_data['vehicle_id']}: {payload}")


def main():
    """
    Main function for the OBD-II Replay Engine.
    Reads driving logs from S3 and publishes telemetry data to an MQTT topic (AWS IoT Core).

    Environment variables expected:
    - S3_BUCKET: Name of the S3 bucket containing driving logs
    - MQTT_TOPIC: MQTT topic to publish telemetry data to
    - IOT_ENDPOINT: AWS IoT Core endpoint
    - IOT_CERT_PATH: Path to device certificate
    - IOT_KEY_PATH: Path to device private key
    - IOT_ROOT_CA_PATH: Path to root CA certificate
    """

    # Get configuration from environment variables
    s3_bucket = os.environ.get('S3_BUCKET', 'obd-ii-logs')
    mqtt_topic = os.environ.get('MQTT_TOPIC', 'obdii-telemetry')
    iot_endpoint = os.environ.get('IOT_ENDPOINT', 'http://host.docker.internal:4566')
    # iot_cert_path = os.environ.get('IOT_CERT_PATH')
    # iot_key_path = os.environ.get('IOT_KEY_PATH')
    # iot_root_ca_path = os.environ.get('IOT_ROOT_CA_PATH')

    logger.info(f"Starting OBD-II Replay Engine")
    logger.info(f"S3 Bucket: {s3_bucket}")
    logger.info(f"MQTT Topic: {mqtt_topic}")
    logger.info(f"IoT Endpoint: {iot_endpoint}")

    # Initialize AWS IoT MQTT client
    mqtt_connection = setup_mqtt_connection(iot_endpoint)

    # Simulate reading logs and publishing telemetry
    # In reality, we would list objects in the S3 bucket, download them, and process each record
    vehicle_ids = [f"vehicle_{i:04d}" for i in range(1, 1001)]  # Simulate 1000 vehicles

    logger.info(f"Simulating {len(vehicle_ids)} vehicles")

    try:
        while True:
            # Simulate generating telemetry data for each vehicle
            for vehicle_id in vehicle_ids:
                telemetry_data = generate_telemetry_data(vehicle_id)
                publish_telemetry(mqtt_connection, mqtt_topic, telemetry_data)

            # Sleep to simulate real-time interval (e.g., 1 second between updates)
            time.sleep(1)

    except KeyboardInterrupt:
        logger.info("Shutting down OBD-II Replay Engine")
        if mqtt_connection is not None:
            logger.info("Disconnecting from AWS IoT Core...")
            disconnect_future = mqtt_connection.disconnect()
            disconnect_future.result()
    except Exception as e:
        logger.exception(f"Error in replay engine: {e}")
        if mqtt_connection is not None:
            try:
                mqtt_connection.disconnect()
            except Exception:
                pass  # Best effort disconnect
        raise


if __name__ == "__main__":
    main()