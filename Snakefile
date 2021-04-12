# use snakemake to run this Snakefile
# the final rule lmmlasso is to be skipped or modified by the user as my corresponding script for genotype - phenotype trait prediction is only soon available



CHR = ["{}".format(i) for i in list(range(1, 23))] + ["X", "Y"]
GEN = ['bed', 'bim', 'fam']
MAF = '0.04'
GENO = '0.02'
PRUNELD =  '0.5'
LIST_FILE = str( expand("chr{chromosome}_maf{maf}_geno{geno}_pruned0.5" ,chromosome=CHR, maf=MAF, geno=GENO) ).split()       # input for the rule lmmlasso


genetic_path = "/directory/with/bedbimfam/files/microarray/unzipped"
derived_path = "/filter/geneticfiles/maf0.04_geno0.02_pruned0.5"


rule all:
    input:
	   "/resultdir/samples_height_withconf_pr0.5.pdf"


rule plink_maf_geno:
    input:
        expand(genetic_path + "/ukb_chr{chromosome}_v2.{ext}", ext=GEN, chromosome=CHR)
    params:
        infile = expand(genetic_path + "/ukb_chr{chromosome}_v2", chromosome=CHR),
        outfile = expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}", chromosome=CHR, maf=MAF, geno=GENO),
        maf = float(MAF),
        geno = float(GENO)
    output:
        temp(expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}.{ext}", ext=GEN, chromosome=CHR, maf=MAF, geno=GENO))
    run:
        for infile, outfile in zip(params.infile, params.outfile):
            shell("/home/Aliki.Zavaropoulou/plink2 --bfile {infile} --snps-only --hwe 0.00001 --maf {params.maf} --geno {params.geno} --make-bed --out {outfile}")


rule plink_prunset:
    input:
        expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}.{ext}", ext=GEN, chromosome=CHR, maf=MAF, geno=GENO)
    params:
        infile = expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}", chromosome=CHR, maf=MAF, geno=GENO),
        outfile = expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}", chromosome=CHR, maf=MAF, geno=GENO),
	prune = float(PRUNELD)
    output:
        temp(expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}.prune.in", chromosome=CHR, maf=MAF, geno=GENO)),
        temp(expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}.prune.out", chromosome=CHR, maf=MAF, geno=GENO))
    run:
        for infile, outfile in zip(params.infile, params.outfile):
            shell("/home/Aliki.Zavaropoulou/plink2 --bfile {infile} --indep-pairwise 500 1 {params.prune} --out {outfile}")


rule plink_extract:
    input:
        expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}.{ext}", ext=GEN ,chromosome=CHR, maf=MAF, geno=GENO),
        expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}.prune.in", chromosome=CHR, maf=MAF, geno=GENO)
    params:
        infile = expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}", chromosome=CHR, maf=MAF, geno=GENO),
        prune = expand(derived_path + "/ukb_chr{chromosome}_maf{maf}_geno{geno}.prune.in", chromosome=CHR, maf=MAF, geno=GENO),
        outfile = expand(derived_path + "/chr{chromosome}_maf{maf}_geno{geno}_pruned0.5", chromosome=CHR, maf=MAF, geno=GENO)
    output:
        expand(derived_path + "/chr{chromosome}_maf{maf}_geno{geno}_pruned0.5.{ext}", ext=GEN ,chromosome=CHR, maf=MAF, geno=GENO)
    run:
        for infile, prune, outfile in zip(params.infile, params.prune, params.outfile):
            shell("/home/Aliki.Zavaropoulou/plink2 --bfile {infile} --extract {prune} --make-bed --out {outfile}")


rule lmmlasso:
    input:
      bed = expand(derived_path + "/chr{chromosome}_maf{maf}_geno{geno}_pruned0.5.bed" ,chromosome=CHR, maf=MAF, geno=GENO),
      bim = expand(derived_path + "/chr{chromosome}_maf{maf}_geno{geno}_pruned0.5.bim" ,chromosome=CHR, maf=MAF, geno=GENO),
      fam = expand(derived_path + "/chr{chromosome}_maf{maf}_geno{geno}_pruned0.5.fam" ,chromosome=CHR, maf=MAF, geno=GENO)
    params:
      inname = LIST_FILE ,
      toremove = derived_path + "/chr*.log"
    conda: "/myenvironments/newpy3.yaml"
    output:
        "/resultdir/samples_height_withconf_pr0.5.pdf"
    shell:
        """
        echo {params.inname}
	python /tobepulished/soon/code/simple_test.py -f "{params.inname}" -p "{derived_path}" -m 100000 -n 1
	"""

