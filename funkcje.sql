--Funkcja dodająca nowego uczestnika do bazy.

CREATE OR REPLACE FUNCTION add_participant(lastname varchar, firstname varchar, mail varchar)
RETURNS VOID AS $$
BEGIN
	INSERT INTO participants values(default, lastname, firstname, mail);
END;
$$ language plpgsql;



--Funkcja dodająca nową konferencję do bazy. Użytkownik podaje kod pocztowy lokalizacji, w której odbywa się konferencja, a przy
--wykorzystaniu funkcji get\_id\_from\_postalcode(postalcode) do tabeli zostaje wpisane ID kodu pocztowego.

CREATE OR REPLACE FUNCTION add_conference(ctopic varchar, sdate date, edate date, postal varchar, sdiscount decimal)
RETURNS VOID AS $$
BEGIN
	INSERT INTO Conference VALUES (default, ctopic, sdate, edate, get_id_from_postalcode(postal), sdiscount);
END;
$$ LANGUAGE plpgsql;



--Funkcja zwracająca ID kodu pocztowego o podanej nazwie.

CREATE OR REPLACE FUNCTION get_id_from_postalcode(postal varchar)
RETURNS INT AS $idpc$
DECLARE idpc int;
BEGIN
	SELECT postalcodeid INTO idpc FROM postalcodes WHERE postalcode = postal;
	RETURN idpc;
END;
$idpc$ LANGUAGE plpgsql;



--Funkcja dodająca do bazy klientów firmowych.

CREATE OR REPLACE FUNCTION add_company_customer(
caddress varchar,
cpostalcode varchar,
cphone varchar,
clogin varchar,
cpassword varchar,
cmail varchar,
ccompanyname varchar,
cfax varchar) RETURNS VOID AS $$
DECLARE
	id int;
BEGIN
	INSERT INTO customers VALUES (default, 'company', caddress, get_id_from_postalcode(cpostalcode), cphone, clogin, cpassword, cmail)
	RETURNING customerid INTO id;
	INSERT INTO companycustomers VALUES (id, ccompanyname, cfax);
END;
$$ language plpgsql


--Funkcja dodająca klientów indywidulanych.

CREATE OR REPLACE FUNCTION add_individual_customer(
caddress varchar,
cpostalcode varchar,
cphone varchar,
clogin varchar,
cpassword varchar,
cmail varchar,
clastname varchar,
cfirstname varchar
) RETURNS VOID AS $$
DECLARE
	id int;
BEGIN
	INSERT INTO customers VALUES (default, 'person', caddress, get_id_from_postalcode(cpostalcode), cphone, clogin, cpassword, cmail)
	RETURNING customerid INTO id;
	INSERT INTO individualcustomers VALUES (id, clastname, cfirstname);
END;
$$ language plpgsql


--Funkcja dodająca nową płatność do bazy.

CREATE OR REPLACE FUNCTION add_payment(
pbookingid INT,
ptime date,
pamount decimal
) RETURNS VOID AS $$
BEGIN
	INSERT INTO payments VALUES (default, pbookingid, ptime, pamount);
END;
$$ language plpgsql



--Funkcja dodająca nowy dzień konferencji do bazy.

CREATE OR REPLACE FUNCTION add_conference_day(
confid int,
confdate date,
daytopic varchar,
starttime time,
endtime time,
address varchar,
roomno varchar,
noseats int,
baseprice decimal
) RETURNS VOID AS $$
BEGIN
	INSERT INTO ConferenceDay VALUES (confid, confdate, daytopic, starttime, endtime, address, roomno, noseats, baseprice);
END;
$$ language plpgsql



--CREATE OR REPLACE FUNCTION add_workshop(
confid int,
confdate date,
starttime time,
endtime time,
address varchar,
roomno varchar,
noseats int,
baseprice decimal
) RETURNS VOID AS $$
BEGIN
	INSERT INTO Workshop VALUES (default, confid, confdate, starttime, endtime, address, roomno, noseats, baseprice);
