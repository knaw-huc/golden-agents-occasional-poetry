// [[Rcpp::plugins("cpp2a")]]

#include <Rcpp.h>
#include <queue>
#include <map>
#include <string>
#include <sstream>
#include <math.h>
#include <tuple>
#include <string>

using namespace Rcpp;


typedef std::pair<int, double> paired;

void print(const Rcpp::NumericVector& v) {
  const size_t n = v.length();
  for(size_t i = 0; i < n-1; i++) {
    Rcpp::Rcout << v[i] << ", ";
  }
  Rcpp::Rcout << v[n-1] << std::endl;
}

void print(const Rcpp::IntegerVector& v) {
  const size_t n = v.length();
  for(size_t i = 0; i < n-1; i++) {
    Rcpp::Rcout << v[i] << ", ";
  }
  Rcpp::Rcout << v[n-1] << std::endl;
}

void print(const Rcpp::IntegerMatrix& m) {
  const size_t row = m.nrow();
  const size_t col = m.ncol();
  
  for(size_t r = 0; r < row; r++) {
    for(size_t c = 0; c < col-1; c++) {
      Rcpp::Rcout << m(r,c) << ", ";
    }
    Rcpp::Rcout << m(r,col-1) << std::endl;
  }
}

void print(const Rcpp::NumericMatrix& m) {
  const size_t row = m.nrow();
  const size_t col = m.ncol();
  
  for(size_t r = 0; r < row; r++) {
    for(size_t c = 0; c < col-1; c++) {
      Rcpp::Rcout << m(r,c) << ", ";
    }
    Rcpp::Rcout << m(r,col-1) << std::endl;
  }
}

void replaceStringInPlace(std::string& subject, const std::string& search, const std::string& replace) {
  size_t pos = 0;
  while ((pos = subject.find(search, pos)) != std::string::npos) {
    subject.replace(pos, search.length(), replace);
    pos += replace.length();
  }
}

size_t combnToIndex(size_t a, size_t b, size_t n) {
  if(a > b) return (b - 1) * n - b * (b + 1) / 2 + a;
  else return (a - 1) * n - a * (a + 1) / 2 + b;
}


IntegerVector order(const NumericVector& v) {
  const size_t n = v.length();
  std::vector<paired> pairs;
  pairs.reserve(n);
  
  for(size_t i = 0; i < n; i++)
    pairs.push_back(std::make_pair(i, v[i]));
  
  std::sort(pairs.begin(), pairs.end(), [](paired a, paired b) {
    return a.second < b.second;
  });
  
  IntegerVector result = Rcpp::no_init(n);
  for(size_t i = 0; i < n; i++)
    result[i] = pairs[i].first;
  return result;
}


void _combn(IntegerVector& vals, const size_t n, const size_t start_idx, std::vector<double>& combn_data, IntegerMatrix& combn_ds, size_t& combn_col) {
  size_t rows = combn_ds.nrow();
  if (!n) {
    size_t cols = combn_ds.ncol();
    for (size_t i = 0; i < rows && combn_col < cols; i++) {
      combn_ds(i, combn_col) = combn_data.at(i);
    }
    combn_col++;
    return;
  }
  size_t nVals = vals.length();
  for (size_t i = start_idx; i <= (nVals - n); i++) {
    combn_data.at(rows - n) = vals[i];
    _combn(vals, n - 1, i + 1, combn_data, combn_ds, combn_col);
  }
}

IntegerMatrix comb_n(IntegerVector& vals, const size_t n) {
  static size_t combn_col = 0;
  const size_t nrows = n;
  const size_t ncols = std::round(R::choose(vals.length(), n));
  
  IntegerMatrix combn_ds(nrows, ncols);
  std::vector<double> combn_data(nrows);
  const size_t start_idx = 0;
  combn_col = 0; 
  _combn(vals, n, start_idx, combn_data, combn_ds, combn_col);
  return combn_ds;
}



double weight(int& i, int& j, NumericMatrix& vect, double& theta, double& epsilon, double& penalty) {
  NumericMatrix::Column a = vect(_, i);
  NumericMatrix::Column b = vect(_, j);
  
  double cos = Rcpp::sum(a*b) / (std::sqrt(Rcpp::sum(a*a)) * std::sqrt(Rcpp::sum(b*b)));
  double sim = cos - theta - penalty;

  return (sim == 0) ? epsilon : sim;
}

