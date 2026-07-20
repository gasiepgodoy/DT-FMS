#!/usr/bin/env python3
import sys
import json
import paho.mqtt.client as mqtt

BROKER = "localhost"
PORT = 1884
TOPIC = "test"
received = False

def on_message(client, userdata, msg):
    global received
    try:
        payload = json.loads(msg.payload.decode())
        if payload.get('action') == 'DECISION':
            print("DECISION_RECEIVED")
            received = True
            client.disconnect()
    except:
        pass

client = mqtt.Client()
client.on_message = on_message
client.connect(BROKER, PORT, 60)
client.subscribe(TOPIC)
client.loop_forever()
