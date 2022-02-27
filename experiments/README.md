# Experiments

```sparql

PREFIX schema: <http://schema.org/>
PREFIX roar: <https://data.goldenagents.org/ontology/roar/>
PREFIX pnv: <https://w3id.org/pnv#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sem: <http://semanticweb.cs.vu.nl/2009/11/sem/>

CONSTRUCT {
    
    ?person a roar:Person ;
            rdfs:label ?literalName ;
            pnv:hasName ?personName ;
            roar:participatesIn ?event .
    
    ?personName a pnv:PersonName ;
                pnv:givenName ?givenName ;
                pnv:surnamePrefix ?surnamePrefix ;
                pnv:baseSurname ?baseSurname .
    
    ?otherPerson a roar:Person ;
                 rdfs:label ?otherPersonLiteralName  ;
                 pnv:hasName ?otherPersonName ; 
                 roar:participatesIn ?event .    
    
    ?otherPersonName a pnv:PersonName ;
                     pnv:givenName ?otherPersonGivenName ;
                     pnv:surnamePrefix ?otherPersonSurnamePrefix ;
                     pnv:baseSurname ?otherPersonBaseSurname .
    
    ?event a ?eventType ;
           sem:hasTimeStamp ?date .
    
}

WHERE {
    
    # A person takes part in an event
    ?person a schema:Person ; # only in GGD
            pnv:hasName ?personName ;
    	    roar:participatesIn ?event .
    
    # Has name information
    ?personName a pnv:PersonName ;
                pnv:literalName ?literalName .
    
    OPTIONAL { ?personName pnv:givenName ?givenName . }
    OPTIONAL { ?personName pnv:surnamePrefix ?surnamePrefix . }
    OPTIONAL { ?personName pnv:baseSurname ?baseSurname . }
    
    # That event has a date and is of a particular type
    ?event a ?eventType ;
           sem:hasTimeStamp ?date .
 
    # There is another person in a particular role in that event
    [] a ?roleType ;
       roar:carriedBy ?otherPerson ;
       roar:carriedIn ?event .
    
    # And its not the person itself
    FILTER(?otherPerson != ?person)
    
    # This person also has a name
    ?otherPerson pnv:hasName ?otherPersonName .
    
    # Has name information
    ?otherPersonName a pnv:PersonName ;
                     pnv:literalName ?otherPersonLiteralName .
    
    OPTIONAL { ?otherPersonName pnv:givenName ?otherPersonGivenName . }
    OPTIONAL { ?otherPersonName pnv:surnamePrefix ?otherPersonSurnamePrefix . }
    OPTIONAL { ?otherPersonName pnv:baseSurname ?otherPersonBaseSurname . }
   
    
}

```