List adjacencyList(size_t n, IntegerVector& index1, IntegerVector& index2) {
  
  size_t nEdges = index1.length();
  bool processed[n]  = {false};
  std::vector<IntegerVector> adjList(n);
  
  for(size_t i = 0; i < nEdges; i++) {
    
    size_t u = index1[i];
    size_t v = index2[i];
    
    if(processed[u]) {
      adjList[u].push_back(v);
    } else {
      adjList[u] = IntegerVector::create(v);
      processed[u] = true;
    }
    
    if(processed[v]) {
      adjList[v].push_back(u);
    } else {
      adjList[v] = IntegerVector::create(u);
      processed[v] = true;
    }
  }
  return Rcpp::wrap(adjList);
}

IntegerVector bfs(size_t& v, List& adjlist, bool* visited) {
  
  std::queue<size_t> q;
  IntegerVector component = IntegerVector::create();
  q.push(v);
  visited[v] = true;
  
  while (!q.empty()) {
    size_t u = q.front();
    q.pop();
    component.push_back(u);
    IntegerVector adjV = adjlist[u];
    size_t n = adjV.length();
    
    for (size_t i = 0; i < n; i++) {
      size_t nextVertex = adjV[i];
      if (!visited[nextVertex]) {
        q.push(nextVertex);
        visited[nextVertex] = true;
      }
    }
    
  }
  return component;
}

// [[Rcpp::export]]
NumericVector violationsToPenalties(LogicalMatrix& M, NumericVector& P, LogicalVector& S, int supremePenalty) {
  
  const size_t rows = M.nrow();
  const size_t cols = M.ncol();
  
  NumericVector out = no_init(rows);
  
  for(size_t i = 0; i < rows; i++) {
    
    double p = 1;
    bool supreme = false;
    for(size_t j = 0; j < cols; j++) {
      if(S[j] && M(i,j)) {
        supreme = true;
        break;
      } else if(M(i,j)) {
        p = p * (1 - P[j]);
      }
    }
    if(supreme) {
      out[i] = supremePenalty;
    }else {
      out[i] = 1 - std::sqrt(p);
    }

  }
  
  return out;
}


// [[Rcpp::export]]
List connectedComponents(size_t& n, IntegerVector& index1, IntegerVector& index2) {
  
  List adjList = adjacencyList(n, index1, index2);
  
  bool visited[n]  = {false};
  List components = List::create();
  
  for(size_t i = 0; i < n; i++) {
    if (!visited[i]) {
      if(i % 100 == 0) Rcpp::checkUserInterrupt();
      components.push_back(bfs(i, adjList, visited));
    }
  }
  
  return components;
}

// [[Rcpp::export]]
NumericVector adjustedWeight(IntegerVector& index, NumericMatrix& vect, double& theta, double& epsilon, NumericVector& penalties) {
  
  const size_t n = index.length();
  
  NumericVector weights = no_init(0.5 * ((n-1) * n));
  for(size_t i = 0, k = 0; i < n ; i++) {
    for(size_t j = i + 1; j < n; j++) {
      weights(k) = weight(index[i], index[j], vect, theta, epsilon, penalties[k]);
      k++;
    }
  }
  return weights;
}


// [[Rcpp::export]]
IntegerMatrix comembershipTable(IntegerVector& a, IntegerVector& b) {
  
  const size_t n = a.length();
  
  IntegerMatrix table(2,2);
  for(size_t i = 0; i < n ; i++) {
    for(size_t j = i + 1; j < n; j++) {
      
      if(a[i] != a[j]) {
        
        if(b[i] == b[j]) table(1,0)++; // FN
        else table(1,1)++; // TN

      } else {
        
        if(b[i] == b[j]) table(0,0)++; // TP
        else table(0,1)++; // FP
        
      }
    }  
  }
  
  return table;
}


