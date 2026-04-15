brokerAddress = "tcp://127.0.0.1";
port = 1884; 

response = "DONE";

mqClient = mqttclient(brokerAddress, Port=port);
fprintf("Successfully connected to broker\n")

topic  = "test";
        
payloadReady = struct( ...
    "sn",  "16_1776083060292", ...
    "response", response ...
);
        
write(mqClient, topic, jsonencode(payloadReady));
fprintf("Message sent\n");
