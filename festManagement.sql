/* Creating database if not exists */
DROP DATABASE IF EXISTS FestManagement;
CREATE DATABASE IF NOT EXISTS FestManagement;

USE FestManagement;

/* DDL */
CREATE TABLE IF NOT EXISTS attendee (
    firstName   CHAR(100)   NOT NULL,
    lastName    CHAR(100)   NOT NULL,
    username    CHAR(200)   NOT NULL    UNIQUE,
    password    CHAR(50)    NOT NULL,
   
    CONSTRAINT pk_attendees PRIMARY KEY(userName)
);

CREATE TABLE IF NOT EXISTS bitsians (
    bitsId      CHAR(10)    NOT NULL    UNIQUE,
    username    CHAR(200)   NOT NULL    UNIQUE,
    CONSTRAINT pk_bitsians PRIMARY KEY(username),
    CONSTRAINT fk_username_bitsians FOREIGN KEY(username) REFERENCES attendee(username) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS nonBitsians (
    city        CHAR(100)       NOT NULL,
    age         INT UNSIGNED    NOT NULL,
    phoneNumber BIGINT         NOT NULL    UNIQUE,
    email       CHAR(20)        NOT NULL    UNIQUE,
    username    CHAR(200)       NOT NULL    UNIQUE,
    CONSTRAINT pk_nonBitsians PRIMARY KEY(username),
    CONSTRAINT fk_username_nonBitsians FOREIGN KEY(username) REFERENCES attendee(username) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS  sponsor(
    name           VARCHAR(30)  NOT NULL,
    logo           VARCHAR(200) NOT NULL,
    contribution   INT UNSIGNED NOT NULL,
    sponsor_id     INT UNSIGNED  NOT NULL UNIQUE,
    phoneNumber    BIGINT      NOT NULL UNIQUE,
   
    CONSTRAINT pk_sponsor PRIMARY KEY(sponsor_id)
);

CREATE TABLE IF NOT EXISTS vendor(
    name        VARCHAR(30) NOT NULL,
    location    VARCHAR(30) NOT NULL,
    phoneNumber BIGINT     NOT NULL UNIQUE,
    vendor_id   INT UNSIGNED NOT NULL UNIQUE,

    CONSTRAINT pk_vendor PRIMARY KEY(vendor_id)
);

CREATE TABLE IF NOT EXISTS item(
    name            VARCHAR(30)     NOT NULL,
    quantity        INT UNSIGNED    DEFAULT 0,
    quantity_left   INT UNSIGNED,
    price           INT UNSIGNED    NOT NULL,
    item_id         INT UNSIGNED    NOT NULL UNIQUE AUTO_INCREMENT,
    vendor_id INT UNSIGNED NOT NULL,

    CONSTRAINT CHECK (quantity_left>=0),
    CONSTRAINT CHECK (quantity_left<=quantity),
    CONSTRAINT pk_item PRIMARY KEY(item_id,vendor_id),
    CONSTRAINT fk_item FOREIGN KEY(vendor_id) REFERENCES vendor(vendor_id)
);

CREATE TABLE IF NOT EXISTS event(
    event_id        INT UNSIGNED    NOT NULL UNIQUE AUTO_INCREMENT,
    name            VARCHAR(20)     NOT NULL,
    description     VARCHAR(200)    NOT NULL,
    location        VARCHAR(20)     NOT NULL,
    date_time       DATETIME        NOT NULL,
    duration INT UNSIGNED DEFAULT 0,
    price       INT UNSIGNED    NOT NULL,
    capacity        INT UNSIGNED,
    capacity_left   INT UNSIGNED,

    CONSTRAINT CHECK (capacity_left>=0),
    CONSTRAINT pk_event PRIMARY KEY(event_id)
);

CREATE TABLE IF NOT EXISTS performer(
    name            VARCHAR(20) NOT NULL,
    genre           VARCHAR(20) NOT NULL,
    date_time       DATETIME    NOT NULL,
    phoneNumber     BIGINT     NOT NULL UNIQUE,
    performer_id    INT UNSIGNED NOT NULL UNIQUE,

    CONSTRAINT pk_performer PRIMARY KEY(performer_id)
);

CREATE TABLE IF NOT EXISTS order_book(
    order_id    INT UNSIGNED NOT NULL UNIQUE AUTO_INCREMENT,
    item_id     INT UNSIGNED NOT NULL,
    quantity    INT UNSIGNED,
    total_price INT UNSIGNED,
    username    CHAR(200) NOT NULL,

    CONSTRAINT pk_order_book PRIMARY KEY(order_id),
    CONSTRAINT fk1_order_book FOREIGN KEY(item_id) REFERENCES item(item_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk2_order_book FOREIGN KEY(username) REFERENCES attendee(username) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE IF NOT EXISTS ticket(
    ticket_id   INT UNSIGNED     NOT NULL UNIQUE AUTO_INCREMENT,
    event_id    INT UNSIGNED    NOT NULL,
    username CHAR(200)     NOT NULL,
    Q_order     INT UNSIGNED    DEFAULT 0,    
    Q_used      INT UNSIGNED    DEFAULT 0,

    CONSTRAINT CHECK (Q_used<=Q_order),
    CONSTRAINT pk_ticket PRIMARY KEY(ticket_id,event_id,username),
    CONSTRAINT fk1_ticket FOREIGN KEY (event_id) REFERENCES event(event_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk2_ticket FOREIGN KEY (username) REFERENCES attendee(username) ON DELETE CASCADE ON UPDATE CASCADE
);



CREATE TABLE IF NOT EXISTS performs(
    performer_id    INT UNSIGNED  NOT NULL,
    event_id        INT UNSIGNED NOT NULL,
   
    CONSTRAINT pk_performs PRIMARY KEY(performer_id,event_id),
    CONSTRAINT fk1_performs FOREIGN KEY(performer_id) REFERENCES performer(performer_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk2_performs FOREIGN KEY(event_id) REFERENCES event(event_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS sponsors (
sponsor_id INT UNSIGNED NOT NULL,
    event_id INT UNSIGNED NOT NULL,
    CONSTRAINT pk_sponsors PRIMARY KEY(sponsor_id,event_id),
    CONSTRAINT fk1_sponsors FOREIGN KEY(sponsor_id) REFERENCES sponsor(sponsor_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk2_sponsors FOREIGN KEY(event_id) REFERENCES event(event_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Register Bitsians
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE registerBitsians(
    IN firstName    CHAR(100),
    IN lastName     CHAR(100),
    IN username     CHAR(200),
    IN password     CHAR(50),
    IN bitsId       CHAR(10))
DETERMINISTIC
BEGIN
    INSERT INTO attendee VALUES(firstname, lastname, username, password);
    INSERT INTO bitsians VALUES(bitsId, username);
END$$
DELIMITER ;

-- Register Non Bitsians
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE registerNonBitsians(
    IN firstName    CHAR(100),
    IN lastName     CHAR(100),
    IN username     CHAR(200),
    IN password     CHAR(50),
    IN city         CHAR(100),
    IN age          INT UNSIGNED,
    IN phoneNumber  BIGINT,
    IN email        CHAR(20))
DETERMINISTIC
BEGIN
    INSERT INTO attendee VALUES(firstname, lastname, username, password);
    INSERT INTO nonBitsians VALUES(city, age, phoneNumber, email, userName);
END$$
DELIMITER ;

-- Attendee Login
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
FUNCTION attendeeLogin(
    username    CHAR(200),
    password    CHAR(50))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE auth BOOLEAN;
    IF (SELECT COUNT(*) FROM attendee WHERE attendee.username = username AND attendee.password = password) > 0 THEN
        SET auth = TRUE;
    ELSE
        SET auth = FALSE;
    END IF;
    RETURN auth;
END$$
DELIMITER ;

-- Admin Login
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
FUNCTION adminLogin(
    username    CHAR(200),
    password    CHAR(50))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE auth BOOLEAN;
    IF (SELECT COUNT(*) FROM organiser WHERE organiser.username = username AND organiser.password = password) > 0 THEN
        SET auth = TRUE;
    ELSE
        SET auth = FALSE;
    END IF;
    RETURN auth;
END$$
DELIMITER ;

-- Insert and Update order_book and items
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE insert_update_order(
    IN order_id     INT UNSIGNED,
    IN item_id      INT UNSIGNED,
    IN quantity     INT UNSIGNED,
    IN tot          INT UNSIGNED,
    IN username     CHAR(200))
DETERMINISTIC
BEGIN
UPDATE item SET item.quantity_left = item.quantity_left - quantity where item.item_id = item_id;
    INSERT INTO order_book VALUES(order_id, item_id, quantity, tot, username);
END$$
DELIMITER ;

-- Get User Detail with username
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE getUserDetails(
    IN username CHAR(200))
DETERMINISTIC
BEGIN
IF((SELECT COUNT(*) FROM bitsians WHERE bitsians.username = username)>0) THEN
SELECT * FROM bitsians WHERE bitsians.username=username;
ELSE
SELECT * FROM nonBitsians WHERE nonBitsians.username = username;
END IF;
END$$
DELIMITER;

-- Insert and Update tickets
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE insert_update_ticket(
    IN ticket_id    INT UNSIGNED,
    IN event_id     INT UNSIGNED,
    IN username  VARCHAR(200),
    IN Q_order      INT UNSIGNED,
    IN Q_used     INT UNSIGNED)
DETERMINISTIC
BEGIN
UPDATE event SET event.capacity_left = event.capacity_left - Q_order where event.event_id = event_id;
    INSERT INTO ticket VALUES(ticket_id, event_id,username,Q_order,Q_used);
END$$
DELIMITER ;


CALL registerBitsians("Sarthak", "Goyal", "f20201978", "sarthak", "2020BX1978");
CALL registerBitsians("Akshat", "Kumar", "f20201976", "akshat", "2020BX1976");
CALL registerBitsians("Dhruv", "Singh", "f20200969", "dhruv", "2020BX0969");
CALL registerBitsians("Harsh", "Neema", "f20200878", "harsh", "2020BX0878");
CALL registerBitsians("Kunal", "Gupta", "f20200474", "kunal", "2020BX0474");
CALL registerBitsians("Jay", "Mundhra", "f20200799", "jay", "2020BX0799");
CALL registerBitsians("Archit", "Jain", "f20201222", "archit", "2020BX1222");
CALL registerBitsians("Aaryan", "Raj Jindal", "f20200772", "aaryan", "2020BX0772");
CALL registerBitsians("Harsh", "Todi", "f20201476", "harsh", "2020BX1476");
CALL registerBitsians("Aakash", "Singh Lawana", "f20201450", "aakash", "2020BX1450");
CALL registerBitsians("Saransh", "Gautam", "f20201988", "saransh", "2020BX1988");

CALL registerNonBitsians("ABC1", "DEF1", "abc1", "abc1", "London", 69, 8888888888, "abc1@gmail.com");
CALL registerNonBitsians("ABC2", "DEF2", "abc2", "abc2", "Paris", 69, 8888888889, "abc2@gmail.com");
CALL registerNonBitsians("ABC3", "DEF3", "abc3", "abc3", "Bangkok", 69, 8888888881, "abc3@gmail.com");
CALL registerNonBitsians("ABC4", "DEF4", "abc4", "abc4", "Delhi", 69, 8888888882, "abc4@gmail.com");
CALL registerNonBitsians("ABC5", "DEF5", "abc5", "abc5", "Kanpur", 69, 8888888883, "abc5@gmail.com");
CALL registerNonBitsians("ABC6", "DEF6", "abc6", "abc6", "Kolkata", 69, 8888888887, "abc6@gmail.com");
CALL registerNonBitsians("ABC7", "DEF7", "abc7", "abc7", "Lahore",69, 8880888889, "abc7@gmail.com");
CALL registerNonBitsians("ABC8", "DEF8", "abc8", "abc8", "Jalandhar", 69, 8888828888, "abc8@gmail.com");
CALL registerNonBitsians("ABC9", "DEF9", "abc9", "abc9", "Bhatinda", 69, 8888884888, "abc9@gmail.com");
CALL registerNonBitsians("ABC10", "DEF10", "abc10", "abc10", "Chennai", 69, 8886888888, "abc10@gmail.com");
CALL registerNonBitsians("ABC11", "DEF11", "abc11", "abc11", "Amritsar", 69, 8288888888, "abc11@gmail.com");


INSERT INTO sponsor VALUES
("Red Bull","/random file name","1000000",11001,9173689112),
    ("Kalu Redi","/random file name","10000000",11002,9143686172),
    ("Panasonic","/random file name","2000000",11003,91736822112),
    ("Chhatri","/random file name","4000000",11004,9173689452),
    ("Physics Wallah","/random file name","1500000",11005,7673682212),
    ("MBA ChaiWala","/random file name","1005000",11006,9199633112),
    ("Pepsi","/random file name","1000000",11007,9173469912),
    ("Tesla","/random file name","1000000",11008,9173349112);
   

INSERT INTO vendor VALUES
("MomoMia","FD II",7877886622,"12001"),
    ("Biryani By Kilo","FD I",7877833622,"12002"),
    ("Domino's","FD III",7877886644,"12003"),
    ("Kapde","Rotunda",7977886622,"12004"),
    ("Thode Aur Kapde","FD II",7877899622,"12005"),
    ("Icecream","NAB",7877811622,"12006"),
    ("Gaming VR","FD II",7877822622,"12007"),
    ("Keventers","South Park",7877832622,"12008"),
    ("Vada Pav","Lawns",7877867622,"12009"),
    ("Burger King","Clock Tower",7877891622,"12010");

INSERT INTO event VALUES
(13001,"Concert","Music Night", "cnot","2023-03-10 15:30:00", 2, 500, 1000,1000),
    (13002,"EDM","EDM Night","cnot","2023-03-11 20:30:00", 3, 5000, 1000,1000),
    (13003,"Comedy","Comedy Night","cnot","2023-03-12 17:30:00",4,750,1000,1000),
    (13004,"Dance Show","Dance Show", "cnot","2023-03-10 15:30:00", 2, 500, 1000,1000),
    (13005,"Rap Battle","Rap Battle", "cnot","2023-03-10 15:30:00", 3, 500, 1000,1000),
    (13006,"Robo Wars","Robo Wars", "cnot","2023-03-10 15:30:00", 1, 500, 1000,1000),
    (13007,"Drone Show","Drone Show", "cnot","2023-03-10 15:30:00", 2, 500, 1000,1000),
    (13008,"Drone Race","Drone Race", "cnot","2023-03-10 15:30:00", 3, 500, 1000,1000),
    (13009,"One more Dance Show","Dance Show", "cnot","2023-03-10 15:30:00", 2, 500, 1000,1000),
    (13010,"One more concert","Music Night", "cnot","2023-03-10 15:30:00", 1, 500, 1000,1000),
(13011,"Test No performer","Music Night NO performer", "budh","2023-03-10 15:30:00",1,100,1000,1000),
(13012,"Concert","Music Night", "cnot","2023-03-10 15:30:00", 2, 500, 1000,0),
(13013,"Concert","Music Night", "cnot","2023-03-10 15:30:00", 2, 500, 1000,0),
(13014,"Concert","Music Night", "cnot","2023-03-10 15:30:00", 2, 500, 1000,0);


INSERT INTO performer VALUES
("Kalesh Chauhan","Singing","2023-03-10 15:30:00",9876354661,14001),
    ("Amit Trivedi","Singing","2023-03-11 20:30:00",9876535661,14002),
    ("Sunidhi Chauhan","Dancing","2023-03-12 17:30:00",9876322261,14003),
    ("Sunidhi Chauhan","Singing","2023-03-14 17:30:00",98745322261,14004),
    ("Karunesh Talvar","Comedy","2023-03-12 20:30:00",9873422261,14005),
    ("Akshay Kumar","Acting","2023-03-12 10:30:00",9876324461,14006),
    ("Amitabh Bacchan","Acting","2023-03-15 12:30:00",9876522261,14007),
    ("Deepika Padukone","Acting","2023-03-14 13:30:00",9876122261,14008);
   
   
INSERT INTO item VALUES
("Tshirt1",1000,1000,100,15001,12004),
    ("Tshirt2",1000,1000,100,15002,12004),
    ("Cap",1000,1000,50,15003,12004),
    ("Hoodie",1000,1000,100,15004,12005),
    ("Momo",1000,1000,200,15005,12001),
    ("Pizza",1000,1000,250,15006,12003),
    ("Biryani",1000,1000,90,15007,12002),
    ("Jeans1",1000,1000,300,15008,12005),
    ("MilkShake",1000,1000,500,15009,12008),
    ("Icecream",1000,1000,70,15010,12006),
    ("Burger",1000,1000,80,15011,12010),
    ("Vada Pav",1000,1000,100,15012,12009);
   
INSERT INTO performs VALUES
    (14001,13001),
    (14002,13002),
    (14003,13003),
    (14004,13004),
    (14005,13005),
    (14006,13006),
    (14006,13007),
    (14007,13008),
    (14008,13009),
    (14001,13010),
(14002,13001);


INSERT INTO sponsors VALUES
(11001,13001),
    (11002,13002),
    (11003,13003),
    (11004,13004),
    (11005,13005),
    (11006,13006),
    (11007,13007),
    (11008,13008);
   

CALL insert_update_order (16001,15001,10,1000, "f20201976");
CALL insert_update_order (16002,15002,10,1000, "f20201976");
CALL insert_update_order (16003,15003,10,500, "f20201976");
CALL insert_update_order (16004,15004,10,1000, "f20200474");
CALL insert_update_order (16005,15005,10,2000, "abc1");
CALL insert_update_order (16006,15006,10,2500, "abc1");
CALL insert_update_order (16007,15007,10,900, "f20200799");
CALL insert_update_order (16008,15008,10,3000, "f20200799");
CALL insert_update_order (16009,15009,10,5000, "abc11");
CALL insert_update_order (16010,15010,10,700, "abc8");

CALL insert_update_ticket(17001,13001,"f20201976",10,0);
CALL insert_update_ticket(17002,13002,"f20201976",5,0);
CALL insert_update_ticket(17003,13003,"f20201978",1,0);
CALL insert_update_ticket(17004,13004,"abc1",2,0);
CALL insert_update_ticket(17005,13005,"abc2",4,0);
CALL insert_update_ticket(17006,13006,"f20200799",10,0);
CALL insert_update_ticket(17007,13007,"f20200772",10,0);
CALL insert_update_ticket(17008,13008,"f20201476",10,0);
CALL insert_update_ticket(17009,13009,"abc10",10,0);
CALL insert_update_ticket(17010,13010,"abc11",10,0);



-- Ticket purchased by Attendee
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE ticketPurchasedByAttendee(
    IN username CHAR(200))
DETERMINISTIC
BEGIN
SELECT event.event_id, event.name, event.description, event.location, performer.name as performer_name, event.date_time, ticket.Q_order, ticket.Q_used FROM attendee
INNER JOIN ticket ON ticket.username = attendee.username
INNER JOIN event ON ticket.event_id = event.event_id
LEFT JOIN performs ON event.event_id = performs.event_id
LEFT JOIN performer ON performs.performer_id = performer.performer_id
WHERE attendee.username = username;
END$$
DELIMITER ;

-- Ticket purchased by Attendee for an event
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE ticketPurchasedByAttendeeEvent(
    IN username CHAR(200),
    IN event_id INT UNSIGNED)
DETERMINISTIC
BEGIN
SELECT event.event_id, event.name, event.description, event.location, performer.name as performer_name, event.date_time, ticket.Q_order, ticket.Q_used FROM attendee
INNER JOIN ticket ON ticket.username = attendee.username
INNER JOIN event ON ticket.event_id = event.event_id
LEFT JOIN performs ON event.event_id = performs.event_id
LEFT JOIN performer ON performs.performer_id = performer.performer_id
WHERE attendee.username = username AND event.event_id = event_id;
END$$
DELIMITER ;

-- Item Purchased by Attendee
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE itemPurchasedByAttendee(
IN username CHAR(200))
DETERMINISTIC
BEGIN
SELECT item.name as item_name, item.price as item_price, order_book.order_id, order_book.quantity, order_book.total_price, vendor.name as vendor_name FROM attendee
INNER JOIN order_book ON order_book.username = attendee.username
INNER JOIN item ON item.item_id = order_book.item_id
INNER JOIN vendor ON item.vendor_id = vendor.vendor_id
where attendee.username = username;
END$$
DELIMITER ;

-- Item Available for Sale
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE itemAvailableForSale()
DETERMINISTIC
BEGIN
SELECT item.item_id, item.name as item_name, item.quantity_left, item.price, vendor.name as vendor_name, vendor.location, vendor.phoneNumber FROM item
INNER JOIN vendor ON item.vendor_id = vendor.vendor_id;
END$$
DELIMITER ;

-- Ticket Available for Sale
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE TicketAvailableForSale()
DETERMINISTIC
BEGIN
SELECT event.event_id, event.name as event_name, event.description, event.date_time, event.capacity_left, event.location, event.duration, event.price, performer.name as performer_name FROM event
LEFT JOIN performs ON event.event_id = performs.event_id
LEFT JOIN performer ON performs.performer_id = performer.performer_id;
END$$
DELIMITER ;

-- Function for purchasing ticket
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE purchase_ticket(
    username    CHAR(15),
    event_id INT UNSIGNED,
    quantity INT UNSIGNED,
    OUT status INT UNSIGNED)
DETERMINISTIC
BEGIN
    IF ((select count(*) from ticket where ticket.username = username and ticket.event_id = event_id) > 0 ) then
IF (quantity>(SELECT distinct event.capacity_left FROM event NATURAL JOIN ticket where  ticket.event_id = event_id)) THEN
SET status = FALSE;
ELSE
START TRANSACTION; -- start here
update ticket set Q_order = Q_order+quantity where ticket.username = username and ticket.event_id = event_id;
            SELECT ROW_COUNT() INTO @count1;
            UPDATE event SET capacity_left = capacity_left-quantity where event.event_id = event_id ;
            SELECT ROW_COUNT() INTO @count2;
            COMMIT;
            rollback;
            IF ((@count1 + @count2) = 2) THEN
set status = TRUE;
ELSE
SET status = FALSE;
END IF;
end if;
else
IF (quantity>(SELECT distinct event.capacity_left FROM event NATURAL JOIN ticket where  ticket.event_id = event_id)) THEN
SET status = FALSE;
ELSE
START TRANSACTION;
INSERT INTO ticket (event_id, username, Q_order, Q_used)VALUES (event_id,username,quantity,0);
            SELECT ROW_COUNT() INTO @count1;
UPDATE event SET capacity_left = capacity_left-quantity where event.event_id = event_id ;
            SELECT ROW_COUNT() INTO @count1;
            COMMIT;
            ROLLBACK;
IF ((@count1 + @count2) = 2) THEN
set status = TRUE;
ELSE
SET status = FALSE;
END IF;
           
END IF;
end if;
END$$
DELIMITER ;

-- Function for purchasing item
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE purchase_item(
    item_id     INT UNSIGNED,
    quantity INT UNSIGNED,
    username CHAR(200),
    OUT status INT UNSIGNED)
DETERMINISTIC
BEGIN -- start here
    IF (quantity>(SELECT item.quantity_left FROM item where item.item_id = item_id)) THEN
        SET status = FALSE;
    ELSE
SELECT ROW_COUNT() INTO @count1;
INSERT INTO order_book (item_id, quantity, total_price, username) VALUES (item_id,quantity,(SELECT price FROM item where item.item_id = item_id)*quantity, username);
        SELECT ROW_COUNT() INTO @count1;
        UPDATE item SET quantity_left = quantity_left-quantity where item.item_id = item_id;
        SELECT ROW_COUNT() INTO @count2;
        COMMIT;
        ROLLBACK;
        IF ((@count1 + @count2) = 2) THEN
set status = TRUE;
ELSE
SET status = FALSE;
END IF;
    END IF;
END$$
DELIMITER ;



-- QUESTION QUERIES

-- 1. #Tickets sold for a particular event
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE TicketsSold(
IN event_id INT UNSIGNED)
DETERMINISTIC
BEGIN
SELECT SUM(Q_order) as Sum_total FROM ticket
WHERE ticket.event_id = event_id;
END$$
DELIMITER ;
call TicketsSold(13001);


-- 2. Events for which tickets are sold out
SELECT * FROM event
WHERE capacity_left = 0;

 
--  3. #Total Revenue generated by the sale of tickets
DELIMITER $$
CREATE DEFINER=`root`@`localhost`
PROCEDURE RevenueFromAnEvent(
IN event_id INT UNSIGNED)
DETERMINISTIC
BEGIN
SELECT SUM(event.price*Q_order) FROM ticket
    INNER JOIN event ON ticket.event_id = event.event_id
WHERE ticket.event_id = event_id;
END$$
DELIMITER ;
call RevenueFromAnEvent(13001);

SELECT SUM(event.price*Q_order) as tot_rev FROM ticket
    INNER JOIN event ON ticket.event_id = event.event_id
WHERE ticket.event_id = 13001;


-- 4 #Vendors that have applied for participation
SELECT * from vendor;


-- 5 Number of Attendees that have purchased ticket for a particular event
DELIMITER $
CREATE DEFINER=`root`@`localhost`
PROCEDURE NumAttendeesEvent(
IN event_id INT UNSIGNED)
DETERMINISTIC
BEGIN
SELECT SUM(Q_order) AS count FROM ticket
WHERE ticket.event_id = event_id;
END$$
DELIMITER ;
CALL NumAttendeesEvent(13002);


-- 6 Sponsors for a particular event
DELIMITER $
CREATE DEFINER=`root`@`localhost`
PROCEDURE sponsorsEvent(
IN event_id INT UNSIGNED)
DETERMINISTIC
BEGIN
SELECT * FROM sponsors NATURAL JOIN sponsor
WHERE sponsors.event_id = event_id;
END$$
DELIMITER ;
CALL sponsorsEvent(13001);

-- 7. #Events with the Maximum Ticketes Sold
WITH T(event_id,name,tot) AS
(SELECT event.event_id,event.name,SUM(Q_order)
 FROM event NATURAL JOIN ticket
 GROUP BY event.event_id,event.name),
M(max_value) AS
(SELECT MAX(tot) FROM T)
SELECT T.event_id,T.name,T.tot
FROM T,M
WHERE T.tot = M.max_value;
 
-- 8 Ticket Price for a specific event
SELECT price FROM ticket NATURAL JOIN event
WHERE event.event_id = "13001";
 
-- 9 Performers Scheduled to perform at a particular event
DELIMITER $
CREATE DEFINER=`root`@`localhost`
PROCEDURE performersInEvent(
IN event_id INT UNSIGNED)
DETERMINISTIC
BEGIN
SELECT event.event_id,event.name,performer.performer_id,performer.name,performer.genre
FROM performs,performer,event
WHERE performs.performer_id = performer.performer_id
AND event.event_id = performs.event_id
AND event.event_id = event_id;
END$$
DELIMITER ;
CALL performersInEvent(13001);

-- 10. Number of Tickets sold for all events combined
SELECT SUM(Q_order) FROM ticket;


-- 11 Events on a particular Date
SELECT * FROM event
WHERE CAST(event.date_time as DATE) = "2023-03-10";
