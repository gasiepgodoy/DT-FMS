CREATE DATABASE IF NOT EXISTS MES_POLIMI;
CREATE DATABASE IF NOT EXISTS MES_UNESP;

USE MES_POLIMI;

CREATE TABLE Products (
    product_type CHAR(1) PRIMARY KEY,
    Station1Stop BOOLEAN DEFAULT FALSE,
    Station1Op VARCHAR(50),
    Station2Stop BOOLEAN DEFAULT FALSE,
    Station2Op VARCHAR(50),
    Station3Stop BOOLEAN DEFAULT FALSE,
    Station3Op VARCHAR(50),
    Station4Stop BOOLEAN DEFAULT FALSE,
    Station4Op VARCHAR(50),
    Station5Stop BOOLEAN DEFAULT FALSE,
    Station5Op VARCHAR(50),
    Station6Stop BOOLEAN DEFAULT FALSE,
    Station6Op VARCHAR(50),
    Station7Stop BOOLEAN DEFAULT FALSE,
    Station7Op VARCHAR(50)
);

CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    nb_product INT NOT NULL,
    product_type CHAR(1),
    status ENUM('WAITING', 'QUEUED', 'IN_PROGRESS', 'PAUSED', 'FINISHED'),
    FOREIGN KEY (product_type) REFERENCES Products(product_type),
    priority BOOLEAN DEFAULT FALSE
);

CREATE TABLE Production (
    productSN VARCHAR(50) PRIMARY KEY,
    order_id INT,
    cart_id INT,
    current_station ENUM('Station1', 'Station2', 'Station3', 'Station4', 'Station5', 'Station6', 'Station7', 'OUT'),
    visited_stations VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    status ENUM('QUEUED', 'IN_PROGRESS', 'PAUSED', 'FINISHED')
);

-- Inserts avec guillemets simples et les 7 stations
INSERT INTO Products (
    product_type, Station1Stop, Station1Op, Station2Stop, Station2Op, 
    Station3Stop, Station3Op, Station4Stop, Station4Op, Station5Stop, Station5Op,
    Station6Stop, Station6Op, Station7Stop, Station7Op
) VALUES (
    'A', TRUE, 'Drop 1 Cover', TRUE, '2 Holes', FALSE, NULL, FALSE, NULL, 
    TRUE, 'Drop 1 Cover', TRUE, 'Pressing', TRUE, 'Manual Pickup'
);

INSERT INTO Products (
    product_type, Station1Stop, Station1Op, Station2Stop, Station2Op, 
    Station3Stop, Station3Op, Station4Stop, Station4Op, Station5Stop, Station5Op,
    Station6Stop, Station6Op, Station7Stop, Station7Op
) VALUES (
    'B', TRUE, 'Drop 1 Cover', TRUE, '4 Holes', TRUE, NULL, TRUE, '2 Picture', 
    TRUE, 'Drop 1 Cover', TRUE, 'Pressing', TRUE, 'Robot Pickup'
);

INSERT INTO Products (
    product_type, Station1Stop, Station1Op, Station2Stop, Station2Op, 
    Station3Stop, Station3Op, Station4Stop, Station4Op, Station5Stop, Station5Op,
    Station6Stop, Station6Op, Station7Stop, Station7Op
) VALUES (
    'C', TRUE, 'Drop 1 Cover', TRUE, '2 Holes', FALSE, NULL, TRUE, '1 Picture', 
    FALSE, NULL, FALSE, NULL, TRUE, 'Manual Pickup'
);

USE MES_UNESP;

CREATE TABLE Products (
    product_type CHAR(1) PRIMARY KEY,
    Station1Stop BOOLEAN DEFAULT FALSE,
    Station1Op VARCHAR(50),
    Station2Stop BOOLEAN DEFAULT FALSE,
    Station2Op VARCHAR(50),
    Station3Stop BOOLEAN DEFAULT FALSE,
    Station3Op VARCHAR(50),
    Station4Stop BOOLEAN DEFAULT FALSE,
    Station4Op VARCHAR(50),
    Station5Stop BOOLEAN DEFAULT FALSE,
    Station5Op VARCHAR(50),
    Station6Stop BOOLEAN DEFAULT FALSE,
    Station6Op VARCHAR(50),
    Station7Stop BOOLEAN DEFAULT FALSE,
    Station7Op VARCHAR(50)
);

CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    nb_product INT NOT NULL,
    product_type CHAR(1),
    status ENUM('WAITING', 'QUEUED', 'IN_PROGRESS', 'PAUSED', 'FINISHED'),
    FOREIGN KEY (product_type) REFERENCES Products(product_type),
    priority BOOLEAN DEFAULT FALSE
);

CREATE TABLE Production (
    productSN VARCHAR(50) PRIMARY KEY,
    order_id INT,
    cart_id INT,
    current_station ENUM('Station1', 'Station2', 'Station3', 'Station4', 'Station5', 'Station6', 'Station7', 'OUT'),
    visited_stations VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    status ENUM('QUEUED', 'IN_PROGRESS', 'PAUSED', 'FINISHED')
);

-- Inserts avec guillemets simples et les 7 stations
INSERT INTO Products (
    product_type, Station1Stop, Station1Op, Station2Stop, Station2Op, 
    Station3Stop, Station3Op, Station4Stop, Station4Op, Station5Stop, Station5Op,
    Station6Stop, Station6Op, Station7Stop, Station7Op
) VALUES (
    'A', TRUE, 'Drop 1 Cover', TRUE, '2 Holes', FALSE, NULL, FALSE, NULL, 
    TRUE, 'Drop 1 Cover', TRUE, 'Pressing', TRUE, 'Manual Pickup'
);

INSERT INTO Products (
    product_type, Station1Stop, Station1Op, Station2Stop, Station2Op, 
    Station3Stop, Station3Op, Station4Stop, Station4Op, Station5Stop, Station5Op,
    Station6Stop, Station6Op, Station7Stop, Station7Op
) VALUES (
    'B', TRUE, 'Drop 1 Cover', TRUE, '4 Holes', TRUE, NULL, TRUE, '2 Picture', 
    TRUE, 'Drop 1 Cover', TRUE, 'Pressing', TRUE, 'Robot Pickup'
);

INSERT INTO Products (
    product_type, Station1Stop, Station1Op, Station2Stop, Station2Op, 
    Station3Stop, Station3Op, Station4Stop, Station4Op, Station5Stop, Station5Op,
    Station6Stop, Station6Op, Station7Stop, Station7Op
) VALUES (
    'C', TRUE, 'Drop 1 Cover', TRUE, '2 Holes', FALSE, NULL, TRUE, '1 Picture', 
    FALSE, NULL, FALSE, NULL, TRUE, 'Manual Pickup'
);