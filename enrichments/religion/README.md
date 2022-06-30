# Religion

All combinations of appearances of religion and church(yards) as mentioned in the Baptism and Burial indexes of the Amsterdam City Archives were requested via the following query. The purpose is to create a mapping for religion that enables us to trace possible clustering in the network of people we found involved in occasional poetry and that might serve as next step in community detection.

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

The results of this query are now curated on a basic level, which means that different locations that occured in one decription (for example 'Noorderkerk en Kerkhof') are seperated in different entities ('Noorderkerk', 'Noorderkerkhof'), all location names are standardized and are categorized with a type. Relgions and if possible also locations have URI's to Adamlink and Wikidata, although a lot of clandestine churches aren't findable on Adamlink and Wikidata (see: 'Aanvullingen_Kerken_Adamlink.csv'
