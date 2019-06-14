CREATE VIEW upcoming_conferences AS
SELECT Conf.ConfID,
       Conf.ConfTopic,
       Conf.StartDate,
       Conf.EndDate,
       Cities.CityName,
       Countries.CountryName,
	   COALESCE((SELECT SUM(NoSeats) FROM ConferenceDay cd WHERE cd.confid = Conf.confid), 0) -  COALESCE((SELECT SUM(NoSeats) FROM DayBookings db WHERE db.confid = Conf.confid), 0) AS avaliable_places
FROM Conference Conf
JOIN PostalCodes PC ON Conf.PostalCodeID = PC.PostalCodeID
JOIN Cities ON Cities.CityID = PC.CityID
JOIN Countries ON Countries.CountryID = Cities.CountryID
WHERE NOW() < Conf.StartDate -- NOW() is  equivalent to GETDATE()
GROUP BY Conf.ConfID,
         Cities.CityName,
         Countries.CountryName
ORDER BY Conf.StartDate,
         Conf.ConfTopic





CREATE VIEW conferences_history AS
SELECT Conf.ConfID,
       Conf.ConfTopic,
       Conf.StartDate,
       Conf.EndDate,
       Cities.CityName,
       Countries.CountryName,
       SUM(DB.NoSeats) AS participants
FROM Conference Conf
JOIN PostalCodes PC ON Conf.PostalCodeID = PC.PostalCodeID
JOIN Cities ON Cities.CityID = PC.CityID
JOIN Countries ON Countries.CountryID = Cities.CountryID
JOIN ConferenceDay CD ON Conf.ConfID = CD.ConfID
JOIN DayBookings DB ON DB.ConfID = CD.ConfID
WHERE NOW() > Conf.EndDate
GROUP BY Conf.ConfID,
         Cities.CityName,
         Countries.CountryName
ORDER BY Conf.EndDate DESC,
         Conf.ConfTopic






CREATE VIEW present_conferences AS
SELECT Conf.ConfID,
       Conf.ConfTopic,
       Conf.StartDate,
       Conf.EndDate,
       Cities.CityName,
       Countries.CountryName,
       (SELECT SUM(NoSeats) FROM ConferenceDay cd WHERE cd.confid = Conf.confid) AS total_places,
	   (SELECT SUM(NoSeats) FROM DayBookings db WHERE db.confid = Conf.confid) AS taken_places
FROM Conference Conf
JOIN PostalCodes PC ON Conf.PostalCodeID = PC.PostalCodeID
JOIN Cities ON Cities.CityID = PC.CityID
JOIN Countries ON Countries.CountryID = Cities.CountryID
JOIN ConferenceDay CD ON Conf.ConfID = CD.ConfID
JOIN DayBookings DB ON DB.ConfID = CD.ConfID
WHERE NOW() > Conf.StartDate AND NOW() < Conf.EndDate
GROUP BY Conf.ConfID,
         Cities.CityName,
         Countries.CountryName
ORDER BY Conf.StartDate,
         Conf.ConfTopic




CREATE VIEW unpaid_bookings AS
SELECT Customers.CustomerID,
       CompanyCustomers.CompanyName AS name,
       Customers.Phone || ' ' || CompanyCustomers.Fax AS phone_fax,
       Customers.Mail,
      (DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount)) AS price_after_discount,
       ((DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount)) - P.Amount) AS money_to_pay
FROM Customers
JOIN CompanyCustomers ON CompanyCustomers.CustomerID = Customers.CustomerID
JOIN ConferenceBookings CB ON Customers.CustomerID = CB.CustomerID
LEFT JOIN Payments P ON P.BookingID = CB.BookingID
JOIN DayBookings DB ON CB.BookingID = DB.BookingID
JOIN ConferenceDay CD ON DB.ConfID = CD.ConfID
JOIN Conference ON Conference.ConfID = CD.ConfID
JOIN PriceTresholds PT ON PT.ConfID = Conference.ConfID
WHERE (DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount)) > P.Amount
UNION
SELECT Customers.CustomerID,
       IC.firstname || ' ' || IC.lastname AS name,
       Customers.Phone AS phone_fax,
       Customers.Mail,
       (DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount)) AS final_price,
       ((DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount)) - P.Amount) AS money_to_pay
FROM Customers
JOIN IndividualCustomers IC ON IC.CustomerID = Customers.CustomerID
JOIN ConferenceBookings CB ON Customers.CustomerID = CB.CustomerID
LEFT JOIN Payments P ON P.BookingID = CB.BookingID
JOIN DayBookings DB ON CB.BookingID = DB.BookingID
JOIN ConferenceDay CD ON DB.ConfID = CD.ConfID
JOIN Conference ON Conference.ConfID = CD.ConfID
JOIN PriceTresholds PT ON PT.ConfID = Conference.ConfID
WHERE (DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount)) > P.Amount







CREATE VIEW overpaid_bookings AS
SELECT Customers.CustomerID,
       CompanyCustomers.CompanyName AS name,
       Customers.Phone || ' ' || CompanyCustomers.Fax AS phone_fax,
       Customers.Mail,
       (P.Amount - (DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount))) AS money_to_return
