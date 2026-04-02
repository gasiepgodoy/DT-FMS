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
    Station6Op VARCHAR(50)
);

CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    nb_product INT NOT NULL,
    product_type CHAR(1),
    FOREIGN KEY (product_type) REFERENCES Products(product_type)
);

CREATE TABLE Production (
    productSN INT PRIMARY KEY,
    order_id INT,
    cart_id INT,
    current_station ENUM('Station1', 'Station2', 'Station3', 'Station4', 'Station5', 'Station6'),
    visited_stations VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

INSERT INTO Products (product_type, Station1Stop, Station1Op, Station2Stop, Station2Op, Station3Stop, Station3Op,Station4Stop, Station4Op,Station5Stop, Station5Op,Station6Stop, Station6Op)
VALUES ('A', TRUE, "Move Cart", TRUE, "Drop Front Cover", TRUE, "Drill Both Holes", FALSE, NULL, TRUE, "Drop Back Cover", FALSE, NULL );