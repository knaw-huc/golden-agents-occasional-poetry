# Experiment 2

## Data

### Everything from the previous experiment

We use the same query to generate a new abstraction from the GA SAA data, this time with the newly validated (10k person entries) included. Added to this is information about the location (e.g. a Church or Graveyard) and the religions relevant to these.

All datasets:
* SAA Indices
  * Notariële Archieven 1578-1915 (3.102.264 persons)
  * Doopregisters voor 1811 (4.880.206 persons)
  * Ondertrouwregisters 1565-1811 (906.695 persons)
  * Kwijtscheldingen voor 1811 (358.689 persons)
  * Poorters 1531-1652 (21.441 persons)
  * Confessieboeken 1535-1732 (113.313 persons)
  * Boetes op begraven (4.596 persons)
  * Begraafregisters voor 1811 (1.509.132 persons)
  * Overledenen Gast-, Pest-, Werk- en Spinhuis 1739-1812 (40.109 persons)
  * Averijgrossen 1700-1810 (10.986 persons)
  * Boedelpapieren 1634-1938 (20.572 persons)
  * Lidmatenregister Doopsgezinde Gemeente (29.665 persons)
* Ja, ik wil!
* Gelegenheidsgedichten
* Linksets:
  * Links included in Gelegenheidsgedichten
  * Ja, ik wil! to SAA Ondertrouwregisters
  [`linkset_jiw_otr_20211005.trig.gz`](https://github.com/knaw-huc/golden-agents-processes-of-creativity/blob/main/linksets/linkset_jiw_otr_20211005.trig.gz)
  * 10k+ linkset from previous experiment
  [`ggd_clusters_t0.70_k10_validation.trig`](https://github.com/knaw-huc/golden-agents-occasional-poetry/blob/main/experiments/Semantics2022/results/ggd_clusters_t0.70_k10_validation.trig)

#### Query and data (ttl):
* [`ggd_people_events_roles_locations_religions.ttl`](./ggd_people_events_roles_locations_religions.ttl)

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
                roar:carriedBy ?person ;
                roar:hasReligion ?personReligion .

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
                roar:carriedBy ?otherPerson ;
                roar:hasReligion ?otherPersonReligion .

    ?event a ?eventType ;
           sem:hasTimeStamp ?date ;
           roar:hasPlace ?eventLocation ;
           roar:hasReligion ?eventReligion .

    ?eventLocation a roar:Location ;
                   roar:hasReligion ?locationReligion .
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

    # Optionally, we know the person's religion
    OPTIONAL {
        ?personRole roar:hasReligion ?religionRole .
        ?religionRole roar:carriedBy ?religionObservation .
        ?personReligion prov:wasDerivedFrom ?religionObservation .
    }

    # That event has a date and is of a particular type
    ?event a ?eventType ;
           sem:hasTimeStamp ?date .

    # There is an optional event location
    OPTIONAL {
        ?event roar:registers ?registeredEvent .

        ?registeredEvent roar:hasPlace ?eventLocation .

        # And optionally, this eventLocation has religions attached
        OPTIONAL {
            ?eventLocation roar:hasReligion ?locationReligion .
        }

        # And optionally, this event has a religion (from source)
        OPTIONAL {
            ?registeredEvent roar:hasReligion ?eventReligion .
        }

    }

    # There is an optional other person in a particular role in that event
    OPTIONAL {
        ?otherPersonRole a ?otherPersonRoleType ;
           roar:carriedBy ?otherPerson ;
           roar:carriedIn ?event .

        # Optionally, we know the person's religion
        OPTIONAL {
            ?otherPersonRole roar:hasReligion ?otherPersonReligionRole .
            ?otherPersonReligionRole roar:carriedBy ?otherPersonReligionObservation .
            ?otherPersonReligion prov:wasDerivedFrom ?otherPersonReligionObservation .
        }

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
### Notice of marriage registers (Ondertrouw)
SAA + JIW

#### Query and data (ttl):

* `ga_otrjiw_locations_religions.ttl.gz`

```sparql
PREFIX roar: <https://data.goldenagents.org/ontology/roar/>
PREFIX pnv: <https://w3id.org/pnv#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sem: <http://semanticweb.cs.vu.nl/2009/11/sem/>
PREFIX thes: <https://data.goldenagents.org/thesaurus/>
PREFIX prov: <http://www.w3.org/ns/prov#>

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
                roar:carriedBy ?person ;
                roar:hasReligion ?personReligion .

    ?event a ?eventType ;
           sem:hasTimeStamp ?date ;
           roar:hasPlace ?eventLocation ;
           roar:hasReligion ?eventReligion .

    ?eventLocation a roar:Location ;
                   roar:hasReligion ?locationReligion .

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

    # Optionally, we know the person's religion
    OPTIONAL {
        ?personRole roar:hasReligion ?religionRole .
        ?religionRole roar:carriedBy ?religionObservation .
        ?personReligion prov:wasDerivedFrom ?religionObservation .
    }

    # That event has a date and is of a particular type
    ?event a ?eventType ;
           sem:hasTimeStamp ?date .

    FILTER(?eventType = thes:Ondertrouw)

    # There is an optional event location
    OPTIONAL {
        ?event roar:registers ?registeredEvent .

        ?registeredEvent roar:hasPlace ?eventLocation .

        # And optionally, this eventLocation has religions attached
        OPTIONAL {
            ?eventLocation roar:hasReligion ?locationReligion .
        }

        # And optionally, this event has a religion (from source)
        OPTIONAL {
            ?registeredEvent roar:hasReligion ?eventReligion .
        }

    }
}
```


### Baptism registers (Doop)

#### Query and data (ttl):
* `ga_doop_locations.ttl.gz`

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
                   roar:hasReligion ?locationReligion .

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
        ?event roar:registers ?registeredEvent .

        ?registeredEvent roar:hasPlace ?eventLocation .

        # And optionally, this eventLocation has religions attached
        OPTIONAL {
            ?eventLocation roar:hasReligion ?locationReligion .
        }

        # And optionally, this event has a religion (from source)
        OPTIONAL {
            ?registeredEvent roar:hasReligion ?eventReligion .
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



### Both combined
We used GraphDB with owl:sameAs reasoning turned on (but owl:sameAs expansion turned off) to generate these files. Both queries above were generated at the same time, with the same data loaded in the GraphDB repository, and we can therefore assume that the inference of GraphDB (more info here: https://graphdb.ontotext.com/documentation/10.0/sameas-optimisation.html) gives back the same URIs for entities that were merged using a `sameAs` statement. However, we also want that our data is usable outside of this repository. Therefore, we generate a separate data file with all sameAs statements from the data, so that, regardless of which version or combination of the files one picks, the clustered data (to be generated) gives back usable URIs.

The results of the above two queries are loaded in a separate repository, together with the sameAs linkset. Then, we execute the query below to obtain an RDF file in which the two datasets are merged. If needed, the URIs can be expanded again by using the the sameAs linkset.

#### Linkset (ttl):

* Result: [`ga_sameAs.ttl`](./ga_sameAs.ttl)

```sparql
PREFIX owl: <http://www.w3.org/2002/07/owl#>
CONSTRUCT {
    ?entity1 owl:sameAs ?entity2 .
} WHERE {
	?entity1 owl:sameAs ?entity2 .
}
```
#### Query and data (ttl):

* Result: TBD

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
                roar:carriedBy ?person ;
                roar:hasReligion ?personReligion .

    ?event a ?eventType ;
           sem:hasTimeStamp ?date ;
           roar:hasPlace ?eventLocation ;
           roar:hasReligion ?eventReligion .

    ?eventLocation a roar:Location ;
                   roar:hasReligion ?locationReligion .

}

WHERE {

    ?person a roar:Person ;
            rdfs:label ?literalName ;
            pnv:hasName ?personName ;
            roar:participatesIn ?event .

    ?personName a pnv:PersonName ;
                pnv:literalName ?literalName .

    OPTIONAL { ?personName pnv:givenName ?givenName . }
    OPTIONAL { ?personName pnv:surnamePrefix ?surnamePrefix . }
    OPTIONAL { ?personName pnv:baseSurname ?baseSurname . }

    ?personRole a ?personRoleType ;
                roar:carriedIn ?event ;
                roar:carriedBy ?person .

    OPTIONAL {
        ?personRole roar:hasReligion ?personReligion .

    ?event a ?eventType ;
           sem:hasTimeStamp ?date ;

    OPTIONAL {
        ?event roar:hasPlace ?eventLocation .

        OPTIONAL {
            ?eventLocation roar:hasReligion ?locationReligion .
        }

        OPTIONAL {
            ?event roar:hasReligion ?eventReligion .
        }
    }
}
```
