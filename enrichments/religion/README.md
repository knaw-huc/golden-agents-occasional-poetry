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

The results of this query are now curated on a basic level (see: 'Religie_Kerken_DTB.csv') , which means that different locations that occured in one decription (for example 'Noorderkerk en Kerkhof') are seperated into different entities ('Noorderkerk', 'Noorderkerkhof'), all location names are standardized and are categorized with a type. Religions and if possible also locations have URI's to Adamlink and Wikidata. Churches that were not yet in Adamlink have been entered.

Please notify the following issues:
- Although religion and church coincide most of the time (in a Walloon or a Lutheran church one might expect only Walloon and Lutheran Baptisms for instance) this is not always the case. It is likely to also find Roman Catholic burials in the Dutch Reformed churches such as the Nieuwe Kerk and the Oude Kerk also after the 'Alteratie' of 1578. The same applies for Lutherans and Walloons, who also might be found in the indexes of the large Dutch Reformed churches.
- For now, time isn't included in the matching between churches and religion. This might be a future idea when we want to distinct the transfer of a certain religion in a single church(building). For example the shift from Roman Catholic towards Dutch Reformed in 1578 or the shift from Roman Catholic towards Old Catholic in the early 1700s. In the case of the administration of the 'Lutherse Kerk' not a single Lutheran church was linked since the periode coincided with 4 (!) Lutheran churches that were present in Amsterdam during the time the administration was kept. Untill the erection of the Nieuwe Lutherse Kerk it is however quite clear in what buildings the Lutherans went to church. When we work with time as a label it might be possible adding these nuances.
- It has turned out that in the case of the Walloons that where administred at the Westerkerk all these records were matched correctly. This variation in administration seems to be quite unique.
