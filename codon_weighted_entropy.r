library(getopt)
source("codon_services.r")

# read parameters
opt <- getopt(matrix(c(
    'input','i',1,'character',
    'output','o',1,'character',
    'translation','t',2,'integer'), 
    byrow=T, ncol=4))
if (is.null(opt$translation)) opt$translation <- 1    
    
genome_af <- read.table(opt$input, header=T)

genome_rf <- calculate_relative_frequencies(genome_af, opt$translation)

codons_of <- get_codon_aa_table(genome_rf, opt$translation)
# we only want to use aas with more than one synonymous codon
codons_of <- codons_of[sapply(codons_of,function(x) length(x) > 1)]
degeneracies <- sapply(codons_of,length)

# for each aa (Phe, Lys,...), get its codons (columns),
genome_entropies <- sapply(names(codons_of), function(x) {
    #access their rf and calculate entropy (on rows)
    apply(genome_rf[,codons_of[[x]]],1, shannon.entropy)
})
genome_entropies[is.na(genome_entropies)] <- 0

# for each aa (Phe, Lys,...), get its codons (columns),
aa_bias <- sapply(names(codons_of), function(aa) {
    apply(genome_af,1, function(gene) sum(gene[codons_of[[aa]]])/sum(gene))
})
aa_bias[is.na(aa_bias)] <- 0

genome_weighted_entropies <- shannon.weighted.entropy(genome_entropies, degeneracies, aa_bias)

write.table(genome_weighted_entropies, opt$output)