double clusterCost(IntegerVector& index, IntegerVector& cluster, NumericMatrix& vect, double& theta, double& epsilon, NumericVector& penalties) {

  const size_t n = index.length();
  
  double sum1 = 0;
  double sum2 = 0;
  
  for(size_t i = 0, k = 0; i < n ; i++) {
    for(size_t j = i + 1; j < n; j++) {
      double w = weight(index[i], index[j], vect, theta, epsilon, penalties[k]);
      if(w > 0) sum1 += w;
      
      if(cluster[i] == cluster[j])  
        sum2 += weight(index[i], index[j], vect, theta, epsilon, penalties[k]);
      
      k++;
    }
  }
  
  return sum1 - sum2;
}

// [[Rcpp::export]]
double clusteringCost(List& components, List& clusterings, NumericMatrix& vect, double& theta, double& epsilon, List& penalties) {
  
  size_t n = components.length();
  double sum = 0;
  
  for(size_t i= 0; i < n; i++) {
    
    IntegerVector component = components[i];
    IntegerVector clustering = clusterings[i];
    NumericVector penalty = penalties[i];
    sum += clusterCost(component, clustering, vect, theta, epsilon, penalty);
      
  }
  return sum;
}


// [[Rcpp::export]]
IntegerVector centerClustering(IntegerVector& index, NumericVector& penalties, NumericMatrix& vect, double& theta, double& epsilon) {
  
  const size_t n = index.length();
  
  if(n == 1) return index;
  if(n == 2) {
    if(weight(index[0], index[1], vect, theta, epsilon, penalties[0]) > 0)  return IntegerVector::create(index[0], index[0]);  
    else return index;
  }
  
  const size_t nEdges = (n * (n - 1)) / 2;
    
  NumericVector edgeSimilarity(nEdges);
  IntegerVector leftNodes(nEdges);
  IntegerVector rightNodes(nEdges);
  
  IntegerVector clusters = clone(index);
  
  for(size_t i = 0, k = 0; i < n ; i++) {
    for(size_t j = i + 1; j < n ; j++) {
      
      if(i % 100 == 0) Rcpp::checkUserInterrupt();
      
      edgeSimilarity[k] = weight(index[i], index[j], vect, theta, epsilon, penalties[k]);
      leftNodes[k] = i;
      rightNodes[k] = j;
      
      k++;
    }
  }
  
  IntegerVector edgesOrder = rev(order(edgeSimilarity));
  
  bool hasCluster[n]  = {false};
  bool isCenter[n] = {false};
  
  for(size_t i = 0; i < nEdges; i++) {
    
    if(i % 100 == 0) Rcpp::checkUserInterrupt();
    
    size_t node1 = leftNodes[edgesOrder[i]];
    size_t node2 = rightNodes[edgesOrder[i]];
    
    if(!hasCluster[node1] && !hasCluster[node2]) {
      
      clusters[node1] = index[node1];
      clusters[node2] = index[node1];
      
      isCenter[node2] = true;
      hasCluster[node1] = true;
      hasCluster[node2] = true;
      
    } else if(isCenter[node1] && !hasCluster[node2]) {
      
      clusters[node2] = index[node1];
      hasCluster[node2] = true;

    } else if(isCenter[node2] && !hasCluster[node1]) {
      
      clusters[node1] = index[node2];
      hasCluster[node1] = true;

    }
  }
  
  return clusters;
}

