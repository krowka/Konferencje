CREATE TABLE IF NOT EXISTS Countries
(CountryID SERIAL PRIMARY KEY,
 CountryName VARCHAR(45) NOT NULL,
 UNIQUE(CountryName));

CREATE TABLE IF NOT EXISTS Cities
(CityID SERIAL PRIMARY KEY,
 CityName VARCHAR(45) NOT NULL,
 CountryID INT NOT NULL,
 FOREIGN KEY (CountryID) REFERENCES Countries);

CREATE TABLE IF NOT EXISTS PostalCodes
(PostalCodeID SERIAL PRIMARY KEY,
 PostalCode VARCHAR(10) NOT NULL,
 CityID INT NOT NULL,
 UNIQUE(PostalCode, CityID),
 FOREIGN KEY (CityID) REFERENCES Cities);

CREATE TABLE IF NOT EXISTS Conference
(ConfID SERIAL PRIMARY KEY,
 ConfTopic VARCHAR(100) NULL,
 StartDate DATE NOT NULL,
 EndDate DATE NOT NULL,
 PostalCodeID INT NOT NULL,
 StudentDiscount DECIMAL NOT NULL,
 CHECK (StartDate <= EndDate),
 CHECK (StudentDiscount >= 0),
 FOREIGN KEY (PostalCodeID) REFERENCES PostalCodes);

CREATE TABLE IF NOT EXISTS Customers
(CustomerID SERIAL PRIMARY KEY,
 CustomerType VARCHAR(7) NOT NULL,
 Address VARCHAR(45) NOT NULL,
 PostalCodeID INT NOT NULL,
 Phone VARCHAR(16) NOT NULL,
 Login VARCHAR(25) NOT NULL,
 Password VARCHAR(35) NOT NULL,
 Mail VARCHAR(70) NOT NULL,
 UNIQUE (Phone),
 UNIQUE (login),
 UNIQUE (Mail),
 CHECK (is_valid_phone_or_fax(Phone)),
 CHECK (is_valid_login(Login)),
 CHECK (is_valid_mail(Mail)),
 CHECK (CustomerType IN('company','person')),
 FOREIGN KEY (PostalCodeID) REFERENCES PostalCodes);

CREATE TABLE IF NOT EXISTS CompanyCustomers
(CustomerID SERIAL PRIMARY KEY,
 CompanyName VARCHAR(45) NOT NULL,
 Fax VARCHAR(16) NULL,
 CHECK (is_valid_phone_or_fax(Fax)),
 FOREIGN KEY (CustomerID) REFERENCES Customers);

CREATE TABLE IF NOT EXISTS IndividualCustomers
(CustomerID SERIAL PRIMARY KEY,
 LastName VARCHAR(45) NOT NULL,
 FirstName VARCHAR(45) NOT NULL,
 CHECK (is_valid_name(FirstName)),
 CHECK (is_valid_name(LastName)),
 FOREIGN KEY (CustomerID) REFERENCES Customers);

CREATE TABLE IF NOT EXISTS ConferenceBookings
(BookingID SERIAL PRIMARY KEY,
 ConfID INT NOT NULL,
 CustomerID INT NOT NULL,
 BookingTime TIMESTAMP NOT NULL,
 UNIQUE (BookingID, ConfID),
 FOREIGN KEY (ConfID) REFERENCES Conference,
 FOREIGN KEY (CustomerID) REFERENCES Customers);

CREATE TABLE IF NOT EXISTS ConferenceDay
(ConfID INT NOT NULL,
 ConfDate DATE NOT NULL,
 DayTopic VARCHAR(100) NULL,
 StartTime TIME NOT NULL,
 EndTime TIME NOT NULL,
 Address VARCHAR(45) NOT NULL,
 RoomNo VARCHAR(15) NULL,
 NoSeats INT NOT NULL,
 BasePrice DECIMAL NOT NULL,
 PRIMARY KEY (ConfID, ConfDate),
 CHECK (NoSeats > 0),
 CHECK (BasePrice >= 0),
 FOREIGN KEY (ConfID) REFERENCES Conference);

