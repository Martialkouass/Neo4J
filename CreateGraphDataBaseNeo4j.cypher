## Create Graph Data Base Neo4j

// Create constraints
CREATE CONSTRAINT Person_personId IF NOT EXISTS
FOR (x:Person)
REQUIRE x.personId IS UNIQUE;
 
CREATE CONSTRAINT Location_LocationId IF NOT EXISTS
FOR (x:Location)
REQUIRE x.locationId IS UNIQUE;
 
CREATE CONSTRAINT Visit_VisitId IF NOT EXISTS
FOR (x:Visit)
REQUIRE x.visitId IS UNIQUE;
 
// Load Person Nodes
LOAD CSV WITH HEADERS FROM 'file:///person_nodes.csv' AS row
MERGE (p:Person {personId: toInteger(row.person_id)})
SET
p.personName = row.person_name,
p.healthStatus = row.health_status,
p.testResultTime = row.test_result_time,
p.residenceLatitude = row.residence_latitude,
p.residenceLongitude = row.residence_longitude;
 
// Load Location Nodes
LOAD CSV WITH HEADERS FROM 'file:///location_nodes.csv' AS row
MERGE (l:Location {locationId: toInteger(row.location_id)})
SET
l.locationName = row.location_name,
l.locationType = row.location_type;
 
// Load Visit Nodes
LOAD CSV WITH HEADERS FROM 'file:///visit_nodes.csv' AS row
MERGE (v:Visit {visitId: toInteger(row.visit_id)})
SET
v.personId = toInteger(row.person_id),
v.locationId = toInteger(row.location_id),
v.visitStart = row.visit_start,
v.visitEnd = row.visit_end;
 
// Relationship VISITS_LOCATION (between Person and Location)
LOAD CSV WITH HEADERS
FROM 'file:///visit_nodes.csv' AS row
MATCH (p:Person {personId: toInteger(row.person_id)})
MATCH (l:Location {locationId: toInteger(row.location_id)})
MERGE (p)-[r:VISITS_LOCATION]->(l)
SET r.visitStart = row.visit_start,
r.visitEnd = row.visit_end;
 
// Relationship MAKES_VISIT (between Person and Visit)
LOAD CSV WITH HEADERS
FROM 'file:///visit_nodes.csv' AS row
MATCH (p:Person {personId: toInteger(row.person_id)})
MATCH (v:Visit {visitId: toInteger(row.visit_id)})
MERGE (p)-[r:MAKES_VISIT]->(v)
SET r.visitStart = row.visit_start,
r.visitEnd = row.visit_end;
 
// Relationship TO_ESTABLISHMENT (between Visit and Location)
LOAD CSV WITH HEADERS
FROM 'file:///visit_nodes.csv' AS row
MATCH (v:Visit {visitId: toInteger(row.visit_id)})
MATCH (l:Location {locationId: toInteger(row.location_id)})
MERGE (v)-[r:TO_ESTABLISHMENT]->(l);
