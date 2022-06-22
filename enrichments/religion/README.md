# Religion



## Query

Datasets: DTB

```sparql
PREFIX roar: <https://data.goldenagents.org/ontology/roar/>
PREFIX sem: <http://semanticweb.cs.vu.nl/2009/11/sem/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT (COUNT(?registrationEvent) AS ?c) ?location ?religion WHERE { 
	?registrationEvent a ?eventType ;
        roar:registers ?event .
    
    ?event roar:occursAt ?location ;
           sem:hasTimeStamp ?date .
    
#    ?location rdfs:label ?locationLabel .
    
    OPTIONAL {
        ?event roar:hasReligion ?religion . 
    
#        ?religion rdfs:label ?religionLabel. 
    }
} GROUP BY ?location ?religion ORDER BY DESC(?c)
```

Results: [`location-religion-count.csv`](location-religion-count.csv)