// [[Rcpp::export]]
IntegerVector centerMergeClustering(IntegerVector& index, NumericVector& penalties, NumericMatrix& vect, double& theta, double& epsilon) {
  
  const size_t n = index.length();
  
  if(n == 1) return index;
  if(n == 2) {
    if(weight(index[0], index[1], vect, theta, epsilon, penalties[0]) > 0)  return IntegerVector::create(index[0], index[0]);  
    else return index;
  }
  
  const size_t nEdges = (n * (n - 1)) / 2;
  
  NumericVector edgeSimilarity(nEdges);
  IntegerVector clusters = clone(index);
  
  IntegerVector leftNodes(nEdges);
  IntegerVector rightNodes(nEdges);
  
  for(size_t i = 0, k = 0; i < n ; i++) {
    for(size_t j = i + 1; j < n ; j++) {
      
      if(i % 100 == 0) Rcpp::checkUserInterrupt();

      edgeSimilarity[k] = weight(index[i], index[j], vect, theta, epsilon, penalties[k]);
      leftNodes[k] = i;
      rightNodes[k] = j;
      k++;
    }
  }
  
  IntegerVector edgesOrder = rev(order(edgeSimilarity));
  
  bool hasCluster[n]  = {false};
  bool isCenter[n] = {false};
  
  for(size_t i = 0; i < nEdges; i++) {
    
    if(i % 100 == 0) Rcpp::checkUserInterrupt();
    
    size_t node1 = leftNodes[edgesOrder[i]];
    size_t node2 = rightNodes[edgesOrder[i]];
    
    if(!hasCluster[node1] && !hasCluster[node2]) {
      
      clusters[node1] = index[node1];
      clusters[node2] = index[node1];
      
      isCenter[node2] = true;
      hasCluster[node1] = true;
      hasCluster[node2] = true;
      
    } else if (isCenter[node1] && hasCluster[node2] && clusters[node1] != clusters[node2]) {
      
      for(size_t j = 0; j < n; j++) {
        if(clusters[j] == index[node2]) {
          clusters[j] = index[node1];
        }
      }
      
    } else if (isCenter[node2] && hasCluster[node1] && clusters[node1] != clusters[node2]) {
      
      for(size_t j = 0; j < n; j++) {
        if(clusters[j] == index[node1]) {
          clusters[j] = index[node2];
        }
      }
      
    } else if(isCenter[node1] && !hasCluster[node2]) {
      
      clusters[node2] = index[node1];
      hasCluster[node2] = true;
      
    } else if(isCenter[node2] && !hasCluster[node1]) {
      
      clusters[node1] = index[node2];
      hasCluster[node1] = true;
    }
    
  }
  
  return clusters;
  
}


// [[Rcpp::export]]
IntegerVector voteClustering(IntegerVector& index, NumericVector& penalties, NumericMatrix& vect, double& theta, double& epsilon) {
  
  const size_t n = index.length();
  
  if(n == 1) return index;
  if(n == 2) {
    if(weight(index[0], index[1], vect, theta, epsilon, penalties[0]) > 0)  return IntegerVector::create(index[0], index[0]);  
    else return index;
  }

  size_t nClust = 0;
  std::vector<size_t> clusterIndex;
  IntegerVector clusters = no_init(n);
  
  clusters[0] = index[0];
  clusterIndex.push_back(nClust++);
  
  for(size_t i = 1; i < n; i++) {
    
    if(i % 100 == 0) Rcpp::checkUserInterrupt();
    
    NumericVector sums(nClust);
    
    double bestSum = 0;
    size_t bestClst = 0;
    size_t bestIndex = 0;
    
    for(size_t j = 0; j < i; j++) {
      
      size_t k = combnToIndex(i+1, j+1, n) - 1;
      sums(clusterIndex[j]) += weight(index[i], index[j], vect, theta, epsilon, penalties[k]);
      
      if(sums(clusterIndex[j]) > bestSum) {
        bestSum = sums(clusterIndex[j]);
        bestClst = clusterIndex[j];
        bestIndex = clusters[j];
      }
    }
    
    if(sums(bestClst) > 0) {
      clusters[i] = bestIndex;
      clusterIndex.push_back(bestClst);
    } else {
      clusters[i] = index[i];
      clusterIndex.push_back(nClust++);
    }
  }

  return clusters;
}


// [[Rcpp::export]]
NumericVector cosineSimilarityV(NumericMatrix& vect, IntegerVector& index1, IntegerVector& index2) {
  
  const size_t n = index1.length();
  
  NumericVector sim = no_init(n);
  
  for(size_t i = 0; i < n ; i++) {
    
    NumericMatrix::Column a = vect(_, index1[i]);
    NumericMatrix::Column b = vect(_, index2[i]);
    
    sim[i] = Rcpp::sum(a*b) / (std::sqrt(Rcpp::sum(a*a)) * std::sqrt(Rcpp::sum(b*b)));
  }
  
  return sim;
}

