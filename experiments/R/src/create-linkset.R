


install.dependencies <- function() {
  list.of.packages.cran <- c('data.table', 'lpSolve', 'Matrix', 'pbapply', 'Rcpp', 'RcppGSL', 'RcppZiggurat', 'RcppArmadillo', 'RcppAnnoy', 'tictoc', 'SPARQL')
  new.packages.cran <- list.of.packages.cran[!(list.of.packages.cran %in% installed.packages()[,'Package'])]
  if(length(new.packages.cran)) install.packages(new.packages.cran)
}

embedding.load.glove <- function(dataset) {
  output <- list()
  
  data <- fread(file = paste0('data/', dataset, '.tsv'), header = F, sep = '\t')
  data[,V1:=as.factor(V1)]
  output$dict <- data[,V1]
  output$vect <- t(as.matrix(data[,2:ncol(data)]))
  
  return(output)
}

editClustering <- function(compIndex, penalties, vect, dict, theta, epsilon, max.in.size) {
  
  # A component of size 1 means an entity that is matched with nothing else
  if(length(compIndex) == 1) { return(compIndex) }
  # We cannot handle problems that are too large
  if(length(compIndex) > max.in.size) { return(voteClustering(compIndex, penalties, vect, theta, epsilon)) }
  
  if(length(compIndex) == 2) {
    if(adjustedWeight(compIndex, vect, theta, epsilon, penalties) > 0) {
      return(c(compIndex[1], compIndex[1]))
    } else {
      return(compIndex)
    }
  }
  
  # print(paste('cluster edit on component of size', length(compIndex)))
  
  n <- length(compIndex) # The number of vertexes
  #e <- n*(n-1)/2 # The number of edges
  b <- round((1/6) * (n - 2) * (n - 1) * n) # The number of triangles
  c <- 3 * b # The number of constraints
  
  edge.triangles <- getallTriangles(n)
  
  # Create a matrix of coordinates of all coefficients we need to set to some non-zero value (first 2 columns)
  # plus a column of values
  f.con <- matrix(
    data = c(
      rep(1:b, times = 3, each = 3) + rep((0:2) * b, each = c), 
      rep(c(edge.triangles), times = 3),
      c(rep(c(1,1,-1),b), rep(c(1,-1,1),b), rep(c(-1,1,1),b))
    ), 
    ncol = 3
  )
  
  # Set inequality/equality signs
  f.dir <- rep('<=', c)
  
  # Set right hand side coefficients
  f.rhs <- rep(1, c)
  
  # Set coefficients of the objective function
  f.obj <- adjustedWeight(compIndex, vect, theta, epsilon, penalties)
  
  # Perform the integer linear programming operation
  ILP <- lp(
    direction = 'max', 
    objective.in = f.obj, 
    dense.const = f.con, 
    const.dir = f.dir, 
    const.rhs = f.rhs, 
    all.bin = TRUE
  )
  
  
  return(extractSolution(compIndex, ILP$solution))
}

load.annoy.index <- function(annoy.file, dim) {
  a <- new(AnnoyEuclidean, dim)
  a$load(annoy.file)
  return(a)
}

build.annoy.index <- function(annoy.file, embedding, n_trees) {
  total.nr.entities <- length(embedding$dict)
  dim <- nrow(embedding$vect)
  
  a <- new(AnnoyEuclidean, dim)
  
  for (i in 1:total.nr.entities) a$addItem(i - 1, embedding$vect[,i])
  
  a$build(n_trees)
  a$save(annoy.file)
  
  return(a)
}

