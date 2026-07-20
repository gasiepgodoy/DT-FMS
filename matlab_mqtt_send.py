#!/usr/bin/env python3
import sys
import json
import paho.mqtt.publish as publish

BROKER = "localhost"
PORT = 1884
TOPIC = "test"

if len(sys.argv) < 3:
    print("Usage: matlab_mqtt_send.py <station> <signal>")
    sys.exit(1)

station = int(sys.argv[1])
signal = sys.argv[2]

payload = json.dumps({"station": station, "response": signal})
publish.single(TOPIC, payload=payload, hostname=BROKER, port=PORT)
print(f"Sent: station={station}, signal={signal}")
