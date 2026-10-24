FROM python:3.9-slim
WORKDIR /app
COPY . /app
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --upgrade 'requests>=2.20.0' 'urllib3>=1.24.2' 'jaraco.context>=6.1.0'
EXPOSE 8080
ENV S3_BUCKET=obd-ii-logs
ENV MQTT_TOPIC=obdii-telemetry
CMD ["python", "replay_engine.py"]
