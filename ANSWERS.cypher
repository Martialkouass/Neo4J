/****** ANSWERS ******/

// 1)  Identify the number of infected and healthy people in the sample of 40 individuals

MATCH (n:Person)
RETURN SUM (CASE WHEN n.healthStatus='Infected' THEN 1 ELSE 0 END) AS NumInfected,
SUM (CASE WHEN n.healthStatus='Healthy' THEN 1 ELSE 0 END) AS NumHealthy;

// 2)  Find healthy individuals who have been in contact with a person who tested positive

MATCH (infected:Person {healthStatus:'Infected'})-[:VISITS_LOCATION]->(l:Location)<-[:VISITS_LOCATION]-(healthy:Person {healthStatus:'Healthy'})
RETURN DISTINCT healthy.personName AS HealthyPerson,infected.personName AS InfectedPerson , l.locationName;

//3)  Show a graph with healthy individuals who have coincided with an infected person, specifically with "Maxwell Ramirez"

MATCH (infected:Person {healthStatus:'Infected',personName:'Maxwell Ramirez'})-[:VISITS_LOCATION]->(l:Location)<-[:VISITS_LOCATION]-(healthy:Person {healthStatus:'Healthy'})
RETURN DISTINCT healthy , infected,l;

// 4)  Build the same query as above but show the result as a table and not as a graph (table or text format) displaying the fields:


MATCH (infected:Person {healthStatus:'Infected'})-[:MAKES_VISIT]->(v2:Visit)-[:TO_ESTABLISHMENT]->(l:Location)<-[:TO_ESTABLISHMENT]-(v1:Visit)<-[:MAKES_VISIT]-(healthy:Person {healthStatus:'Healthy'})
RETURN DISTINCT infected AS Virus_spreader,v2.visitEnd AS  Start_virus_spreading ,l.locationName AS Establishment ,healthy AS Person_at_risk, v1.visitStart AS Start_visit_person_at_risk;


// 5)   Build a table (text and table format) that identifies for each infected person (first column), the healthy individuals with whom they have coincided in an establishment at the same time. Build as the second column an array of JSON elements called "Contacts" with keys:


MATCH (infected:Person {healthStatus:'Infected'})-[:MAKES_VISIT]->(v_infected:Visit)-[:TO_ESTABLISHMENT]->(l:Location)<-[:TO_ESTABLISHMENT]-(v_healthy:Visit)<-[:MAKES_VISIT]-(healthy:Person {healthStatus:'Healthy'})
WHERE v_infected.visitStart <v_healthy.visitEnd AND v_infected.visitEnd >v_healthy.visitStart
RETURN infected.personName AS Spreader,
Collect ({Person_in_contact:healthy.personName,
Establishment:l.locationName,
Start_date_overlap: v_healthy.visitStart,
End_date_overlap: v_healthy.visitEnd}) AS Contact;

//6)  Once the previous query is obtained, by adding three statements to it, obtain a table that has the name of the infected person and another column with the number of healthy individuals they have had contact with, obtaining that number from the elements of the JSON array

MATCH (infected:Person {healthStatus:'Infected'})-[:MAKES_VISIT]->(v_infected:Visit)-[:TO_ESTABLISHMENT]->(l:Location)<-[:TO_ESTABLISHMENT]-(v_healthy:Visit)<-[:MAKES_VISIT]-(healthy:Person {healthStatus:'Healthy'})
WHERE v_infected.visitStart <v_healthy.visitEnd AND v_infected.visitEnd >v_healthy.visitStart
WITH infected , COUNT (DISTINCT healthy) AS Number_of_healthy_contacts,Collect ({Person_in_contact:healthy.personName,
Establishment:l.locationName,
Start_date_overlap: v_healthy.visitStart,
End_date_overlap: v_healthy.visitEnd}) AS Contact
RETURN infected.personName AS  Infected_person,Number_of_healthy_contacts,Contact
ORDER BY Number_of_healthy_contacts DESC;

// 7)  Find those individuals (if any) who visited an establishment even after knowing they had tested positive.

MATCH (n:Person {healthStatus:'Infected'})-[:MAKES_VISIT]->(v_infected:Visit)-[:TO_ESTABLISHMENT]->(l:Location)
WHERE v_infected.visitStart>n.testResultTime
RETURN n.personName AS InfectedPerson,l AS Establisment,n.testResultTime AS TestDate,v_infected.visitStart AS VisitDate;

