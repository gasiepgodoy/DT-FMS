brokerAddress = "tcp://127.0.0.1";
port = 1884; 

response = "ACK";
station_number = 4;

mqClient = mqttclient(brokerAddress, Port=port);
fprintf("Successfully connected to broker\n")

topic  = "test";
        
payloadReady = struct( ...
    "station",  station_number, ...
    "response", response ...
);
        
write(mqClient, topic, jsonencode(payloadReady));
fprintf("Message sent\n");
