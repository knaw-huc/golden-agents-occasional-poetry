# Experiment 2

## Data

### Everything from the previous experiment

We use the same query to generate a new abstraction from the GA SAA data, this time with the newly validated (10k person entries) included. Added to this is information about the location (e.g. a Church or Graveyard) and the religions relevant to these. 

All datasets:
* SAA Indices
  * Notariële Archieven 1578-1915
  * Doopregisters voor 1811
  * Ondertrouwregisters 1565-1811
  * Kwijtscheldingen voor 1811
  * Poorters 1531-1652
  * Confessieboeken 1535-1732
  * Boetes op begraven
  * Begraafregisters voor 1811
  * Overledenen Gast-, Pest-, Werk- en Spinhuis 1739-1812
  * Averijgrossen 1700-1810
  * Boedelpapieren 1634-1938
  * Lidmatenregister Doopsgezinde Gemeente
* Ja, ik wil!
* Gelegenheidsgedichten
* Linksets:
  * Links included in Gelegenheidsgedichten
  * Ja, ik wil! to SAA Ondertrouwregisters
  [`linkset_jiw_otr_20211005.trig.gz`](https://github.com/knaw-huc/golden-agents-processes-of-creativity/blob/main/linksets/linkset_jiw_otr_20211005.trig.gz)
  * 10k+ linkset from previous experiment
  [`ggd_clusters_t0.70_k10_validation.trig`](https://github.com/knaw-huc/golden-agents-occasional-poetry/blob/main/experiments/Semantics2022/results/ggd_clusters_t0.70_k10_validation.trig)

#### Query and data (ttl):
* TBD

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
           sem:hasTimeStamp ?date ;
           roar:hasPlace ?eventLocation ;
           roar:hasReligion ?eventReligion .
    
    ?eventLocation a roar:Location ;
                   roar:hasReligion ?eventLocationReligion .    
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
 
    # There is an optional event location
    OPTIONAL {
        ?event roar:hasPlace ?eventLocation .
        
        # And optionally, this eventLocation has religions attached
        OPTIONAL {
            ?eventLocation roar:hasReligion ?locationReligion .
        }
        
        # And optionally, this event has a religion (from source)
        OPTIONAL {
            ?event roar:hasReligion ?eventReligion .
        }
        
    }
    
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

### Baptism registers (Doop)

#### Query and data (ttl):
* TBD

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
           sem:hasTimeStamp ?date ;
           roar:hasPlace ?eventLocation ;
           roar:hasReligion ?eventReligion .
    
    ?eventLocation a roar:Location ;
                   roar:hasReligion ?eventLocationReligion .    
   
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
   
    FILTER(?eventType = thes:Doop)
 
    # There is an optional event location
    OPTIONAL {
        ?event roar:hasPlace ?eventLocation .
        
        # And optionally, this eventLocation has religions attached
        OPTIONAL {
            ?eventLocation roar:hasReligion ?locationReligion .
        }
        
        # And optionally, this event has a religion (from source)
        OPTIONAL {
            ?event roar:hasReligion ?eventReligion .
        }
        
    }
 
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
