#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use Net::FTP;
use File::chdir;

#ADD GNU license here!

######################
#
#To do list:
#Change the script to use the NCBI's prokaryotes.csv file to select 1 phylum (or all)
#and download all genomes available for this phylum.
#
#
#Column order in NCBI's prokaryotes.csv file:
#Organism/Name	TaxID	BioProject Accession	BioProject ID	Group	SubGroup	Size (Mb)	GC%	Chromosomes/RefSeq	Chromosomes/INSDC	Plasmids/RefSeq	Plasmids/INSDC	WGS	Scaffolds	Genes	Proteins	Release Date	Modify Date	Status	Center	BioSample Accession	Assembly Accession	Reference	FTP Path	Pubmed ID
#Column 6 contains the Phylum name: add option -group
#Column 7 contains the Class name: add option -class; mostly only useful for Proteobacteria
#
#In the file assembly_summary.csv the column of interest is ftp_path (column 17)
# assembly_accession	bioproject	biosample	wgs_master	refseq_category	taxid	species_taxid	organism_name	infraspecific_name	isolate	version_status	assembly_level	release_type	genome_rep	seq_rel_date	asm_name	submitter	gbrs_paired_asm	paired_asm_comp	ftp_path	excluded_from_refseq
#
#
#
################################################################

#command line options, the variable names should be self explanatory;
my $list_file;
my $genome_url_table;
my $verbose;
my $debug;
my $ftp = "ftp.ncbi.nlm.nih.gov"; #Default = NCBI ftp
my $genomes_dir = "/genomes/all"; # where in the ftp server should I look
my $ftp_user = "anonymous"; #which user should I use?
my $ftp_password = "anonymous"; #which password should I use?
my $output_folder = "."; #where should I store the genomes?
my $group = undef; #name of phylum to be selected
my $subgroup = undef; #name of class to be selected
my $group_column = 5; #column in list with name of phylum to be selected
my $subgroup_column = 6; #column in list with name of class to be selected
my $assembly_accession = 22; #column in list with assembly accession name for each genome
my $accession_column = 1;
my $url_column = 20;
my $with_protein_annotations = 0;

my $usage = "The following options have to be provided:
		--list_file = prokaryotes.csv file from NCBI; download at ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt and change .txt by .csv
		--genome_url_table = the bacterial assemblies file; download at ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/bacteria/assembly_summary.txt and change .txt by .csv

The following options can be provided; in each case the defaults are shown:
		--ftp ftp.ncbi.nlm.nih.gov
		--dir /genomes/all
		--out = .
		--user anonymous
		--password anonymous
		--group undef
		--subgroup undef
		--with_protein_annotations F
		--group_column 6
		--subgroup_column 7
		--assembly 23
		--verbose
		--debug

A normal command line would look like:
	perl Fetch_Genomes.pl --list_file ./prokaryotes.csv --genome_url_table ./assembly_summary.csv --group Cyanobacteria
	
Defining these options is required!

To download only genomes with protein annotations (i.e. *.faa exists):
	perl Fetch_Genomes.pl --list_file ./prokaryotes.csv --genome_url_table ./assembly_summary.csv --group Cyanobacteria --with_protein_annotations

A funky one (if I modify the prokaryotes.csv file...)
	perl Fetch_Genomes.pl --list_file ./prokaryotes.csv --./assembly_summary.csv --group Cyanobacteria --group_column 10 --assembly 1 --out ~/my_genomes

The following groups can be used as search criteria:
				
				
				
The following subgroups can be used as search criteria:

				
				

";

my $help =  "This script should help you download a bunch of genomes from the NCBI ftp server.\nThe script expects a list of genomes to be downloaded, this list of genomes must provide the names of the folders where the genomes are stored in NCBI's ftp server. These folders are names after the \"Assembly Accession\".\n\nRun perl Fetch_Genomes.pl --usage to see a list of the different options you have".

