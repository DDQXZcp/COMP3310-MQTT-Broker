import paho.mqtt.client as mqtt
import time

# Flags
received_lab = False
received_content = False

username = 'comp3310'
password = 'comp3310'

# Callback when connected
def on_connect(client, userdata, flags, rc):
    print("Connected with result code", rc)
    client.subscribe([("comp3310/lab", 0), ("comp3310/content", 0)])

# Callback when a message is received
def on_message(client, userdata, msg):
    global received_lab, received_content
    topic = msg.topic
    payload = msg.payload.decode()

    if topic == "comp3310/lab":
        print(f"Received lab: {payload}")
        received_lab = True
    elif topic == "comp3310/content":
        print(f"Received content: {payload}")
        received_content = True

# Create client
client = mqtt.Client()
client.username_pw_set(username, password)
client.on_connect = on_connect
client.on_message = on_message

client.connect("52.63.194.183", 1883, 60)
client.loop_start()

# Now publish 1–100 once per second
for i in range(1, 101):
    client.publish("comp3310/counter", str(i), qos=0)
    print(f"Published: {i}")
    time.sleep(1)

client.loop_stop()
client.disconnect()