// [[Rcpp::export]]
NumericMatrix normalize(NumericMatrix& vect) {
  const size_t n = vect.ncol();
  
  for(size_t i = 0; i < n; i++) {
    
    NumericMatrix::Column c = vect(_, i);
    c = c / std::sqrt(Rcpp::sum(c*c));
  }
  
  return vect;
}

// [[Rcpp::export]]
IntegerMatrix getallTriangles(size_t& n) {
  
  IntegerVector vals = seq(1, n);
  IntegerMatrix triangles = comb_n(vals, 3);
  
  size_t nTriangles = triangles.ncol();
  
  // Output matrix
  IntegerMatrix out(3, nTriangles);
  
  for(size_t i = 0; i < nTriangles; i++) {
    for(size_t j = 0; j < 2; j++) {
      for(size_t k = j + 1; k < 3; k++) {

        // Take an edge from the triangle
        size_t a = triangles(j, i);
        size_t b = triangles(k, i);
        
        out(j + k - 1, i) = combnToIndex(a,b,n);//(a - 1) * n - a * (a + 1) / 2 + b;
      }
    }
  }
  
  return out;
}

// [[Rcpp::export]]
IntegerVector extractSolution(IntegerVector& index, IntegerVector& lpSolution) {
  
  const size_t n = index.length();
  const size_t nEdges = (n * (n - 1)) / 2;
  IntegerVector out = clone(index);

  std::vector<size_t> a;
  std::vector<size_t> b;
  
  a.reserve(nEdges);
  b.reserve(nEdges);
  
  for(size_t i = 0, k = 0; i < n ; i++) {
    for(size_t j = i + 1; j < n; j++) {
      if(lpSolution[k++]) {
        a.push_back(i);
        b.push_back(j);
      }
    }
  }
  
  IntegerVector index1 = Rcpp::wrap(a);
  IntegerVector index2 = Rcpp::wrap(b);
  
  size_t nVerts = index.length();
  List components = connectedComponents(nVerts, index1, index2);
  size_t nComponents = components.length();

  for(size_t i = 0; i < nComponents; i++){
  
    IntegerVector component = components[i];
    size_t nElem = component.length();

    for(size_t j = 0; j < nElem; j++) {
      out[component[j]] = index[component[0]];
    }
  }
  
  return out;
}

// [[Rcpp::export]]
List constructBatchQuery(List& components, IntegerVector& dict, std::string queryFormat, const size_t maxQuerySize, size_t& currentComponent, size_t& currentPair) {

  size_t processedPairs = 0;
  
  const size_t nComp = components.length();
  const CharacterVector uri = dict.attr("levels");
  std::ostringstream builder;
  bool finished = false;
  
  size_t j = 0;
  size_t i = currentPair;
  size_t c = currentComponent;
  
  for(; c < nComp; c++) {
    
    IntegerVector index = components[c];
    IntegerMatrix pairs = comb_n(index, 2);
    
    const size_t n = index.length();
    const size_t nPairs = 0.5 * (n-1) * n;
    
    for(; i < nPairs; i++, j++) {
      
      if(j == maxQuerySize) {
        finished = true;
        break;
      }
      
      builder << "\t\t(" << c << " "<< i << " <" << uri[dict[pairs(0,i)]-1] << "><" << uri[dict[pairs(1,i)]-1] << ">)"<< std::endl;
    }
    
    if(finished) break;
    
    i = 0;
  }
  
  currentPair = i;
  currentComponent = c;
  processedPairs = j;
  
  std::string s = builder.str();
  
  char buffer[s.length() + queryFormat.length()];
  sprintf(buffer, queryFormat.c_str(), s.c_str());
  String query(buffer);
  
  return List::create(_["query"] = query, _["currentComponent"] = currentComponent, _["currentPair"] = currentPair, _["processedPairs"] = processedPairs);
}