prune.candidate.pairs <- function(pairs, dict, query.violation.data, query.options, rule.supremacy) {
  
  nSupremeRules <- sum(rule.supremacy)
  nPairs <- nrow(pairs)
  currentPair <- 0L
  
  pb <- txtProgressBar(min = 0,      # Minimum value of the progress bar
                       max = nPairs, # Maximum value of the progress bar
                       style = 3,    # Progress bar style (also available style = 1 and style = 2)
                       width = 50,   # Progress bar width. Defaults to getOption("width")
                       char = "=")   # Character used to create the bar
  
  query.base <- constructBatchQueryBase(query.violation.data, onlySupreme = TRUE)
  
  pruned.pairs <- c()
  
  while(currentPair < nPairs) {
    
    query.info <- constructPruneQuery(pairs$key1.index, pairs$key2.index, dict, query.base, query.options$max.query.size, currentPair)
    
    post.results <- httr::POST(
      url = query.violation.data$endpoint,
      httr::add_headers(Accept = 'text/csv', Authorization = 'Basic YWRtaW46YWRtaW4='),
      body = list(query = query.info$query, infer = 'false'),
      encode = 'form'
    )
    query.results <- fread(rawToChar(post.results$content))
    rm(post.results)
    
    pruned.pairs <- c(pruned.pairs, apply(matrix(data = query.results[,.(v = apply(.SD,2,any,na.rm = T)),by=.(c,e1,e2)]$v, ncol = nSupremeRules, byrow = T), 1, any))
 
    currentPair <- currentPair + query.info$processedPairs
    setTxtProgressBar(pb, currentPair)
  }
  
  
  
  close(pb)
  print(paste('Pruned', sum(pruned.pairs), 'candidate pairs'))
  return(pairs[!pruned.pairs])
}

perform.batch.query <- function(components, dict, query.violation.data, query.options, rule.weights, rule.supremacy) {
  
  nRules <- length(query.violation.data$rules)
  nComponents <- length(components);
  currentComponent <- 0L
  currentPair <- 0L

  processed.pairs <- 0L
  total.nr.pairs <- totalPairs(components)
  query.base <- constructBatchQueryBase(query.violation.data, onlySupreme = FALSE)
  
  pb <- txtProgressBar(min = 0,      # Minimum value of the progress bar
                       max = total.nr.pairs, # Maximum value of the progress bar
                       style = 3,    # Progress bar style (also available style = 1 and style = 2)
                       width = 50,   # Progress bar width. Defaults to getOption("width")
                       char = "=")   # Character used to create the bar
  
  penalties <- list()
  
  while(currentComponent < nComponents) {
    
    #print(paste('Starting at component', currentComponent, 'of', nComponents, '(size =' , length(components[[currentComponent + 1]]), ')'))
    
    query.info <- constructBatchQuery(components, dict, query.base, query.options$max.query.size, currentComponent, currentPair)
    processed.pairs <- processed.pairs + query.info$processedPairs
    
    post.results <- httr::POST(
      url = query.violation.data$endpoint,
      httr::add_headers(Accept = 'text/csv', Authorization = 'Basic YWRtaW46YWRtaW4='),
      body = list(query = query.info$query, infer = 'false'),
      encode = 'form'
    )
    query.results <- fread(rawToChar(post.results$content))
    rm(post.results)
    
    penalty.new <- lapply(split(query.results, by = 'c'), function(x){
      
      # Make sure that we remove any duplicates and preserve rule violations
      temp <- matrix(data = x[,.(v = apply(.SD,2,any,na.rm = T)),by=.(c,e1,e2)]$v, ncol = nRules, byrow = T)
      
      # Calculate the associated costs for violating pairs
      violationsToPenalties(temp, rule.weights, rule.supremacy, query.options$penalty)
    })
    
    penalties <- mergeLists(penalties, penalty.new, nComponents, currentComponent)
    currentComponent <- query.info$currentComponent
    currentPair <- query.info$currentPair
    setTxtProgressBar(pb, processed.pairs)
  }
  
  close(pb)
  
  return(unname(penalties))
}