END;
$$ language plpgsql


--Funkcja dodająca nowy próg cenowy do bazy danych.

CREATE OR REPLACE FUNCTION add_pricetreshold(
confid int,
until time,
discout decimal
) RETURNS VOID AS $$
BEGIN
	INSERT INTO PriceTresholds VALUES (confid, until, discount);
END;
$$ language plpgsql



--Funkcja dodaje nową rezerwację konferencji do bazy.

CREATE OR REPLACE FUNCTION add_conference_booking(
confid int,
until time,
customerid int,
bookingtime date
) RETURNS VOID AS $$
BEGIN
	INSERT INTO ConferenceBookings VALUES (default, until, customerid, bookingtime);
END;
$$ language plpgsql


--Funkcja ta dodaje rezerwacje na dany dzień koferencji.

CREATE OR REPLACE FUNCTION add_day_booking(
bookingid int,
confid int,
confdate time,
noseats int,
nostudents int
) RETURNS VOID AS $$
BEGIN
	INSERT INTO DayBookings VALUES (default, bookingid, confid, confdate, noseats, nostudents);
END;
$$ language plpgsql



--Dodaje rezerwacje na dany warsztat do bazy.

CREATE OR REPLACE FUNCTION add_workshop_booking(
daybookingid int,
workshopid int,
noseats int,
nostudents int
) RETURNS VOID AS $$
BEGIN
	INSERT INTO WorkshopBookings VALUES (daybookingid, workshopid, noseats, nostudents);
END;
$$ language plpgsql



--Funkcja dodaje nowy kod pocztowy do bazy.

CREATE OR REPLACE FUNCTION add_postal_code(
postal_code varchar,
city_name varchar,
country_name varchar
) RETURNS VOID AS $$
DECLARE
	city int;
	country int;
BEGIN
	SELECT INTO country CountryID FROM Countries c WHERE CountryName = country_name;
	IF country IS NULL THEN
          INSERT INTO Countries VALUES (default, country_name) RETURNING countryid INTO country;
	END IF;
	SELECT INTO city CityID FROM Cities c WHERE CityName = city_name;
	IF city IS NULL THEN
          INSERT INTO Cities VALUES (default, city_name, country) RETURNING cityid INTO city;
	END IF;
	INSERT INTO PostalCodes VALUES (default, postalcode, city);
END;
$$ language plpgsql;



--Funkcja zwraca łączną kwotę wpłaconą na rzecz danej rezerwacji.

CREATE OR REPLACE FUNCTION conference_day_booked_seats (cid INT, cdate DATE)
RETURNS INT AS $$
DECLARE
  booked_seats INT;
BEGIN
  booked_seats = (SELECT SUM(noseats)
                    FROM DayBookings db
                    WHERE db.confdate = cdate AND db.confid = cid);
  RETURN COALESCE(booked_seats, 0);
END;
$$ LANGUAGE plpgsql;



--Funkcja zwraca ilość zarezerwonych miejsc dla danego dnia konferencji.

CREATE OR REPLACE FUNCTION conference_day_booked_seats (cid INT, cdate DATE)
RETURNS INT AS $$
DECLARE
	booked_seats INT;
BEGIN
	booked_seats = (SELECT SUM(noseats) FROM DayBookings db
					JOIN ConferenceDay cd ON db.confid = cd.confid AND db.confdate = cd.confdate
				    WHERE db.confdate = cdate AND db.cid = db.confid);
	RETURN COALESCE(booked_seats, 0);
END;
$$ LANGUAGE plpgsql;




--Funkcja zwracająca ilość zarezerwowanych miejsc na dany warsztat.\\


CREATE OR REPLACE FUNCTION workshop_booked_seats (wid INT)
RETURNS INT AS $$
DECLARE
  booked_seats INT;
BEGIN
  booked_seats = (SELECT SUM(noseats)
                    FROM WorkshopBookings
                    WHERE workshopid = wid);