// [[Rcpp::export]]
List constructPruneQuery(IntegerVector& p1, IntegerVector& p2, IntegerVector& dict, std::string queryFormat, const size_t maxQuerySize, size_t& currentPair) {
  
  const size_t nPairs = p1.length();
  const CharacterVector uri = dict.attr("levels");
  std::ostringstream builder;
  
  const size_t c = 0;
  size_t j = 0;
  size_t i = currentPair;
  
  for(; i < nPairs && j < maxQuerySize; i++, j++) {
    builder << "\t\t(" << c << " "<< i << " <" << uri[dict[p1[i]]-1] << "><" << uri[dict[p2[i]]-1] << ">)"<< std::endl;
  }

  
  std::string s = builder.str();
  char buffer[s.length() + queryFormat.length()];
  sprintf(buffer, queryFormat.c_str(), s.c_str());
  String query(buffer);
  
  return List::create(_["query"] = query, _["processedPairs"] = j);
}

// [[Rcpp::export]]
size_t totalPairs(List& components) {
  const size_t nComp = components.length();
  
  size_t totalPairs = 0;
  
  for(size_t c = 0; c < nComp; c++) {
    IntegerVector index = components[c];
    const size_t n = index.length();
    const size_t nPairs = 0.5 * (n-1) * n;
    
    totalPairs += nPairs;
  }
  
  return totalPairs;
}

// [[Rcpp::export]]
List mergeLists(List& l1, List& l2, const size_t nComponents, const size_t startComponent) {
  
  const size_t appendListSize = l2.length();
  size_t j = startComponent;
  size_t i = 0;
  
  for(; i < appendListSize; i++, j++) {
    
    NumericVector w = l2[i];
    
    std::string key = std::to_string(j);
    char c[key.size() + 1];
    strcpy(c, key.c_str());
    
    if(l1.containsElementNamed(c)) {
      //Rcout << "Appending to previous result for component "<< (j) << std::endl;
      NumericVector u = l1[c];
      
      for(int k : w) {
        u.push_back(k);
      }
      l1[c] = u;
      
    } else {
      //Rcout << "Adding new result for component "<< (j) << std::endl;
      l1[c] = w;
    }
    
  }
  
  return l1;
}