#get options from command line
GetOptions("list_file=s" => \$list_file,
					 "genome_url_table=s" => \$genome_url_table,
					 "ftp=s" => \$ftp,
					 "dir=s" => \$genomes_dir,
					 "out=s" => \$output_folder,
					 "user=s" => \$ftp_user,
					 "password=s" => \$ftp_password,
					 "group=s" => \$group,
					 "subgroup=s" => \$subgroup,
 					 "group_column=i" => \$group_column,
					 "subgroup_column=i" => \$subgroup_column,	
					 "assembly=i" => \$assembly_accession,
					 "verbose" => \$verbose,
 					 "with_protein_annotations" => \$with_protein_annotations,
					 "debug" => \$debug,
					 "usage" => \$usage
					 )
or die("Error in the command line arguments\n$usage");

#check that some options are defined;
#die "\nERROR: A file defining the genomes to download must be provided through the --list_file option\n\n" unless defined $list_file;
die "\n$usage\n" unless (defined $list_file && defined $group && defined $genome_url_table);

print("Starting with the following parameters:
		--list_file $list_file
		--genome_url_table $genome_url_table
		--ftp $ftp
		--dir $genomes_dir
		--out $output_folder
		--user $ftp_user
		--password $ftp_password
		--group $group
		--subgroup $subgroup
		--group_column $group_column
		--subgroup_column $subgroup_column
		--assembly $assembly_accession
		--with_protein_annotations $with_protein_annotations\n", $verbose?"\t\t--verbose TRUE\n":"\t\t--verbose FALSE\n", $debug?"\t\t--debug TRUE\n":"\t\t--debug FALSE\n");

#read urls for each assembly accession number
#get the ftp names of the genomes in the genome_url_table.
#
#we need to extract the folder name from the ulr name because later we will access the ftp and go to each folder.
#
#
my %genome_folder_names;
open(URL_TABLE, $genome_url_table) or die "Cannot open the genome list file";
#read and discard the first line = header

<URL_TABLE>;

while(<URL_TABLE>){
	my @genome_accession_details = split(/\t/);

	my @genome_url = split(/\//, $genome_accession_details[$url_column-1]);

	#print some information for debuggin purposes
	print "$genome_accession_details[$accession_column-1] = $genome_url[-1]\n" if $debug;

	#populate the hash with the accession number and genome url. Note that accession number are unique, so we do not need to check for uniqueness of the keys here!		
	$genome_folder_names{$genome_accession_details[$accession_column-1]}=$genome_url[-1];
}

#connect to ftp; Other options: Passive => 1, Debug => 0
print "Connecting to ftp server\n" if($verbose);

my $genome_store;

if($debug){
	$genome_store = Net::FTP->new($ftp, Debug=>1) or die "Cannot connect to ftp server: $ftp\n$@\n";
}else{
	$genome_store = Net::FTP->new($ftp, Debug=>0) or die "Cannot connect to ftp server: $ftp\n$@\n";
}

#log to the ftp as an anonymous user
print "Logging to ftp server\n" if($verbose);
$genome_store->login($ftp_user, $ftp_password);

#change to binary mode
$genome_store->binary();

#cd to directory containing the genomes
print "Changing to genome directory... this takes a while\n" if($verbose);
$genome_store->cwd($genomes_dir) or die "cannot cwd to $genomes_dir ", $genome_store->message;

#get the list of genome folders available
#print "Getting list of available genome folders\n";
#my @available_genomes = $genome_store->ls();
#my @available_genomes = $genome_store->dir();


#passive
#$genome_store->pasv();

#print CWD
print $CWD, "\n";

#open file handle with the genome list
open(GENOME_LIST, $list_file) or die "Cannot open the genome list file\n$!";

#read the first line
<GENOME_LIST>;

#for some stats
my $total_number_of_genomes = 0;
my $matching_genomes = 0;
my $downloaded_genomes = 0;

#try to download all the data for each genome in the genome list for the desired phylum and class
while(<GENOME_LIST>){#from line 2 onwards
	$total_number_of_genomes++;
	chomp;
	my $group_match = 0;
	my $subgroup_match = 1;
	my @genome_details = split(/\t/);

	#does this entry belong to the selected phylum?
	$group_match = 1 if($genome_details[$group_column-1] eq $group || $group eq "all");
	
	#does this entry belong to the selected class?
	$subgroup_match = 0 if(defined $subgroup && $genome_details[$subgroup_column-1] ne $subgroup);

	#print some info on the matching of the genomes
	if($subgroup_match && $verbose){
		print "Current genome in list ($genome_details[$assembly_accession-1]) belogns to subgroup: $genome_details[$subgroup_column-1], looking for $subgroup\n";
	}elsif($group_match && $verbose){
		print "Current genome in list ($genome_details[$assembly_accession-1]) belogns to group: $genome_details[$group_column-1], looking for $group\n";
	}


	if($group_match && $subgroup_match){
		$matching_genomes++;
		print "Looking for ", $genome_details[$assembly_accession-1], " among available genomes\n" if($verbose);

		#the name of the folder in the ftp is not the assembly accession only but has some more info in the name
		#we grep the accession number to get the folder name, because the accession is unique

		#need to change this to query the directly looks into a hash of Assembly_accession->url
		#my ($genome_to_download) = grep {$_ =~ $genome_details[$assembly_accession-1]} @available_genomes;

		my $genome_to_download = $genome_folder_names{$genome_details[$assembly_accession-1]};
		
		#name of the folder to download the data
		my $new_genome_folder = $output_folder . "/" . $genome_to_download if($verbose);

		print "attemping to download genome from $genome_to_download\n";
	
		if(defined $genome_to_download && !(-d $new_genome_folder)){#if we found a match and folder with this name is does not exist yet!

			print $genome_to_download, " matches the desired genome\n" if($verbose);
			
			#move to genome directory in ftp
			$genome_store->cwd($genome_to_download) or die "cannot cwd to $genome_to_download ", $genome_store->message;
#			$genome_store->passive();

			#get files to donwload somehow neither ls nor dir are working. They give me timeouts!
			my @files_to_download = $genome_store->dir() or warn $genome_store->message;
			
			print $#files_to_download, "\n";

			my ($faa_file) = grep {$_ =~ ".+\.faa\.gz"} @files_to_download;

			if(!$with_protein_annotations || $faa_file){

				print "Protein annotation file found: $faa_file\n" if($verbose && $with_protein_annotations);
				
				#make local directory to store files		
				print "Creating folder ", $genome_to_download, " in ", $output_folder, " to store the downloaded information\n" if($verbose);
				mkdir($new_genome_folder);

				#download the files.
				foreach my $file_to_download (@files_to_download){
					print "Changing current working directory to $output_folder/$genome_to_download to begin download\n";
					local $CWD = "$output_folder/$genome_to_download";
					my $download_status = $genome_store->get($file_to_download);
					if(defined $download_status){
						print "Downloading ", $file_to_download, " to ", $CWD, "\n" if($verbose);
						$downloaded_genomes++;
					}else{
						print "Failed downloading ", $file_to_download, " to ", $CWD, "\n" if($verbose);
					}
				}
			}else{
				print "Protein annotation file not found. Proceeding with next genome\n";
			}
			#go back to genome directory in ftp server
			$genome_store->cdup() or die "cannot cwd to parent directory ", $genome_store->message;
		}else{
			print $genome_details[$assembly_accession-1], " was not found or a folder with this name already exists in $output_folder\n" if($verbose);
		}
	}
}

print "Total number of genomes in genome file = $total_number_of_genomes
Total number of genomes matching search criterion = $matching_genomes
Number of downloaded genomes = $downloaded_genomes\n";

$genome_store->quit();
close(GENOME_LIST);