perform.tests <- function(
  dataset, 
  cluster.options,
  query.options,
  query.violation.data) {
  
  install.dependencies()
  
  require(data.table)
  require(lpSolve)
  require(Matrix)
  require(pbapply)
  require(Rcpp)
  require(RcppZiggurat)
  require(RcppArmadillo)
  require(RcppAnnoy)
  require(parallel)
  require(tictoc)
  require(SPARQL)
  
  pbo = pboptions(type="txt")
  Rcpp::sourceCpp('src/CPP-functions.cpp')
  
  tryCatch ({
    
    embedding <- embedding.load.glove(dataset)
    total.nr.entities <- length(embedding$dict)
    dim <- nrow(embedding$vect)
    
    if(cluster.options$normalize) {
      embedding$vect <- normalize(embedding$vect)
    }
    
    annoy.file <- paste0('data/', dataset, '.annoy')
    
    if(file.exists(annoy.file)) {
      print('Loading precomputed annoy index')
      annoy <- load.annoy.index(annoy.file, dim)
    } else {
      print('Computing new annoy index')
      annoy <- build.annoy.index(annoy.file, embedding, cluster.options$n_trees)
    }
    
    
    print('Computing nearest neighbors...')
    tic()
    # NB key2.index is zero indexed
    key2.index <- c(t(sapply(0:(total.nr.entities - 1), function(i){annoy$getNNsByItem(i, cluster.options$k+1)}))[,2:(cluster.options$k+1), drop = F])
    toc()
    annoy$unload()
    
    # NB key1.index is zero indexed
    key1.index <- rep(0:(total.nr.entities - 1), cluster.options$k)
    
    # Create the candidate pairs and their features
    candidate.pairs <- data.table(
      cosine.similarity = cosineSimilarityV(embedding$vect, key1.index, key2.index),
      key1.index = key1.index,
      key2.index = key2.index
    )
    
    # Remove duplicated rows
    candidate.pairs <- candidate.pairs[!duplicated(candidate.pairs)]
    
    rule.weights <-  unlist(
      sapply(query.violation.data$rules, function(rule){
        supreme <- ifelse(is.null(rule$supreme), F, rule$supreme)
        ifelse(supreme, 1, rule$prob)
      })
    )
    
    rule.supremacy <- unlist(
      sapply(query.violation.data$rules, function(rule){
        ifelse(is.null(rule$supreme), F, rule$supreme)
      })
    )
    
    valid.candidate.pairs <- candidate.pairs[cosine.similarity >= cluster.options$theta]
    
    rm(candidate.pairs)
    

    if(any(rule.supremacy)) {
      print('Pruning candidate pairs')
      tic()
      valid.candidate.pairs <- prune.candidate.pairs(valid.candidate.pairs, embedding$dict, query.violation.data, query.options, rule.supremacy)
      toc()
    }
    
    
    print('Finding connected components...')
    tic()
    # NB components is zero indexed
    components <- connectedComponents(total.nr.entities, valid.candidate.pairs$key1.index, valid.candidate.pairs$key2.index)
    singletons <- sapply(components, length) == 1
    components <- components[!singletons]
    n.component <- length(components)
    toc()
    
    rm(valid.candidate.pairs)
    
    nRules <- length(query.violation.data$rules)
    
    print('Querying component violations...')
    tic()
    if(nRules > 0) {
      penalties <- perform.batch.query(components, embedding$dict, query.violation.data, query.options, rule.weights, rule.supremacy)
    } else {
      penalties <- pblapply(components, function(component){
        n <- length(component)
        k <- 0.5 * (n-1) * n
        return(rep(0,k))
      })
    }
    toc()
    
    print('cluster edit + vote')
    tic()
    clustering <- pblapply(1:n.component, function(i){
      editClustering(components[[i]], penalties[[i]], embedding$vect, embedding$dict, cluster.options$theta, cluster.options$epsilon, max.in.size = cluster.options$max.size.cluster.edit)
    }, cl = detectCores() - 1)
    
    toc()
    
    
    return(data.table(constructHumanReadableClustering(components, clustering, embedding$dict)))
    
  },
  finally = {
    annoy$unload()
  })
}