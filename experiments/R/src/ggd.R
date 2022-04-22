source('src/create-linkset.R')
library(data.table)

query.violation.data <- list(
  endpoint = 'http://localhost:5820/ggd/query',
  prefixes = list(
    'roar: <https://data.goldenagents.org/ontology/roar/>',
    'rdfs: <http://www.w3.org/2000/01/rdf-schema#>',
    'sem: <http://semanticweb.cs.vu.nl/2009/11/sem/>',
    'thes: <https://data.goldenagents.org/thesaurus/>'
  ),
  types = list('roar:Person', 'roar:Person'),
  rules = list(
    
    list(
      triples1 = list(
        list(pred = 'roar:participatesIn', object = '?event1')
      ),
      triples2 = list(
        list(pred = 'roar:participatesIn', object = '?event2')
      ),
      rule = '?event1 = ?event2',
      supreme = TRUE
    ),
    list(
      triples1 = list(
        list(pred = 'roar:participatesIn', object = '?event1'),
        list(subject = '?role1', pred = 'roar:carriedIn', object = '?event1'),
        list(subject = '?role1', pred = 'roar:carriedBy'),
        list(subject = '?role1', pred = 'a', object = '?role1Type'),
        list(subject = '?event1', pred = 'a', object = '?eventType1')
      ),
      triples2 = list(
        list(pred = 'roar:participatesIn', object = '?event2'),
        list(subject = '?role2', pred = 'roar:carriedIn', object = '?event2'),
        list(subject = '?role2', pred = 'roar:carriedBy'),
        list(subject = '?role2', pred = 'a', object = '?role2Type'),
        list(subject = '?event2', pred = 'a', object = '?eventType2')
      ),
      rule = '(?eventType1 = thes:Doop && ?role1Type = thes:Kind && ?role1Type = ?role2Type) || (?eventType2 = thes:Doop && ?role2Type = thes:Kind && ?role1Type = ?role2Type)',
      supreme = TRUE
    ),
    list(
      triples1 = list(
        list(pred = 'roar:participatesIn', object = '?event1'),
        list(subject = '?role1', pred = 'roar:carriedIn', object = '?event1'),
        list(subject = '?role1', pred = 'roar:carriedBy'),
        list(subject = '?role1', pred = 'a', object = '?role1Type'),
        list(subject = '?event1', pred = 'sem:hasTimeStamp', object = '?date1'),
        list(subject = '?event1', pred = 'a', object = '?eventType1')
      ),
      triples2 = list(
        list(pred = 'roar:participatesIn', object = '?event2'),
        list(subject = '?role2', pred = 'roar:carriedIn', object = '?event2'),
        list(subject = '?role2', pred = 'roar:carriedBy'),
        list(subject = '?role2', pred = 'a', object = '?role2Type'),
        list(subject = '?event2', pred = 'sem:hasTimeStamp', object = '?date2'),
        list(subject = '?event2', pred = 'a', object = '?eventType2')
      ),
      rule = '(?eventType1 = thes:Doop && ?role1Type = thes:Kind && YEAR(?date1) > YEAR(?date2)) || (?eventType2 = thes:Doop && ?role2Type = thes:Kind && YEAR(?date2) > YEAR(?date1))',
      supreme = TRUE
    )
  )
)

cluster.options <- list(
  theta = 0.7,
  epsilon = 1e-6, 
  k = 10,
  max.size.cluster.edit = 50,
  n_trees = 1000,
  normalize = T
)

query.options <- list(
  penalty = 1e6,
  max.query.size = 10000,
  batch.size = 100,
  max.cluster.size = 100,
  post = T
)


ggd.results <- perform.tests( dataset = 'ggd_embedding', cluster.options, query.options, query.violation.data)

fwrite(ggd.results, file = paste0('ggd_otr_doop_clusters_t', cluster.options$theta, '_k', cluster.options$k ,'.tsv'), sep = '\t')