CREATE TABLE IF NOT EXISTS Workshop
(WorkshopID SERIAL PRIMARY KEY,
 ConfID INT NOT NULL,
 ConfDate DATE NOT NULL,
 WorkshopTopic VARCHAR(100) NULL,
 StartTime TIME NOT NULL,
 EndTime TIME NOT NULL,
 Address VARCHAR(45) NOT NULL,
 RoomNo VARCHAR(15) NULL,
 NoSeats INT NOT NULL,
 BasePrice DECIMAL NOT NULL,
 CHECK (EndTime > StartTime),
 CHECK (NoSeats > 0),
 CHECK (BasePrice >= 0),
 FOREIGN KEY (ConfID, ConfDate) REFERENCES ConferenceDay);

CREATE TABLE IF NOT EXISTS DayBookings
(DayBookingID SERIAL PRIMARY KEY,
 BookingID INT NOT NULL,
 ConfID INT NOT NULL,
 ConfDate DATE NOT NULL,
 NoSeats INT NOT NULL,
 NoStudents INT NOT NULL,
 CHECK (NoSeats > 0),
 CHECK (NoStudents >= 0),
 CHECK (NoStudents <= NoSeats),
 FOREIGN KEY (BookingID, ConfID) REFERENCES ConferenceBookings(BookingID, ConfID),
 FOREIGN KEY (ConfID, ConfDate) REFERENCES ConferenceDay);

CREATE TABLE IF NOT EXISTS WorkshopBookings
(DayBookingID INT NOT NULL,
 WorkshopID INT NOT NULL,
 NoSeats INT NOT NULL,
 NoStudents INT NOT NULL,
 CHECK (NoSeats > 0),
 CHECK (NoStudents >= 0),
 CHECK (NoStudents <= NoSeats),
 PRIMARY KEY (DayBookingID, WorkshopID),
 FOREIGN KEY (DayBookingID) REFERENCES DayBookings,
 FOREIGN KEY (WorkshopID) REFERENCES Workshop);

CREATE TABLE IF NOT EXISTS Participants
(ParticipantID SERIAL PRIMARY KEY,
 LastName VARCHAR(45) NULL,
 Firstname VARCHAR(45) NULL,
 Mail VARCHAR(70) NOT NULL,
 UNIQUE (Mail),
 CHECK (is_valid_name(FirstName)),
 CHECK (is_valid_name(LastName)),
 CHECK (is_valid_mail(Mail)));

CREATE TABLE IF NOT EXISTS ConferenceParticipations
(ParticipationID SERIAL PRIMARY KEY,
 ParticipantID INT NOT NULL,
 BookingID INT NOT NULL,
 StudentID CHAR(20) NULL,
 CHECK (StudentID IS NULL OR is_valid_student_id(StudentID)),
 FOREIGN KEY (ParticipantID) REFERENCES Participants,
 FOREIGN KEY (BookingID) REFERENCES ConferenceBookings);

CREATE TABLE IF NOT EXISTS DayParticipations
(ParticipationID INT NOT NULL,
 DayBookingID INT NOT NULL,
 PRIMARY KEY (ParticipationID, DayBookingID),
 FOREIGN KEY (DayBookingID) REFERENCES DayBookings,
 FOREIGN KEY (ParticipationID) REFERENCES ConferenceParticipations);

CREATE TABLE IF NOT EXISTS WorkshopParticipations
(ParticipationID INT NOT NULL,
 DayBookingID INT NOT NULL,
 WorkshopID INT NOT NULL,
 PRIMARY KEY (ParticipationID, DayBookingID, WorkshopID),
 FOREIGN KEY (ParticipationID, DayBookingID) REFERENCES DayParticipations,
 FOREIGN KEY (WorkshopID , DayBookingID) REFERENCES WorkshopBookings);

CREATE TABLE IF NOT EXISTS PriceTresholds
(ConfID INT NOT NULL,
 Until TIMESTAMP NOT NULL,
 Discount DECIMAL NOT NULL,
 CHECK (Discount >= 0),
 PRIMARY KEY (ConfID, Until),
 FOREIGN KEY (ConfID) REFERENCES Conference);

CREATE TABLE IF NOT EXISTS Payments
(PaymentID SERIAL PRIMARY KEY,
 BookingID INT NOT NULL,
 PaymentTime TIMESTAMP NOT NULL,
 Amount DECIMAL NOT NULL,
 FOREIGN KEY (BookingID) REFERENCES ConferenceBookings);