// [[Rcpp::export]]
String constructBatchQueryBase(List& queryData, bool onlySupreme = false) {
  
  const String e1 = "e1";
  const String e2 = "e2";
  
  List rules = queryData["rules"];
  List queryPrefixes = queryData["prefixes"];
  
  const size_t nRules = rules.length();
  const size_t nPrefix = queryPrefixes.length();

  std::ostringstream builder;
  std::set<std::string> previousRules;
  
  for(size_t i = 0; i < nPrefix; i++) {
    String prefix = queryPrefixes[i];
    builder << "PREFIX " << prefix.get_cstring() << std::endl;
  }
  
  
  builder << "SELECT DISTINCT ?c ?" << e1.get_cstring() << " ?" << e2.get_cstring() << " ";
  
  for(size_t i = 0; i < nRules; i++) {
    
    List rule = rules[i];
    
    bool supreme = rule.containsElementNamed("supreme") ? rule["supreme"] : false;
    
    if(onlySupreme && !supreme) {
      continue;
    }
    
    builder << "?r" << (i+1) << " ";
  }
  
  List entityTypes = queryData["types"];
  String eType1 = entityTypes[0];
  String eType2 = entityTypes[1];
  
  builder << "WHERE {" << std::endl;
  builder << "\t?"<< e1.get_cstring() <<" a " << eType1.get_cstring() <<  "."<< std::endl;
  builder << "\t?"<< e2.get_cstring() <<" a " << eType2.get_cstring() <<  "."<< std::endl;
  
  
  builder << "\tVALUES (?c ?i ?"<<e1.get_cstring()<<" ?"<<e2.get_cstring()<<") {" << std::endl << "%s\t}"<< std::endl;
  
  
  for(size_t i = 0; i < nRules; i++) {
    
    List rule = rules[i];
    
    bool supreme = rule.containsElementNamed("supreme") ? rule["supreme"] : false;
    
    if(onlySupreme && !supreme) {
      continue;
    }
    
    bool hasTriples1 = rule.containsElementNamed("triples1");
    bool hasTriples2 = rule.containsElementNamed("triples2");
    
    if(hasTriples1) {
      List triples1 = rule["triples1"];
      for(int j = 0; j < triples1.length(); j++) {
        
        List triple = triples1[j];
        
        bool optional = triple.containsElementNamed("optional") ? triple["optional"] : false;
        
        std::ostringstream tripleBuilder;
        
        String subject = triple.containsElementNamed("subject") ? triple["subject"] : String("?") += e1;
        String pred = triple["pred"];
        String object = triple.containsElementNamed("object") ? triple["object"] : String("?") += e1;
        
        tripleBuilder << subject.get_cstring() <<  " " << pred.get_cstring() <<  " " << object.get_cstring();
        
        std::string tripleString = tripleBuilder.str();
        const bool used = previousRules.find(tripleString) != previousRules.end();
        
        if(!used) {
          
          if(optional) builder << "\tOPTIONAL{" << tripleString << ".}" << std::endl;
          else builder << "\t" << tripleString << "." << std::endl;
          
          previousRules.insert(tripleString);
        }
      }
    }
    
    if(hasTriples2) {
      List triples2 = rule["triples2"];
      for(int j = 0; j < triples2.length(); j++) {
        
        List triple = triples2[j];
        
        bool optional = triple.containsElementNamed("optional") ? triple["optional"] : false;
        
        std::ostringstream tripleBuilder;
        
        String subject = triple.containsElementNamed("subject") ? triple["subject"] : String("?") += e2;
        String pred = triple["pred"];
        String object = triple.containsElementNamed("object") ? triple["object"] : String("?") += e2;
        
        tripleBuilder << subject.get_cstring() <<  " " << pred.get_cstring() <<  " " << object.get_cstring();
        
        std::string tripleString = tripleBuilder.str();
        const bool used = previousRules.find(tripleString) != previousRules.end();
        
        if(!used) {
          
          if(optional) builder << "\tOPTIONAL{" << tripleString << ".}" << std::endl;
          else builder << "\t" << tripleString << "." << std::endl;
          
          previousRules.insert(tripleString);
        }
      }
    }
  }

  
  for(size_t i = 0; i < nRules; i++) {
    
    List rule = rules[i];
    
    bool supreme = rule.containsElementNamed("supreme") ? rule["supreme"] : false;
    
    if(onlySupreme && !supreme) {
      continue;
    }
    
    std::string ruleStr_a = rule["rule"];
    builder << "\tBIND( " << ruleStr_a << " AS ?r" << i+1 << ")"<< std::endl;
  }
  
  builder << "} ORDER BY ASC(?c) ASC(?i)";
  
  return String(builder.str());
}



// [[Rcpp::export]]
DataFrame constructHumanReadableClustering(List& components, List& clusterings, IntegerVector& dict) {
  
  CharacterVector URIdict = dict.attr("levels");
  const size_t nComp = components.length();
  std::map<size_t, IntegerVector> clusterMap; 
  
  for(size_t i = 0; i < nComp; i++) {
    
    IntegerVector component = components[i];
    IntegerVector clustering = clusterings[i];
    
    const size_t compSize = component.length();
    bool clustered[compSize] = {false};
    
    for(size_t j = 0; j < compSize; j++) {
      
      if(clustered[j]) continue;
      
      clusterMap.insert({component[j], IntegerVector::create(component[j])});
      clustered[j] = true;
      
      for(size_t k = j+1; k < compSize; k++) {
        
        if(clustered[k]) continue;
        
        if(clustering[j] == clustering[k]) {
          
          IntegerVector sv = clusterMap[component[j]];
          sv.push_back(component[k]);
          clusterMap[component[j]] = sv;
          clustered[k] = true;
        }
      }
    }
  }
  
  IntegerVector clusterID = IntegerVector::create();
  StringVector uri = StringVector::create();
  
  std::map<size_t, IntegerVector>::iterator itr;

  for (itr =  clusterMap.begin(); itr !=  clusterMap.end(); ++itr) { 
    
    IntegerVector sv = itr->second;
    const size_t n = sv.length();
    
    if(n > 1) {
      int id = itr->first;
      for(size_t i = 0; i < n; i++) {
        clusterID.push_back(id);
        uri.push_back(URIdict[dict[sv[i]]-1]);
      }
    }
      
  }
  
  DataFrame df = DataFrame::create(Named("cluster_id") = clusterID, Named("uri") = uri); 
  
  return df;
}











