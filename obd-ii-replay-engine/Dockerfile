# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
# Vulnerable package for testing Trivy scan - CVE-2018-18074
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install 'requests==2.18.4'

# Make port 80 available to the world outside this container
EXPOSE 8080

# Define environment variables (example)
ENV S3_BUCKET=obd-ii-logs
ENV MQTT_TOPIC=obdii-telemetry

# Run the application when the container launches
CMD ["python", "replay_engine.py"]