RETURN COALESCE(booked_seats, 0);
END;
$$ LANGUAGE plpgsql;



--Funkcja zwraca tabele zawierającą dane osobe uczestników oraz adres mailowy dla wskazanego warsztatu.//

CREATE OR REPLACE FUNCTION workshop_participants_list (wid INT)
RETURNS TABLE (
participant_id INT,
last_name VARCHAR,
first_name VARCHAR,
email VARCHAR
) AS $$
BEGIN
RETURN QUERY
  SELECT Participants.ParticipantID,
         LastName, FirstName, Mail
    FROM Participants
      NATURAL JOIN ConferenceParticipations
      NATURAL JOIN WorkshopParticipations
      NATURAL JOIN WorkshopBookings
    WHERE WorkshopID = wid;
END;
$$ LANGUAGE plpgsql;


--Dla argumentu będącego nazwą miasta, jej częścią lub wrażeniem regularnym zwraca pasujące miasta razem z kodami pocztowymi.

CREATE OR REPLACE FUNCTION find_codes_for_city(city varchar) RETURNS SETOF RECORD AS $$
  SELECT CityName, PostalCodeID, PostalCode
    FROM Cities NATURAL LEFT JOIN PostalCodes
    WHERE SUBSTRING(CityName FROM city) IS NOT NULL;
$$ LANGUAGE SQL;




--Dla każdej mającej już ponad tydzień nieopłaconej rezerwacji usuwa z bazy informację o liczbie zarezerwowanych miejsc i tym, komu były przypisane.

CREATE OR REPLACE FUNCTION invalidate_late_unpaid_bookings() RETURNS VOID AS $$
  DELETE FROM DayBookings
    WHERE BookingID IN
      (SELECT BookingID
            FROM unpaid_bookings
              WHERE NOW() > BookingTime + INTERVAL '1 week');
$$ LANGUAGE SQL;



--Usuwa informacje o rezerwacjach na 0 miejsc nie mających żadnych wpłat.

CREATE OR REPLACE FUNCTION remove_empty_bookings() RETURNS VOID AS $$
  DELETE FROM ConferenceBookings
    WHERE BookingID IN
      (SELECT BookingID
         FROM ConferenceBookings
           NATURAL LEFT JOIN DayBookings
           NATURAL LEFT JOIN Payments
         WHERE DayBookingID IS NULL AND PaymentID IS NULL);
$$ LANGUAGE SQL;



--Dodaje uczestnika do danej listy zarezerwowanych miejsc na konferencję, zwraca id uczestnictwa, także w przypadku, gdy taka rezerwacja już istniała.

CREATE OR REPLACE FUNCTION add_day_participant(first_name varchar, last_name varchar,
					       mailstr varchar, day_booking_id INT,
					       out participation_id INT) AS $$
DECLARE
  participant_id INT;
BEGIN
  SELECT ParticipantID INTO participant_id
    FROM Participants
    WHERE LastName = last_name AND
          FirstName = first_name AND
	  Mail = mailstr;

  IF part_id IS NULL THEN
    EXECUTE 'INSERT INTO Participants
               VALUES(DEFAULT, $1, $2, $3)
               RETURNIN ParticipantID'
      INTO STRICT participant_id
      USING last_name, first_name, mailstr;
  END IF;

  SELECT ParticipationID INTO participation_id
    FROM ConferenceParticipations
      NATURAL JOIN ConferenceBookings
      NATURAL JOIN DayBookings
    WHERE DayBookingID = day_id;

  IF participation_id IS NULL THEN
    EXECUTE 'INSERT INTO ConferenceParticipations
               VALUES(DEFAULT, $1, (SELECT BookingID FROM DayBookings
                                      WHERE DayBookingID = $2),
                      NULL) RETURNING ParticipationID'
      INTO STRICT participation_id
      USING participant_id, day_booking_id;
  END IF;

  IF NOT EXISTS (SELECT ParticipationID
                   FROM DayParticipations
		   WHERE DayBookingID = day_booking_id AND
		         ParticipationID = participation_id) THEN
    EXECUTE 'INSERT INTO DayParticipations
               VALUES($1, $2)'
      USING participation_id, day_booking_id;
  END IF;