//8)  Now that all healthy individuals who coincided in any establishment with an infected person have been obtained, it is desired to find out the exact time (duration) that each healthy person coincided with person p1

MATCH (infected:Person{healthStatus:'Infected'})-[:MAKES_VISIT]->(v_infected:Visit)-[:TO_ESTABLISHMENT]->(l:Location)<-[:TO_ESTABLISHMENT]-(v_healthy:Visit)<-[:MAKES_VISIT]-(healthy:Person{healthStatus:'Healthy'})
WITH infected, healthy, v_infected, v_healthy, l,
    toFloat(apoc.coll.max([timestamp(v_infected.visitStart), timestamp(v_healthy.visitStart)])) AS Start_date_overlap,
    toFloat(apoc.coll.min([timestamp(v_infected.visitEnd), timestamp(v_healthy.visitEnd)])) AS End_date_overlap
WITH infected, healthy, l,
    CASE
        WHEN Start_date_overlap <= End_date_overlap
        THEN ROUND((End_date_overlap - Start_date_overlap) / (1000 * 60 * 60), 4)
        ELSE 0
    END AS Spreading_duration
RETURN healthy.personName AS HealthyPerson, infected.personName AS InfectedPerson, l.locationName AS Establishment, Spreading_duration
ORDER BY Spreading_duration DESC;


// 9)   A person has been in two different places with infected individuals; in one, they were in contact for an hour and a half, and in the other, for two hours. The total exposure of that person will have been three and a half hours

MATCH (infected:Person{healthStatus:'Infected'})-[:MAKES_VISIT]->(v_infected:Visit)-[:TO_ESTABLISHMENT]->(l:Location)<-[:TO_ESTABLISHMENT]-(v_healthy:Visit)<-[:MAKES_VISIT]-(healthy:Person{healthStatus:'Healthy'})
WITH infected, healthy, v_infected, v_healthy, l,
    toFloat(apoc.coll.max([timestamp(v_infected.visitStart), timestamp(v_healthy.visitStart)])) AS Start_date_overlap,
    toFloat(apoc.coll.min([timestamp(v_infected.visitEnd), timestamp(v_healthy.visitEnd)])) AS End_date_overlap
WITH infected, healthy, l,
    CASE
        WHEN Start_date_overlap <= End_date_overlap
        THEN ROUND((End_date_overlap - Start_date_overlap) / (1000 * 60 * 60), 4)
        ELSE 0
    END AS Spreading_duration
WITH healthy.personName AS HealthyPerson,SUM (Spreading_duration) AS TotalSpreading_duration,collect ({longitude:healthy.residenceLongitude,latitude:healthy.residenceLatitude})AS Contact
RETURN HealthyPerson, ROUND(TotalSpreading_duration,1),Contact 
ORDER BY TotalSpreading_duration DESC
LIMIT 5;


// 10)  It is intended to try to reduce attendance and implement even more precautionary measures in those establishments where infected individuals have spent more time.**

// Calculate total visits by infected individuals in each establishment
MATCH(infected:Person{healthStatus:'Infected'})-[:MAKES_VISIT]->(v_infected:Visit)-[:TO_ESTABLISHMENT]->(l:Location) 
WITH COUNT(DISTINCT infected)AS Total_visits_of_infected ,l

// Calculate total visits in each establishment
MATCH(n:Person)-[:MAKES_VISIT]->(v:Visit)-[:TO_ESTABLISHMENT]->(l:Location)
WITH COUNT (DISTINCT n) AS Total_visits_in_each_establishment, l,Total_visits_of_infected 

// Calculate percentage of visits by infected individuals relative to total visits
WITH l, Total_visits_of_infected, Total_visits_in_each_establishment,(toFloat(
Total_visits_of_infected)/Total_visits_in_each_establishment * 100) AS Percentage_of_visits_by_infected
RETURN l.locationName AS Establishment,Total_visits_of_infected,Total_visits_in_each_establishment,ROUND(Percentage_of_visits_by_infected,2)
ORDER BY Percentage_of_visits_by_infected DESC;
