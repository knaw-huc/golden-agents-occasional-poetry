source('src/create-linkset.R')

load.saa.ground.truth <- function() {
  truth <- fread('data/saa-truth.tsv',  header = T, sep = '\t', blank.lines.skip = T, quote = '#')
  truth <- truth[!is.na(truth$ILN_GROUP)]
  truth[,uri:=as.factor(paste0(DATASET, RESOURCE_URI))]
  truth[,cluster:=as.integer(as.factor(paste0(as.integer(as.factor(CLUSTER_ID)), ILN_GROUP)))]
  setkey(truth, uri)
  return(truth[,list(uri,cluster)])
}

performance <- function(labels1, labels2, calc.fsc = T, calc.ami = F, calc.ari = F, calc.nmi = F) {
  
  if(!any(c(calc.fsc, calc.ami, calc.ari, calc.nmi))) {
    stop('No performance measure set')
  }
  
  out <- list()
  
  if(calc.fsc) {
    
    comembership <- comembershipTable(labels1, labels2)
    precision <- comembership[1,1] / (comembership[1,1] + comembership[1,2])
    recall <- comembership[1,1] / (comembership[1,1] + comembership[2,1])
    
    out$prc <- precision
    out$rec <- recall
    out$f10 <- 2 * ((precision * recall) / (precision + recall))
    out$f05 <- (1 + 0.5^2) * ((precision * recall) / ((0.5^2 * precision) + recall))
  }
  
  if(calc.ari) out$ari <- aricode::ARI(labels1, labels2)
  if(calc.ami) out$ami <- aricode::AMI(labels1, labels2)
  if(calc.nmi) out$nmi <- aricode::NMI(labels1, labels2)
  
  return(out)
  
}

