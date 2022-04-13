# Experiments

- [Experiments](#experiments)
  - [People in events with other people](#people-in-events-with-other-people)
    - [With roles](#with-roles)
  - [Subset of Notarial Archives: Probate Inventories](#subset-of-notarial-archives-probate-inventories)
## People in events with other people

Persons in the Gelegenheidsgedichten (GGD) data have been linked to their occurences in records from the Amsterdam City Archives. They can occur in records on Baptism, Notice of Marriage, Prenuptial Agreement, Probate Inventory, Testament, and Burial. Usually, there are other persons mentioned in the same record (e.g. the Witnesses) who have not yet been disambiguated between records. 

By using a construct query to produce a slice of all the data available in the Golden Agents infrastructure, we can distill a subset that is relevant for enriching the social networks around the actors in the Gelegenheidsgedichten data. 

Results: 
* [ggd_people_events.ttl](ggd_people_events.ttl)
* [ggd_people_events_without_child.ttl](ggd_people_events_without_child.ttl) (achieved by toggling the FILTER on the Kind role in the query)

```sparql

PREFIX schema: <http://schema.org/>
PREFIX roar: <https://data.goldenagents.org/ontology/roar/>
PREFIX pnv: <https://w3id.org/pnv#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sem: <http://semanticweb.cs.vu.nl/2009/11/sem/>
PREFIX thes: <https://data.goldenagents.org/thesaurus/>

CONSTRUCT {
    
    ?person a roar:Person ;
            rdfs:label ?literalName ;
            pnv:hasName ?personName ;
            roar:participatesIn ?event .
    
    ?personName a pnv:PersonName ;
                pnv:givenName ?givenName ;
                pnv:surnamePrefix ?surnamePrefix ;
                pnv:baseSurname ?baseSurname ;
                pnv:literalName ?literalName .
    
    ?otherPerson a roar:Person ;
                 rdfs:label ?otherPersonLiteralName  ;
                 pnv:hasName ?otherPersonName ; 
                 roar:participatesIn ?event .    
    
    ?otherPersonName a pnv:PersonName ;
                     pnv:givenName ?otherPersonGivenName ;
                     pnv:surnamePrefix ?otherPersonSurnamePrefix ;
                     pnv:baseSurname ?otherPersonBaseSurname ;
                     pnv:literalName ?otherPersonLiteralName .
    
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
 
    # There is an optional other person in a particular role in that event
    OPTIONAL {
        [] a ?roleType ;
           roar:carriedBy ?otherPerson ;
           roar:carriedIn ?event .

        # Leave out the children (that only have a pnv:GivenName) out for now
        # FILTER(?roleType != <https://data.goldenagents.org/thesaurus/Kind>)  # <-- toggle!

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
    
}

```

### With roles

Result: 
* [ggd_people_events_roles.ttl](ggd_people_events_roles.ttl)

```sparql
PREFIX schema: <http://schema.org/>
PREFIX roar: <https://data.goldenagents.org/ontology/roar/>
PREFIX pnv: <https://w3id.org/pnv#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sem: <http://semanticweb.cs.vu.nl/2009/11/sem/>
PREFIX thes: <https://data.goldenagents.org/thesaurus/>

CONSTRUCT {
    
    ?person a roar:Person ;
            rdfs:label ?literalName ;
            pnv:hasName ?personName ;
            roar:participatesIn ?event .
    
    ?personName a pnv:PersonName ;
                pnv:givenName ?givenName ;
                pnv:surnamePrefix ?surnamePrefix ;
                pnv:baseSurname ?baseSurname ;
                pnv:literalName ?literalName .
    
    ?personRole a ?personRoleType ;
                roar:carriedIn ?event ;
                roar:carriedBy ?person .
    
    ?otherPerson a roar:Person ;
                 rdfs:label ?otherPersonLiteralName  ;
                 pnv:hasName ?otherPersonName ; 
                 roar:participatesIn ?event .    
    
    ?otherPersonName a pnv:PersonName ;
                     pnv:givenName ?otherPersonGivenName ;
                     pnv:surnamePrefix ?otherPersonSurnamePrefix ;
                     pnv:baseSurname ?otherPersonBaseSurname ;
                     pnv:literalName ?otherPersonLiteralName .
    
    ?otherPersonRole a ?otherPersonRoleType ;
                roar:carriedIn ?event ;
                roar:carriedBy ?otherPerson .
    
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
    
    # That person has a particular role in that event
    ?personRole a ?personRoleType ;
       roar:carriedBy ?person ;
       roar:carriedIn ?event .
    
    # That event has a date and is of a particular type
    ?event a ?eventType ;
           sem:hasTimeStamp ?date .
 
    # There is an optional other person in a particular role in that event
    OPTIONAL {
        ?otherPersonRole a ?otherPersonRoleType ;
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
    
}
```

## Subset of Notarial Archives: Probate Inventories

Slice containing probate inventories only (N=10.424). Some of the resources in this data have been linked to the GGD.

Result: 
* [na_inventories.ttl](na_inventories.ttl)

```sparql
PREFIX schema: <http://schema.org/>
PREFIX roar: <https://data.goldenagents.org/ontology/roar/>
PREFIX pnv: <https://w3id.org/pnv#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sem: <http://semanticweb.cs.vu.nl/2009/11/sem/>
PREFIX thes: <https://data.goldenagents.org/thesaurus/>

CONSTRUCT {
    
    ?person a roar:Person ;
            rdfs:label ?literalName ;
            pnv:hasName ?personName ;
            roar:participatesIn ?event .
    
    ?personName a pnv:PersonName ;
                pnv:givenName ?givenName ;
                pnv:surnamePrefix ?surnamePrefix ;
                pnv:baseSurname ?baseSurname ;
                pnv:literalName ?literalName .
    
    ?personRole a ?personRoleType ;
                roar:carriedIn ?event ;
                roar:carriedBy ?person .
    
    ?event a ?eventType ;
           sem:hasTimeStamp ?date .
    
}

WHERE {
    
    # A person takes part in an event
    ?person a roar:Person ; 
            pnv:hasName ?personName ;
            roar:participatesIn ?event .
    
    # Has name information
    ?personName a pnv:PersonName ;
                pnv:literalName ?literalName .
    
    OPTIONAL { ?personName pnv:givenName ?givenName . }
    OPTIONAL { ?personName pnv:surnamePrefix ?surnamePrefix . }
    OPTIONAL { ?personName pnv:baseSurname ?baseSurname . }
    
    # That person has a particular role in that event
    ?personRole a ?personRoleType ;
       roar:carriedBy ?person ;
       roar:carriedIn ?event .
    
    # That event has a date and is of a particular type
    ?event a ?eventType ;
           sem:hasTimeStamp ?date .
    
    FILTER(?eventType = <https://data.goldenagents.org/thesaurus/Boedelinventaris> )
   
    
}

```
