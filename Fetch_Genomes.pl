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
################################################################

#command line options, the variable names should be self explanatory;
my $list_file;
my $verbose = "T";
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
my $with_protein_annotations = 0;

my $usage = "The following options have to be provided:
		--list_file = prokaryotes.csv file from NCBI; download at ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt and change .txt by .csv
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
		--verbose T
A normal command line would look like:
	perl Fetch_Genomes.pl -list_file ./prokaryotes.csv -group Cyanobacteria
	
Defining these options is required!

To download only genomes with protein annotations (i.e. *.faa exists):
	perl Fetch_Genomes.pl -list_file ./prokaryotes.csv -group Cyanobacteria --with_protein_annotations

A funky one (if I modify the prokaryotes.csv file...)
	perl Fetch_Genomes.pl -list_file ./prokaryotes.csv -group Cyanobacteria -group_column 10 -assembly 1 -out ~/my_genomes

The following groups can be used as search criteria:
				
				
				
The following subgroups can be used as search criteria:

				
				

";

my $help =  "This script should help you download a bunch of genomes from the NCBI ftp server.\nThe script expects a list of genomes to be downloaded, this list of genomes must provide the names of the folders where the genomes are stored in NCBI's ftp server. These folders are names after the \"Assembly Accession\".\n\nRun perl Fetch_Genomes.pl --usage to see a list of the different options you have".

#get options from command line
GetOptions("list_file=s" => \$list_file,
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
					 "verbose=s" => \$verbose,
 					 "with_protein_annotations" => \$with_protein_annotations,
					 "usage" => \$usage
					 )
or die("Error in the command line arguments\n$usage");



#check that some options are defined;
#die "\nERROR: A file defining the genomes to download must be provided through the --list_file option\n\n" unless defined $list_file;
die "\n$usage\n" unless defined $list_file && defined $group;

print("Starting with the following parameters:
		--list_file $list_file
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
		--with_protein_annotations $with_protein_annotations
		--verbose $verbose
");

#connect to ftp; Other options: Passive => 1, Debug => 0
print "Connecting to ftp server\n" if($verbose);
my $genome_store = Net::FTP->new($ftp) or die "Cannot connect to ftp server: $ftp\n$@\n";

#log to the ftp as an anonymous user
print "Logging to ftp server\n" if($verbose);
$genome_store->login($ftp_user, $ftp_password);

#change to binary mode
$genome_store->binary();

#cd to directory containing the genomes
print "Changing to genome directory... this takes a while\n" if($verbose);
$genome_store->cwd($genomes_dir) or die "cannot cwd to $genomes_dir ", $genome_store->message;

#get the list of genome folders available
my @available_genomes = $genome_store->ls();

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
	print "Current genome belogns to: $genome_details[$group_column-1], looking for $group\n" if($verbose);
	$group_match = 1 if($genome_details[$group_column-1] eq $group || $group eq "all");

	#does this entry belong to the selected class?
	print "Current genome belogns to: $genome_details[$subgroup_column-1], looking for $subgroup\n" if($verbose && defined $subgroup);
	$subgroup_match = 0 if(defined $subgroup && $genome_details[$subgroup_column-1] ne $subgroup);

	if($group_match && $subgroup_match){
		$matching_genomes++;
		print "Looking for ", $genome_details[$assembly_accession-1], " among available genomes\n" if($verbose);

		#the name of the folder in the ftp is not the assembly accession only but has some more info in the name
		#we grep the accession number to get the folder name, because the accession is unique
		my ($genome_to_download) = grep {$_ =~ $genome_details[$assembly_accession-1]} @available_genomes;
	
		#name of the folder to download the data
		my $new_genome_folder = $output_folder . "/" . $genome_to_download;
	
		if(defined $genome_to_download && !(-d $new_genome_folder)){#if we found a match and folder with this name is does not exist yet!

			print $genome_to_download, " matches the desired genome\n" if($verbose);
			
			#move to genome directory in ftp
			$genome_store->cwd($genome_to_download) or die "cannot cwd to $genome_to_download ", $genome_store->message;

			#get files to donwload
			my @files_to_download = $genome_store->ls();

			my ($faa_file) = grep {$_ =~ ".+\.faa\.gz"} @files_to_download;

			if(!$with_protein_annotations || $faa_file){

				print "Protein annotation file found: $faa_file\n" if($verbose && $with_protein_annotations);
				
				#make local directory to store files		
				print "Creating folder ", $genome_to_download, " in ", $output_folder, " to store the downloaded information\n" if($verbose);
				mkdir($new_genome_folder);

				#download the files.
				foreach my $file_to_download (@files_to_download){
					#print "Changing current working directory to $output_folder/$genome_to_download to begin download\n";
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