END;
$$ LANGUAGE plpgsql;



--Dodaje uczestnika do danej listy zarezerwowanych miejsc na warsztat.

CREATE OR REPLACE FUNCTION add_workshop_participant(first_name varchar, last_name varchar,
				  	            mailstr varchar, day_booking_id INT,
						    workshop_id INT,
					            out participation_id INT) AS $$
BEGIN
  participation_id :=
    add_day_participant(first_name, last_name, mailstr, day_booking_id);

  INSERT INTO WorkshopParticipations
    VALUES(participation_id, day_booking_id, workshop_id);
END;
$$ LANGUAGE plpgsql;



--Dla argumentu będącego nazwą polskiego miasta zwraca jego id dodając je do bazy, jeśli wcześniej nie było tam umieszczone.

CREATE OR REPLACE FUNCTION id_for_polish_city(city VARCHAR, out id INT) AS $$
DECLARE
poland INT;
BEGIN
SELECT INTO id CityID
FROM Cities
WHERE CityName = city;
IF id IS NULL THEN
SELECT INTO STRICT poland CountryID
FROM Countries
WHERE CountryName = 'Polska';
EXECUTE 'INSERT INTO Cities VALUES(DEFAULT, $1, $2) RETURNING CityID'
INTO STRICT id
USING city, poland;
END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION is_valid_mail(mailstring varchar) RETURNS boolean AS
$$
SELECT mailstring SIMILAR TO '_+@_+._+';
$$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION is_valid_phone_or_fax(p_or_f char) RETURNS boolean AS
$$
  SELECT p_or_f IS NULL OR p_or_f SIMILAR TO '\+?[[:digit:]]{3,15}';
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION is_valid_login(login char) RETURNS boolean AS
$$
  SELECT login SIMILAR TO '[[:alnum:][._.]-]+';
$$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION is_valid_polish_zip(zip char) RETURNS boolean AS
$$
  SELECT zip SIMILAR TO '[[:digit:]]{2}-[[:digit:]]{3}';
$$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION is_valid_name(namestring varchar) RETURNS BOOLEAN AS
$$
SELECT namestring SIMILAR TO '[[:alpha:]]+(['' -][[:alpha:]]+)*';
$$ LANGUAGE SQL;



CREATE OR REPLACE FUNCTION is_valid_student_id(id char) RETURNS BOOLEAN AS
$$
  SELECT id SIMILAR TO '[[:alnum:]]+';
$$ LANGUAGE SQL;



--Funkcja pomocnicza, zwraca typ klienta.

CREATE OR REPLACE FUNCTION get_customer_type(id INT) RETURNS VARCHAR AS $$
  SELECT CustomerType FROM Customers c WHERE id = c.CustomerID;
$$ LANGUAGE SQL;


--Funkcja pomocnicza, sprawdza czy w podanej tabeli znajduje się CustomerID o podanej wartości.

CREATE OR REPLACE FUNCTION does_customerid_appear_in(id INT, queried_table VARCHAR, OUT res BOOLEAN) AS $$
  BEGIN
    EXECUTE FORMAT('SELECT EXISTS (
                      SELECT * FROM %s c
               	        WHERE c.CustomerID = $1)',
		   queried_table)
      INTO STRICT res
      USING id;
  END;
$$ LANGUAGE plpgsql;





--Funkcja pomocnicza, sprawdza, czy dwa przedziały czasowe na siebie nachodzą

CREATE OR REPLACE FUNCTION time_ranges_collide(start1 TIME, end1 TIME, start2 TIME,
                                              end2 TIME, OUT res BOOLEAN) AS $$
  BEGIN
    res := end2 > start1 AND start2 < end1;
  END;
$$ LANGUAGE plpgsql;