FROM Customers
JOIN CompanyCustomers ON CompanyCustomers.CustomerID = Customers.CustomerID
JOIN ConferenceBookings CB ON Customers.CustomerID = CB.CustomerID
LEFT JOIN Payments P ON P.BookingID = CB.BookingID
JOIN DayBookings DB ON CB.BookingID = DB.BookingID
JOIN ConferenceDay CD ON DB.ConfID = CD.ConfID
JOIN Conference ON Conference.ConfID = CD.ConfID
JOIN PriceTresholds PT ON PT.ConfID = Conference.ConfID
WHERE (DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount)) <  P.Amount
UNION
SELECT Customers.CustomerID,
       IC.firstname || ' ' || IC.lastname AS name,
       Customers.Phone AS phone_fax,
       Customers.Mail,
       (P.Amount - (DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount))) AS money_to_return
FROM Customers
JOIN IndividualCustomers IC ON IC.CustomerID = Customers.CustomerID
JOIN ConferenceBookings CB ON Customers.CustomerID = CB.CustomerID
LEFT JOIN Payments P ON P.BookingID = CB.BookingID
JOIN DayBookings DB ON CB.BookingID = DB.BookingID
JOIN ConferenceDay CD ON DB.ConfID = CD.ConfID
JOIN Conference ON Conference.ConfID = CD.ConfID
JOIN PriceTresholds PT ON PT.ConfID = Conference.ConfID
WHERE (DB.NoSeats * CD.BasePrice * (1 - PT.Discount)) - DB.NoStudents * (CD.BasePrice * (1 - Conference.StudentDiscount)) < P.Amount







CREATE VIEW regular_individual_customers AS
SELECT ID.CustomerID,
       ID.FirstName,
       ID.LastName,
       Customers.Address,
       Customers.Phone,
       Customers.Mail,
       COUNT(CB.BookingID) AS conferences_attended
FROM IndividualCustomers ID
JOIN Customers ON ID.CustomerID = Customers.CustomerID
JOIN ConferenceBookings CB ON CB.CustomerID = Customers.CustomerID
GROUP BY ID.CustomerID,
         Customers.CustomerID
ORDER BY conferences_attended DESC
LIMIT 20






CREATE VIEW regular_company_customers AS
SELECT CC.CustomerID,
       CC.CompanyName,
       Customers.Address,
       Customers.Phone,
       CC.Fax,
       Customers.Mail,
       COUNT(CB.BookingID) AS conferences_attended
FROM CompanyCustomers CC
JOIN Customers ON CC.CustomerID = Customers.CustomerID
JOIN ConferenceBookings CB ON CB.CustomerID = Customers.CustomerID
GROUP BY CC.CustomerID,
         Customers.CustomerID
ORDER BY conferences_attended DESC
LIMIT 50



CREATE VIEW conferences_popularity AS
SELECT Conference.ConfID,
       Conference.ConfTopic,
       Conference.StartDate || ' -- ' || Conference.EndDate AS date,
       COUNT(*) FILTER (WHERE CP.StudentID IS NOT NULL) AS students,
       COUNT(CP.ParticipantID) AS all_participants
FROM Conference
JOIN ConferenceBookings CB ON CB.ConfID = Conference.ConfID
JOIN ConferenceParticipations CP ON CP.BookingID = CB.BookingID
GROUP BY Conference.ConfID
ORDER BY all_participants DESC






CREATE VIEW conferences_popularity_among_students AS
SELECT Conference.ConfID,
       Conference.ConfTopic,
       Conference.StartDate || ' -- ' || Conference.EndDate AS date,
       COUNT(*) FILTER (WHERE CP.StudentID IS NOT NULL) AS students,
       COUNT(CP.ParticipantID) AS all_participants
FROM Conference
JOIN ConferenceBookings CB ON CB.ConfID = Conference.ConfID
JOIN ConferenceParticipations CP ON CP.BookingID = CB.BookingID
GROUP BY Conference.ConfID
ORDER BY students DESC




CREATE VIEW financial_stats AS
SELECT EXTRACT(YEAR FROM Payments.PaymentTime) AS year,
       EXTRACT(MONTH FROM Payments.PaymentTime) AS month,
       SUM(Payments.Amount) AS money_earned
FROM Payments
GROUP BY ROLLUP(year, month)
ORDER BY year,
         month





CREATE VIEW best_years_and_months AS
SELECT EXTRACT(YEAR FROM Payments.PaymentTime) AS year,
       EXTRACT(MONTH FROM Payments.PaymentTime) AS month,
       SUM(Payments.Amount) AS money
FROM Payments
GROUP BY ROLLUP(year, month)
ORDER BY money DESC


CREATE VIEW workshop_popularity AS
SELECT Workshop.WorkshopID,
       Workshop.ConfDate AS date,
       Workshop.Address,
       SUM(WB.NoSeats) AS all_participants
FROM Workshop
JOIN WorkshopBookings WB ON WB.WorkshopID = Workshop.WorkshopID
GROUP BY Workshop.WorkshopID
ORDER BY all_participants DESC



CREATE VIEW workshop_popularity_among_students AS
SELECT Workshop.WorkshopID,
       Workshop.ConfDate AS date,
       Workshop.Address,
       COUNT(*) FILTER (WHERE CP.StudentID IS NOT NULL) AS students,
       SUM(WB.NoSeats) AS all_participants
FROM Workshop
JOIN WorkshopBookings WB ON WB.WorkshopID = Workshop.WorkshopID
JOIN WorkshopParticipations WP ON WP.WorkshopID = WB.WorkshopID
JOIN ConferenceParticipations CP ON CP.ParticipationID = WP.ParticipationID
GROUP BY Workshop.WorkshopID
ORDER BY students DESC
