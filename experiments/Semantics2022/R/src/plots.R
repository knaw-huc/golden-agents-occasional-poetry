library(data.table)
library(ggplot2)
library(ggpubr)

legend.vars <- c('clst.closure', 'clst.center', 'clst.center.merge', 'clst.vote', 'clst.edit.vote')
legend.labels <- c('closure', 'center', 'merge center', 'vote', 'corr. clust. & vote')

make.plot <- function(results, metric) {
  
  vars <- paste0(legend.vars,'.',metric)
  data <- melt(results, id.vars = 'cutoff', measure.vars = vars)
  levels(data$variable) <- legend.labels
  plot <- 
    ggplot(data) + 
    geom_line(aes(y = value, x = cutoff, linetype = variable, color = variable), size = 1.5) + 
    theme_bw() + 
    guides(linetype = guide_legend(nrow = 1)) +
    scale_y_continuous(breaks = seq(0,1, by = 0.1), labels = seq(0,1,by = 0.1),limits = c(0,1)) +
    theme(legend.position='bottom', legend.title = element_blank(), legend.text=element_text(size=18), text = element_text(size = 28), legend.key.size = grid::unit(2.4, "lines"), axis.title.x=element_blank(), axis.title.y=element_blank()) 
  
  return(plot)
}

make.cost.plot <- function(results, metric) {
  
  vars <- paste0(legend.vars,'.',metric)
  data <- melt(results, id.vars = 'cutoff', measure.vars = vars)
  levels(data$variable) <- legend.labels
  plot <- 
    ggplot(data) + 
    geom_line(aes(y = value, x = cutoff, linetype = variable, color = variable), size = 1.5) + 
    theme_bw() + 
    guides(linetype = guide_legend(nrow = 1)) +
    scale_y_continuous(limits = c(0,10000)) +
    theme(legend.position='bottom', legend.title = element_blank(), legend.text=element_text(size=18), text = element_text(size = 28), legend.key.size = grid::unit(2.4, "lines"), axis.title.x=element_blank(), axis.title.y=element_blank()) 
  
  return(plot)
}

make.table <- function(results, metric) {
  
  vars <- paste0(legend.vars,'.',metric)
  
  tab <- data.table(t(sapply(vars, function(v){
    i <- which.max(results[,get(v)])
    as.numeric(results[i, .(cutoff, get(v))])
  })))
  colnames(tab) <- c(paste0(metric,'.cutoff'), paste0(metric, '.value'))
  return(tab)
}

make.error.bar <- function(counts) {
  stats <- data.table(
    name = factor(colnames(counts)[-1], levels= colnames(counts)[-1]),
    sd = apply(counts[,-1], 2, sd),
    mean = apply(counts[,-1], 2, mean)
  )
  plot<- ggplot(stats) +
    geom_bar( aes(x=name, y=mean), stat="identity", fill="skyblue", alpha=0.7) +
    geom_errorbar( aes(x=name, ymin=mean-sd, ymax=mean+sd), width=0.4,stat="identity", colour="orange", alpha=0.9, size=1.3) +
    xlab('Mean frequency') +
    theme_bw() +
    theme(axis.title.x=element_blank())
  
  return(plot)
}


#saa.results.no.domain <- fread('results/saa.results.k2.tsv')

# plot.saa.f10 <- make.plot(saa.results, 'f10')
# plot.saa.f05 <- make.plot(saa.results, 'f05')
# plot.saa.prc <- make.plot(saa.results, 'prc')
# plot.saa.rec <- make.plot(saa.results, 'rec')
# plot.saa.scr <- make.cost.plot(saa.results, 'scr')
# 
# ggsave(filename = 'plots/plot.saa.f102.pdf', plot = plot.saa.f10 + theme(legend.position = "none"), device = 'pdf', width = 30, height = 15, units = 'cm')
# ggsave(filename = 'plots/plot.saa.f05.pdf', plot = plot.saa.f05 + theme(legend.position = "none"), device = 'pdf', width = 30, height = 15, units = 'cm')
# ggsave(filename = 'plots/plot.saa.prc.pdf', plot = plot.saa.prc + theme(legend.position = "none"), device = 'pdf', width = 30, height = 15, units = 'cm')
# ggsave(filename = 'plots/plot.saa.rec.pdf', plot = plot.saa.rec + theme(legend.position = "none"), device = 'pdf', width = 30, height = 15, units = 'cm')
# ggsave(filename = 'plots/plot.saa.legend.pdf', plot = get_legend(plot.saa.f10)  , device = 'pdf', width = 30, height = 0.75, units = 'cm')
# 
# 
# saa.f05 <- make.table(saa.results, 'f05')
# saa.f10 <- make.table(saa.results, 'f10')
# 
# fwrite(round(data.table(saa.f05, saa.f10), 2), file = 'plots/table.saa.tsv', sep = '\t', row.names = F, col.names = T)
# 
# 
# 
# 
# 
# 
# dblp.results <- fread('results/dblp.results.k2.tsv')
# 
# plot.dblp.f10 <- make.plot(dblp.results, 'f10')
# plot.dblp.f05 <- make.plot(dblp.results, 'f05')
# plot.dblp.prc <- make.plot(dblp.results, 'prc')
# plot.dblp.rec <- make.plot(dblp.results, 'rec')
# 
# ggsave(filename = 'plots/plot.dblp.f10.pdf', plot = plot.dblp.f10 + theme(legend.position = "none"), device = 'pdf', width = 30, height = 15, units = 'cm')
# ggsave(filename = 'plots/plot.dblp.f05.pdf', plot = plot.dblp.f05 + theme(legend.position = "none"), device = 'pdf', width = 30, height = 15, units = 'cm')
# ggsave(filename = 'plots/plot.dblp.prc.pdf', plot = plot.dblp.prc + theme(legend.position = "none"), device = 'pdf', width = 30, height = 15, units = 'cm')
# ggsave(filename = 'plots/plot.dblp.rec.pdf', plot = plot.dblp.rec + theme(legend.position = "none"), device = 'pdf', width = 30, height = 15, units = 'cm')
# ggsave(filename = 'plots/plot.dblp.legend.pdf', plot = get_legend(plot.dblp.f10)  , device = 'pdf', width = 30, height = 0.75, units = 'cm')
# 
# dblp.f05 <- make.table(dblp.results, 'f05')
# dblp.f10 <- make.table(dblp.results, 'f10')
# 
# fwrite(round(data.table(dblp.f05, dblp.f10), 2), file = 'plots/table.dblp.tsv', sep = '\t', row.names = F, col.names = T)