brokerAddress = "tcp://127.0.0.1";
port = 1884; 

response = "DONE";
station_number = 5;

mqClient = mqttclient(brokerAddress, Port=port);
fprintf("Successfully connected to broker\n")

topic  = "test";
        
payloadReady = struct( ...
    "station",  station_number, ...
    "response", response ...
);
        
write(mqClient, topic, jsonencode(payloadReady));
fprintf("Message sent\n");