prob.rules <-
  list(
    list(
      triples1 = list(
        list(pred = 'saa:birth_date_approx', object = '?birthDate1', optional = T),
        list(pred = 'saa:isInRecord', object = '?event1'),
        list(subject = '?event1', pred = 'saa:date_approx', object = '?eventDate1'),
        list(subject = '?event1', pred = 'a', object = '?eventType1'),
        list(subject = '?event1', pred = '?role1', object = '?e1', optional = T)
      ),
      triples2 = list(
        list(pred = 'saa:birth_date_approx', object = '?birthDate2', optional = T),
        list(pred = 'saa:isInRecord', object = '?event2'),
        list(subject = '?event2', pred = 'saa:date_approx', object = '?eventDate2'),
        list(subject = '?event2', pred = 'a', object = '?eventType2'),
        list(subject = '?event2', pred = '?role2', object = '?e2', optional = T)
      ),
      rule = paste( sep = ' || ',
        '(?role1 IN (saa:mentionsGroom, saa:mentionsBride) && ?eventType1 = saa:Ondertrouw && ?eventType2 IN (saa:Trouw, saa:Doop) && ABS(YEAR(?eventDate1) - YEAR(?eventDate2))>30)',
        '(?role2 IN (saa:mentionsGroom, saa:mentionsBride) && ?eventType2 = saa:Ondertrouw && ?eventType1 IN (saa:Trouw, saa:Doop) && ABS(YEAR(?eventDate2) - YEAR(?eventDate1))>30)'
      ),
      prob = 0.95
    ),
    list(
      triples1 = list(
        list(pred = 'saa:birth_date_approx', object = '?birthDate1', optional = T),
        list(pred = 'saa:isInRecord', object = '?event1'),
        list(subject = '?event1', pred = 'saa:date_approx', object = '?eventDate1'),
        list(subject = '?event1', pred = 'a', object = '?eventType1'),
        list(subject = '?event1', pred = '?role1', object = '?e1', optional = T)
      ),
      triples2 = list(
        list(pred = 'saa:birth_date_approx', object = '?birthDate2', optional = T),
        list(pred = 'saa:isInRecord', object = '?event2'),
        list(subject = '?event2', pred = 'saa:date_approx', object = '?eventDate2'),
        list(subject = '?event2', pred = 'a', object = '?eventType2'),
        list(subject = '?event2', pred = '?role2', object = '?e2', optional = T)
      ),
      rule = paste( sep = ' || ',
        '(?role1 IN (saa:mentionsGroom, saa:mentionsBride) && YEAR(?eventDate1) - YEAR(?birthDate2) < 17)',
        '(?role1 IN (saa:mentionsGroom, saa:mentionsBride) && YEAR(?eventDate1) - YEAR(?birthDate2) > 60)',
        '(?role2 IN (saa:mentionsGroom, saa:mentionsBride) && YEAR(?eventDate2) - YEAR(?birthDate1) < 17)',
        '(?role2 IN (saa:mentionsGroom, saa:mentionsBride) && YEAR(?eventDate2) - YEAR(?birthDate1) > 60)'
      ),
      prob = 0.5
    ),
    list(
      triples1 = list(
        list(pred = 'saa:death_date_approx', object = '?deathDate1', optional = T),
        list(pred = 'saa:isInRecord', object = '?event1'),
        list(subject = '?event1', pred = 'saa:date_approx', object = '?eventDate1'),
        list(subject = '?event1', pred = 'a', object = '?eventType1')
      ),
      triples2 = list(
        list(pred = 'saa:death_date_approx', object = '?deathDate2', optional = T),
        list(pred = 'saa:isInRecord', object = '?event2'),
        list(subject = '?event2', pred = 'saa:date_approx', object = '?eventDate2'),
        list(subject = '?event2', pred = 'a', object = '?eventType2')
      ),
      rule = paste( sep = ' || ',
        '(?eventType1 IN (saa:Ondertrouw, saa:Trouw, saa:Doop) && YEAR(?eventDate1) - YEAR(?deathDate2) > 3)', 
        '(?eventType2 IN (saa:Ondertrouw, saa:Trouw, saa:Doop) && YEAR(?eventDate2) - YEAR(?deathDate1) > 3)'
      ),
      prob = 0.5
    ),
    # list(
    #   triples1 = list(
    #     list(pred = 'saa:death_date_approx', object = '?birthDate1', optional = T),
    #     list(pred = 'saa:isInRecord', object = '?event1'),
    #     list(subject = '?event1', pred = 'saa:date_approx', object = '?eventDate1'),
    #     list(subject = '?event1', pred = 'a', object = '?eventType1')
    #   ),
    #   triples2 = list(
    #     list(pred = 'saa:death_date_approx', object = '?birthDate2', optional = T),
    #     list(pred = 'saa:isInRecord', object = '?event2'),
    #     list(subject = '?event2', pred = 'saa:date_approx', object = '?eventDate2'),
    #     list(subject = '?event2', pred = 'a', object = '?eventType2')
    #   ),
    #   rule = paste( sep = ' || ',
    #     '(?eventType1 IN (saa:Ondertrouw, saa:Trouw, saa:Doop) && YEAR(?eventDate1) - YEAR(?birthDate2) > 60)',
    #     '(?eventType2 IN (saa:Ondertrouw, saa:Trouw, saa:Doop) && YEAR(?eventDate2) - YEAR(?birthDate1) > 60)'
    #   ),
    #   prob = 0.5
    # ),
    list(
      triples1 = list(
        list(pred = 'saa:birth_date_approx', object = '?birthDate1', optional = T),
        list(pred = 'saa:isInRecord', object = '?event1'),
        list(subject = '?event1', pred = 'saa:date_approx', object = '?eventDate1'),
        list(subject = '?event1', pred = 'a', object = '?eventType1')
      ),
      triples2 = list(
        list(pred = 'saa:birth_date_approx', object = '?birthDate2', optional = T),
        list(pred = 'saa:isInRecord', object = '?event2'),
        list(subject = '?event2', pred = 'saa:date_approx', object = '?eventDate2'),
        list(subject = '?event2', pred = 'a', object = '?eventType2')
      ),
      rule = paste( sep = ' || ',
        '(?eventType1 IN (saa:Trouw, saa:Doop) && YEAR(?eventDate1) - YEAR(?birthDate2) < 17)',
        '(?eventType2 IN (saa:Trouw, saa:Doop) && YEAR(?eventDate2) - YEAR(?birthDate1) < 17)',
        '(?eventType1 IN (saa:Trouw, saa:Doop) && YEAR(?eventDate1) - YEAR(?birthDate2) > 60)',
        '(?eventType2 IN (saa:Trouw, saa:Doop) && YEAR(?eventDate2) - YEAR(?birthDate1) > 60)'
      ),
      prob = 0.25
    ),
    list(
      triples1 = list(
        list(pred = 'saa:birth_date_approx', object = '?birthDate1', optional = T),
        list(pred = 'saa:death_date_approx', object = '?deathDate1', optional = T),
        list(pred = 'saa:isInRecord', object = '?event1'),
        list(subject = '?event1', pred = 'saa:date_approx', object = '?eventDate1'),
        list(subject = '?event1', pred = 'a', object = '?eventType1')
      ),
      triples2 = list(
        list(pred = 'saa:birth_date_approx', object = '?birthDate2', optional = T),
        list(pred = 'saa:death_date_approx', object = '?deathDate2', optional = T),
        list(pred = 'saa:isInRecord', object = '?event2'),
        list(subject = '?event2', pred = 'saa:date_approx', object = '?eventDate2'),
        list(subject = '?event2', pred = 'a', object = '?eventType2')
      ),
      rule = paste( sep = ' || ',
        #'(?eventType1 = saa:Begraaf && YEAR(?eventDate1) != YEAR(?deathDate2))',
        #'(?eventType2 = saa:Begraaf && YEAR(?eventDate2) != YEAR(?deathDate1))',
        '(?eventType1 = saa:Begraaf && YEAR(?eventDate1) - YEAR(?birthDate2)) > 90',  
        '(?eventType2 = saa:Begraaf && YEAR(?eventDate2) - YEAR(?birthDate1)) > 90',
        '(?eventType1 = saa:Begraaf && YEAR(?eventDate1) < YEAR(?birthDate2))', 
        '(?eventType2 = saa:Begraaf && YEAR(?eventDate2) < YEAR(?birthDate1))'
      ),
      prob = 0.95
    ),
    list(
      triples1 = list(
        list(pred = 'saa:death_date_approx', object = '?deathDate1', optional = T),
        list(pred = 'saa:birth_date_approx', object = '?birthDate1', optional = T)
      ),
      triples2 = list(
        list(pred = 'saa:death_date_approx', object = '?deathDate2', optional = T),
        list(pred = 'saa:birth_date_approx', object = '?birthDate2', optional = T)
      ),
      rule = '(YEAR(?deathDate1) > YEAR(?birthDate2)) || (YEAR(?deathDate2) > YEAR(?birthDate1))',
      prob = 0.95
    )
  )

supreme.rules <- 
  list(
    list(
      triples1 = list(
        list(pred = 'saa:isInRecord', object = '?event1')
      ),
      triples2 = list(
        list(pred = 'saa:isInRecord', object = '?event2')
      ),
      rule = '?event1 = ?event2',
      supreme = TRUE
    ),
    list(
      rule = '(STRSTARTS(STR(?e1), "http://www.vondel.humanities.uva.nl/ecartico") && STRSTARTS(STR(?e2), "http://www.vondel.humanities.uva.nl/ecartico"))',
      supreme = TRUE
    )
  )


query.violation.data.no.rules <- list(
  rules = list()
)

query.violation.data.only.supreme <- list(
  endpoint = 'http://localhost:5820/saa/query',
  prefixes = list(
    'saa: <http://goldenagents.org/uva/SAA/ontology/>'
  ),
  types = list('saa:Person', 'saa:Person'),
  rules = supreme.rules
)

query.violation.data.only.prob <- list(
  endpoint = 'http://localhost:5820/saa/query',
  prefixes = list(
    'saa: <http://goldenagents.org/uva/SAA/ontology/>'
  ),
  types = list('saa:Person', 'saa:Person'),
  rules = prob.rules
)

query.violation.data.all.rules <- list(
  endpoint = 'http://localhost:5820/saa/query',
  prefixes = list(
    'saa: <http://goldenagents.org/uva/SAA/ontology/>'
  ),
  types = list('saa:Person', 'saa:Person'),
  rules = c(supreme.rules, prob.rules)
)

cluster.options <- list(
  theta = 0.65,
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


ground.truth <- load.saa.ground.truth()
thetas <- c(0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95)

performances.no.rules <- t(sapply(thetas, function(theta) {
  
  cluster.options$theta <- theta
  
  results <- perform.tests(dataset = 'saa_embedding', cluster.options, query.options, query.violation.data.no.rules)
  results.merged <- merge(results, ground.truth, by = 'uri', all.y = T)
  
  max.id <- max(results.merged$cluster_id, na.rm = T)
  missing <- is.na(results.merged$cluster_id)
  
  filler <- (max.id + 1) : (max.id + sum(missing))
  results.merged$cluster_id[missing] <- filler
  
  c(theta, performance(results.merged$cluster_id, results.merged$cluster))
}))

performances.supreme <- t(sapply(thetas, function(theta) {
  
  cluster.options$theta <- theta
  
  results <- perform.tests(dataset = 'saa_embedding', cluster.options, query.options, query.violation.data.only.supreme)
  results.merged <- merge(results, ground.truth, by = 'uri', all.y = T)
  
  max.id <- max(results.merged$cluster_id, na.rm = T)
  missing <- is.na(results.merged$cluster_id)
  
  filler <- (max.id + 1) : (max.id + sum(missing))
  results.merged$cluster_id[missing] <- filler
  
  c(theta, performance(results.merged$cluster_id, results.merged$cluster))
}))

performances.prob <- t(sapply(thetas, function(theta) {
  
  cluster.options$theta <- theta
  
  results <- perform.tests(dataset = 'saa_embedding', cluster.options, query.options, query.violation.data.only.prob)
  results.merged <- merge(results, ground.truth, by = 'uri', all.y = T)
  
  max.id <- max(results.merged$cluster_id, na.rm = T)
  missing <- is.na(results.merged$cluster_id)
  
  filler <- (max.id + 1) : (max.id + sum(missing))
  results.merged$cluster_id[missing] <- filler
  
  c(theta, performance(results.merged$cluster_id, results.merged$cluster))
}))


performances.all.rules <- t(sapply(thetas, function(theta) {
  
  cluster.options$theta <- theta
  
  results <- perform.tests(dataset = 'saa_embedding', cluster.options, query.options, query.violation.data.all.rules)
  results.merged <- merge(results, ground.truth, by = 'uri', all.y = T)
  
  max.id <- max(results.merged$cluster_id, na.rm = T)
  missing <- is.na(results.merged$cluster_id)
  
  filler <- (max.id + 1) : (max.id + sum(missing))
  results.merged$cluster_id[missing] <- filler
  
  c(theta, performance(results.merged$cluster_id, results.merged$cluster))
}))







