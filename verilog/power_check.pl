#!/usr/bin/perl -w
######################################################################################
### Copyright 
### This source file may be used and distributed without restriction 
### provided that this copyright statement is not removed from the file 
### and that any derivative work contains the original copyright notice 
### and the associated disclaimer. 
### 
### THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS 
### OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED 
### WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE. 
######################################################################################
### Created by Arthas Jie Xiao in 2015-09-07 
### contact author: celebraty2008@163.com
### 1. find register assignmetn without condition 
### 2. find 2D array
### 3. find multiplier
### 4. find initial block
######################################################################################

use Env;
use Getopt::Long;
use strict;


my $print_en          = 0;  #to print verbose log
my $folder_name       = "power_check";

my $log_all           = "$folder_name/all_always.v";
my $log_summary       = "$folder_name/summary.v";
my $log_file          = "$folder_name/power_check.v";
my $log_fatal         = "$folder_name/fatal.log";
my $log_all_mul       = "$folder_name/all_mul.log";
my $log_all_2d        = "$folder_name/all_2d.log";
my $log_all_init      = "$folder_name/all_init.log";



my $err_cnt_total     = 0;
my $err_cnt_rdl       = 0;
my $err_cnt_local     = 0;
my $err_cnt_per_file  = 0;
my $log_err           = 0;
my $fatal_exist       = 0;
my $array_2d_total    = 0; 
my $mul_cnt_total     = 0;
my $init_cnt_total    = 0;


my $usage =
qq/
Usage: power_check.pl -[help|h]            ------print help
       power_check.pl -[verbose|v]         ------print verbose log;
       power_check.pl -[file|f] <filelist> ------eg. power_check.pl -f vfiles_rtl
       power_check.pl -[dir|d]  <dir>      ------eg. power_check.pl -d . 
       power_check.pl -[bak|b]             ------eg. power_check.pl -b
       power_check.pl -[filter] <N>        ------eg. power_check.pl -filter [N]
       power_check.pl -[2d_array|2d]       ------eg. power_check.pl -2d
       power_check.pl -[initial|init]      ------eg. power_check.pl -init
       power_check.pl -[multiplier|mul]    ------eg. power_check.pl -mul
       power_check.pl <files>              ------eg. power_check.pl top.v
/;

#initial block is dangerous for Non-reset register, as its intial value is unknown and may synthesis off.
#Abusing 2D array register waste area and power.  
#Abusing multiplier waste area and power.


my $get_help;
my $get_verbose;
my $get_filelist;
my $get_dir;
my $get_filter  = 0;  #default 0
my $get_2d_array=0;
my $get_bak     =0;
my $get_init    =0;
my $get_mul     =0;

GetOptions( 'help'              => \$get_help,          # print help
            'h'                 => \$get_help,          # print help
            'verbose|v'         => \$get_verbose,       # enable full log
            'file|f=s'          => \$get_filelist,      # get filelist
            'dir|d=s'           => \$get_dir,           # get search directory
            'filter=s'          => \$get_filter,        # get filter number
            '2d_array|2d'       => \$get_2d_array,      # get 2d array info
            'bak|b'             => \$get_bak,           # get back up
            'initial|init'      => \$get_init,          # get intial block
            'multiplier|mul'    => \$get_mul,           # get multiplier 
            '<>'                => \&get_parameter      # get parameter
          ) ;




# check cmd-line params
&chkOpts;

#open log  files 
open(LOGFILE, ">$log_file") || die "Cannot open rtl power check file:$log_file\n";

system `rm $log_all -rf`;
open(ALLLOGFILE, ">$log_all") || die "Cannot open rtl power check file:$log_all\n";

system `rm $log_summary -rf`;
open(SUMMARY, ">$log_summary") || die "Cannot open rtl power check file:$log_summary\n";

system `rm $log_fatal -rf`;
open(FATALFILE, ">$log_fatal") || die "Cannot open rtl power check file:$log_fatal\n";

system `rm $log_all_mul -rf`;
if($get_mul) {
    open(ALLMULFILE, ">$log_all_mul") || die "Cannot open rtl power check file:$log_all_mul\n";
}

system `rm $log_all_2d -rf`;
if($get_2d_array) {
    open(ALL2DFILE, ">$log_all_2d") || die "Cannot open rtl power check file:$log_all_2d\n";
}

system `rm $log_all_init -rf`;
if($get_init) {
    open(ALLINITFILE, ">$log_all_init") || die "Cannot open rtl power check file:$log_all_init\n";
}

#read vfiles jxiao
&read_vfiles;

if($get_mul) {
    if($mul_cnt_total != 0 )  {
        print "Low power RTL checker find $mul_cnt_total Multiplier, please review $log_file for more info!\n";
        print SUMMARY "Total multiplier is $mul_cnt_total!\n";
    } else {
        print "Low power RTL checker find No Multiplier!\n";
        print SUMMARY "Total multiplier is $mul_cnt_total!\n";
    }
}

if($get_2d_array) {
    if($array_2d_total != 0 )  {
        print "Low power RTL checker find $array_2d_total 2D_array, please review $log_file for more info!\n";
        print SUMMARY "Total 2D_Array is $array_2d_total!\n";
    } else {
        print "Low power RTL checker find No 2D_Array!\n";
        print SUMMARY "Total 2D_Array is $array_2d_total!\n";
    }
}


if($get_init) {
    if($init_cnt_total != 0 )  {
        print "Low power RTL checker find $init_cnt_total initial block, please review $log_file for more info!\n";
        print SUMMARY "Total initial block is $init_cnt_total!\n";
    } else {
        print "Low power RTL checker find No initial block!\n";
        print SUMMARY "Total initial block is $init_cnt_total!\n";
    }
}

#report log
if($log_err) {
    if($err_cnt_rdl == 0) {
        print "Low power RTL checker find $err_cnt_total issue, please check $log_file for more info!\n";
        print SUMMARY "Total have $err_cnt_total issue!";
    }
    else {
        print "Low power RTL checker find $err_cnt_total issue, including RDL $err_cnt_rdl issue, local $err_cnt_local issue, please check $log_file for more info!\n";
        print SUMMARY "Total have $err_cnt_total issue, RDL $err_cnt_rdl issue, local $err_cnt_local issue!";
    }
} else {
    print "RTL Pass low power RTL check!\n";
    print SUMMARY "Total have 0 issue, RTL pass low power RTL check!";

}


close(LOGFILE);
close(ALLLOGFILE);
close(SUMMARY);
close(FATALFILE);

if($get_mul)      {close(ALLMULFILE);}
if($get_2d_array) {close(ALL2DFILE);}
if($get_init)     {close(ALLINITFILE);}

###################################################################################
#######Function
###################################################################################
#analyze input cmd
sub chkOpts
{
    die $usage if $get_help;
    
    if($get_verbose) { 
        print "[INFO]:Set Verbose Log \n";
        $print_en =1 
    };
    
    if($get_bak) {
        ################################################
        ##For local time bak 
        ###############################################
        my ( $sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst) = localtime();
        $year += 1900;
        $mon ++;
        my $data = "$year-$mon-$day $hour:$min";
        
        if(-d $folder_name) {
            #folder exist!;
            print "[INFO]:copy $folder_name to $folder_name$data\n";
            system `cp $folder_name "$folder_name$data" -rf `;
        }
            
    }

    if(-d $folder_name) {
        #if folder exist! 
    }
    else{

        system `mkdir $folder_name`;
    }

    if($get_dir) {
        if(-d $get_dir) {

            system `rm $folder_name/vfiles_power_check -rf`;
            print "[INFO]:Exec cmd \" find $get_dir -name \"\*\.v\" \" !\n";
            system `find $get_dir -name "*.v"  >>$folder_name/vfiles_power_check` ; #not using ">" to cover previous file
        }
        else {
           print "[ERROR]: Input directory $get_dir Does Not Exist ! \n";
           die "$usage";
       }
    
    }

    if($get_filelist) {
        if(-e $get_filelist) {
           if($get_filelist ne "$folder_name/vfiles_power_check"){
               system `rm $folder_name/vfiles_power_check -rf`;
               system `cat $get_filelist  >>$folder_name/vfiles_power_check `; 
           }
        }
        else {
            print "[ERROR]: Input file $get_filelist Does Not Exist ! \n";
            die "$usage";
        }
    }

    if($get_filter) {
        print "[INFO]:Filter Error if Register Bit Num is Not More Than  $get_filter ! \n";
    }

    

}

sub get_parameter
{
    my @parameter = shift(@_);
    my $item;
    foreach $item (@parameter) {
        if( $item !~ m/.*\.v/) {
            print "[ERROR]: Input file $get_dir Does Not .v file ! \n";
            die "$usage"; 
        }
    }

    if(-d $folder_name) {
        #if folder exist! 
    }
    else{
        system `mkdir $folder_name`;
    }

    open(TMP, ">tmp") || die "Cannot open rtl power check file:tmp\n";
    print TMP "@parameter\n";
    close TMP;
    system `cat tmp > $folder_name/vfiles_power_check` ;
    system `rm tmp -rf`;
}


sub read_vfiles 
{

    open (VFILE_LIST, "$folder_name/vfiles_power_check" );
    while(<VFILE_LIST>){
        my $vfile = $_;
        chomp ($vfile);
    
        if ($vfile !~ m/.*\.v/) {
            next;
        } 
        elsif ($vfile =~/\#/){
            # "#" used to comment out lines
            next;
        }
    
        my @dirs = split("\/", $vfile);
        my $file_name = $dirs[$#dirs];
        
        #filter reg.v and files from cad/bfm/fpga
        if($file_name !~ m/.*reg\.v/ && $vfile !~ m/\/cad\// && $vfile !~ m/\/bfm\// 
            && $vfile !~ m/\/fpga\// && $vfile !~ m/\/verification\// && $vfile !~ m/\/testbench\// 
            && $vfile !~ m/\/mini_mi_D/ && $vfile !~ m/\/power_check/){ 

            #remove reg.v and /cad/xxxx file
            print LOGFILE    "Checking $vfile!\n";
            print ALLLOGFILE "Checking $vfile!\n";
            if($get_mul) {
                print ALLMULFILE "Checking $vfile!\n";
            }
            if($get_2d_array) {
                print ALL2DFILE "Checking $vfile!\n";
            }
            if($get_init) {
                print ALLINITFILE "Checking $vfile!\n";
            }


            if($print_en) { print "[INFO]:Checking $vfile!\n"};
            
            #do RTL power check 
            $log_err = &power_check($vfile, $file_name) || $log_err;
    
            print SUMMARY "Checking $vfile have $err_cnt_per_file issue!\n";
        }
        else {
            print LOGFILE    "Not Check $vfile!\n";
            print SUMMARY    "Not Check $vfile!\n";
            print ALLLOGFILE "Not Check $vfile!\n";
            if($get_mul) {
                print ALLMULFILE "Not Check $vfile!\n";
            }
            if($get_2d_array) {
                print ALL2DFILE "Not Check $vfile!\n";
            }
            if($get_init) {
                print ALLINITFILE "Not Check $vfile!\n";
            }
            if($print_en) { print "[INFO]:Not Check $vfile!\n" } ;
        }
    }

    close(VFILE_LIST);
}

#Check RTL code that not easy for ICG insertion
sub power_check {

    my ($vfile, $file_name)   = @_;
    my $line_cnt              = 0; #line counter to trace error
    my $always_blk            = 0; #in always block, set 1, after always block end, set 0 
    my $if_blk                = 0; #0: else ; 1: first if hier
    my $always_begin          = 0; #if always start with "begin", should end with "end; 
    my $if_begin              = 0; #add one in "if begin" or "else if begin" 
    my $error_flag            = 0; #if 1, print always block 
    my $error_line            = 0; #if 1, print error line
    my $error_file            = 0; #if 1, print check log
    my $always_print          = 0; #temp print always block 
    my $initial_blk           = 0; #in initial block, set 1, after end, set 0


    my @hier                  = ([0,0,0,0]);#[if_en, if_or_else, if_begin, if_line];
    my @def_hier              = ([0,0]);    #[if_def_en, if or else]
    my @previous              = ();#previous hier info.

    my $hier_cnt              = 0;#hierarchy counter, counter from 0
    my $hier_add              = 0;#if hier_add set 1, means hier_cnt should add back
    my $comment               = 0;#to remove comments in multiple lines /* ....*/, 1 means comments
    my $line_num              = 0;#use for debug
    my $else_flag             = 0;#to remove comments in multiple lines /* ....*/, 1 means comments
    my $ifdef_cnt             = 0;#to remove comments in multiple lines /* ....*/, 1 means comments
   
    my %reg_hash              = (); 
    my $reg_name              = "";
    my $check_en              = 1 ;
    my $left_num              = 0 ;
    my $right_num             = 0 ;
    
    $fatal_exist              = 0;
    if(-e $vfile) {
        open(MYFILE, "$vfile") || die "can't open $vfile : $!";
    }
    $err_cnt_per_file = 0;
    while(<MYFILE>) {
        my $line = $_;
        chomp($line);
        
        $line_cnt = $line_cnt + 1; 
        $line =~ s/\r//g; #remove ^M, fix display issue
        $line =~ s/\t/    /g; #replase tab to  "    ", do not need to care [\s|\t], all can be " "
        my $line_org = $line; # reserve line original
        
        ##################################
        ####For auto indent
        ##################################
        my $line_len = length($line_org);
        my $space    = "";
        for(my $i = 0 ; $i <= (60 - $line_len); $i = $i+1) {
            $space = " ".$space;
        }

        if($line =~ /^ *reg *\[.*\].*\[.*\] *;/){
            if($get_2d_array) {
                $array_2d_total = $array_2d_total + 1;
                print LOGFILE    "$line_cnt : $line_org$space WARNING: 2D array***************Check if it can be replaced by hardmacro, or PIPE to FIFO!\n";   #print reg [xx:xx] aaaa[xx:xxx];
                print ALL2DFILE  "$line_cnt : $line_org$space WARNING: 2D array***************Check if it can be replaced by hardmacro, or PIPE to FIFO!\n";
            }
        }
        elsif($line =~ /^ *reg *(\[ *([^ ]+) *: *([^ ]+) *\]) *([^ ]+) *;/) {
            #reg [m:n] name;
            $reg_name                   = $4;
            $reg_hash{$reg_name}{left}  = $2;
            $reg_hash{$reg_name}{right} = $3; 
            if($2 =~ /[^\d]/ || $3 =~ /[^\d]/) {
                $reg_hash{$reg_name}{width} = 9999; #if can not detect width
            }
            else {
                $reg_hash{$reg_name}{width} = $2 - $3 + 1; 
            }
            $reg_hash{$reg_name}{check} = 1; #need check
            #print " $line : $reg_hash{$reg_name}{left}  ,  $reg_hash{$reg_name}{right} \n";
        }
        elsif ($line =~ /^ *reg *([^ ]+) *;/) {
            #reg name;
            $reg_name                   = $1;
            $reg_hash{$reg_name}{left}  = 0;
            $reg_hash{$reg_name}{right} = 0; 
            $reg_hash{$reg_name}{width} = 1; 
            $reg_hash{$reg_name}{check} = 1; #need check
        }
            
            
        
        if($line=~m/\/\*.*\*\//) {   #remove /* xxxxx */
            $line =~s/\/\*(.*?)\*\///g;
        }

        if($line =~m/^ *\/\//){  
            #match "//" from begining
            $always_print = "$always_print$line_cnt : $line_org\n";
            $line_num = __LINE__;
            if($always_blk ==1 && $print_en == 1) {
                print "$line_cnt : $line_org$space//--------> \$line_num = $line_num,commented skipping !\n";
            }
            next;
        }
        else {
            #match "//" in line
            $line =~s/\/\/.*//g; 
        }
      
        #for ifdef  
        if($line =~ m/^ *`else/) {
            $else_flag = 1
        }
        elsif($line =~ m/^ *`(ifdef|ifndef)/) {
            $ifdef_cnt = $ifdef_cnt + 1; 
        }
        elsif($line =~ m/^ *`endif/) {
            $ifdef_cnt = $ifdef_cnt -1; 
            if($ifdef_cnt==0){
                $else_flag = 0;
             }
        } 
     
        #print "$line_cnt : $line_org$space//--------> \$ifdef_cnt = $ifdef_cnt, \$else_flag = $else_flag!\n";
        if($else_flag == 1 ) {
            #define block
            $always_print = "$always_print$line_cnt : $line_org\n";
            $line_num = __LINE__;
            if($always_blk ==1 && $print_en == 1) {
                print "$line_cnt : $line_org$space//--------> \$line_num=$line_num,commented skipping !\n";
            }
            next;
        }
        elsif($line=~m/\*\// && $comment) {
            #match "*/" to end "/*" comments
            $always_print = "$always_print$line_cnt : $line_org\n";
            $comment = 0;
            $line_num = __LINE__;
            if($always_blk ==1 && $print_en == 1) {
                print "$line_cnt : $line_org$space//--------> \$line_num=$line_num,commented skipping !\n";
            }
            next;
        }
        elsif($comment) {
            #pass comments
            $always_print = "$always_print$line_cnt : $line_org\n";
            $line_num = __LINE__;
            if($always_blk ==1 && $print_en == 1) {
                print "$line_cnt : $line_org$space//--------> \$line_num=$line_num,commented skipping !\n";
            }
            next;
        }
        elsif($line=~m/\/\*/) {
            #mach "/*"
            $always_print = "$always_print$line_cnt : $line_org\n";
            $comment = 1;
            $line_num = __LINE__;
            if($always_blk ==1 && $print_en == 1) {
                print "$line_cnt : $line_org$space//--------> \$line_num=$line_num,commented skipping !\n";
            }
            next;
        }
        else {
            if($get_mul) {
                #-------------------Mul Check-------------------------
                my $mul_flag =0;
                my $line_mul = $line;
                my $line_mul1; 
                my $line_mul2; 
                if($line_mul !~ /\*/) {         #without "*"

                } else {                        #only check line with "*";
                    while($line_mul =~ s/(.*)\[.*\](.*)/$1$2/g){
                        #remove multiple [x*xx : x*xx] 
                    } ;    

                    if($line_mul =~ m/always *\@ *\( *\* *\)/) { #always @(*)
                        $line_num           = __LINE__;
                    } elsif ($line_mul =~ /-?\d*\'(h|d|o|b)[\dabcdef]+\s*\*|\* *-?\d*\'(h|d|o|b)[\dabcdef]+/i )  { # 2'h3 * () or () * 2'h3
                        $line_num           = __LINE__;
                    } elsif ($line_mul =~ /(\w+) *\* *(\w+)/) { 
                        $line_mul1 = $1;
                        $line_mul2 = $2;
                        if($line_mul1 !~/\D/ | $line_mul2 !~ /\D/) {   #2 * () or () * 2;
                            $line_num           = __LINE__;
                        } else {                                       #add_1 * () 
                            $line_num           = __LINE__;
                            $mul_flag = 1;
                        }
                    } elsif ($line_mul =~ /\*/)  {
                        $line_num           = __LINE__;
                        $mul_flag = 1;
                    }
                    if($print_en) {
                        print "$line_cnt : $line_org$space//-------> \$line_num=$line_num, \$line_mul=$line_mul, \$mul_flag=$mul_flag\n";
                    }

                    if($mul_flag) {
                        $mul_cnt_total = $mul_cnt_total  + 1;
                        print LOGFILE    "$line_cnt : $line_org$space WARNING: Multiplier***************Check if needed or can be shared!\n";   
                        print ALLMULFILE "$line_cnt : $line_org$space WARNING: Multiplier***************Check if needed or can be shared!\n";
                    } else {
                        print ALLMULFILE "$line_cnt : $line_org\n";
                    }
                }
                #-------------------Mul Check-------------------------
            }

            if($line =~m/^ *(endmodule|endtask|endfunction)/){           
                #endmodule or endtask or endfunction
                $line_num = __LINE__;
                if($always_blk == 1) { #has always 
                    if($print_en == 1) {
                         print "$line_cnt : $line_org$space//-------> \$line_num=$line_num,print previous always block!\n";
                    }
                    print ALLLOGFILE "$always_print";
                    $always_print =""; #clear $always_print
                }
                #clear 
                $always_blk = 0;
                $always_begin =0;
                $error_flag   =0;
                $error_line   =0;
                $hier_cnt     =0;
                $if_begin     =0;
                next;
            }
            elsif($line =~m/^ *always *\@ *\( *(posedge|negedge).*\)/) {
                #alwasy @ ( posedge clk or negedge reset_n) //match always block 
                $line_num = __LINE__;
                if($always_blk == 1) { #has always 
                    #if($print_en == 1) {
                    #     print "$line_cnt : $line_org$space//-------> \$line_num=$line_num,print previous always block!\n";
                    #}
                    print ALLLOGFILE "$always_print";
                    $always_print =""; #clear $always_print
                }
                $always_blk   =1;
                $always_begin =0;
                $error_flag   =0;
                $error_line   =0;
                $hier_cnt     =0;
                $if_begin     =0;
                @hier         = ([0,0,0,0]);
                @previous     = (0,0,0,0,0);
                if($line =~m/^ *always *\@ *\( *[posedge|negedge].*\) *begin/) {
                    #alway block with begin
                    $always_begin =1;
                }

                if($print_en) { print "$line_cnt : $line_org$space//-------> \$line_num=$line_num, \$always_blk = $always_blk, \$always_begin = $always_begin \n" } ;
                $always_print = "$line_cnt : $line_org\n"; #initial always block print
                next;
            }
            elsif($line =~ m/^ *(initial|wire[ []|assign |reg[ []|always *\@ *\(|\..*\()/){
                #initial / wire / assign
                #always (*
                #.xxx ( xxxx),
                $line_num = __LINE__;
                if($always_blk == 1) { #has always 
                    if($print_en == 1) {
                         print "$line_cnt : $line_org$space//-------> \$line_num=$line_num,print previous always block!\n";
                    }
                    print ALLLOGFILE "$always_print";
                    $always_print =""; #clear $always_print
                }
                #clear 
                $always_blk   =0;
                $always_begin =0;
                $error_flag   =0;
                $error_line   =0;
                $hier_cnt     =0;
                $if_begin     =0;
                
                #handle intial block print
                if($get_init & $line =~ /^ *initial |^ *initial$/ ) {
                    $line_num = __LINE__;
                    $initial_blk =1; 
                    $init_cnt_total = $init_cnt_total + 1;
                    print LOGFILE     "$line_cnt : $line_org$space ERROR: Initial***************Make sure no register initialization!\n";   #print initial
                    print ALLINITFILE "$line_cnt : $line_org$space ERROR: Initial***************Make sure no register initialization!\n";
                    if($print_en == 1) {
                         print "$line_cnt : $line_org$space//-------> \$line_num=$line_num, print initial block start!\n";
                    }
                } 
                next
            }
            elsif($initial_blk==1){
                print LOGFILE "$line_cnt : $line_org\n";   #print initial
                print ALLLOGFILE "$line_cnt : $line_org\n";
                if($line =~/^ *end *$/) {
                    $initial_blk = 0;
                    $line_num = __LINE__;
                    if($print_en == 1) {
                         print "$line_cnt : $line_org$space//-------> \$line_num=$line_num, print initial block end!\n";
                    }
                } else {
                    $line_num = __LINE__;
                    if($print_en == 1) {
                         print "$line_cnt : $line_org$space//-------> \$line_num=$line_num, print initial block body!\n";
                    }
                }
            }
            elsif($always_blk==1 && $always_begin== 0 && $hier_cnt==0  && $line =~ m/^ *begin/){
                #always@(posedge clk)
                #    begin     //match this "begin"
                $line_num     = __LINE__;
                $always_begin = 1;
                $always_print = "$always_print$line_cnt : $line_org\n";
                if($print_en) { print "$line_cnt : $line_org$space//-------> \$line_num=$line_num, \$always_blk = $always_blk, \$always_begin = $always_begin \n" } ;
                next;
            }
            elsif($always_blk == 1 ) { 
                #in always block
                if($print_en) { print "$line_cnt : $line_org" } ;

                $always_print = "$always_print$line_cnt : $line_org";
                $hier_add     =0;  #has only valid for one line

                if($line =~ m/^ *begin *if.*\) *begin/) {                       # begin if () begin
                    $line_num        = __LINE__;
                    $if_begin        = $if_begin + 2;
                    $hier[$hier_cnt][2] = 1;       #add begin for previous hier  
                    $hier_cnt        = $hier_cnt + 1;
                    $hier[$hier_cnt] = [(1,1,1,0)];#if_en=1, if_else=1, if_begin=1, if_line=0; if_line used when if_begin==0
                    @previous        =  (1,1,1,0,$hier_cnt); 
                }
                elsif($line =~ m/^ *begin *if.*\)/) {                       # begin if () 
                    $line_num        = __LINE__;
                    $if_begin        = $if_begin + 1;
                    $hier[$hier_cnt][2] = 1;       #add begin for previous hier  
                    $hier_cnt        = $hier_cnt + 1;
                    $hier[$hier_cnt] = [(1,1,0,0)];#if_en=1, if_else=1, if_begin=1, if_line=0; if_line used when if_begin==0
                    @previous        =  (1,1,0,0,$hier_cnt); 
                }
                elsif($line =~ m/^ *if.*\) *begin/) {                         # if () begin
                    $line_num        = __LINE__;
                    $if_begin        = $if_begin + 1;
                    $hier_cnt        = $hier_cnt + 1;
                    $hier[$hier_cnt] = [(1,1,1,0)]; #if_en=1, if_else=1, if_begin=1, if_line=0; if_line used when if_begin==0
                    @previous        =  (1,1,1,0,$hier_cnt); 
                }
                elsif ($line =~ m/^ *else *if.*\) *begin/){                   # else if () begin, no end
                    $line_num        = __LINE__;
                    $if_begin = $if_begin + 1; #no end, so begin add 1;
                    if($previous[2] == 1 || $previous[3] == 1 ) {                   # if-else with begin, or has one line 
                        #if (xxx)                       #if(xxx)
                        #   q<= d;                      #
                        #else if(xxx) //hier_cnt++      #else if(xxx)   //hier_cnt do not need ++
                        $hier_cnt = $hier_cnt +1 ;                                  
                    }
                    $hier[$hier_cnt] = [(1,1,1,0)];
                    @previous        =  (1,1,1,0,$hier_cnt);
                }
                elsif($line =~ m/^ *(else)* *if *\(.*\).*<=.*;/){             # if () , no begin, but with Q<=d assignment
                    # if(xxx) Q<= D;
                    $line_num          = __LINE__;
                    $hier[$hier_cnt+1] = [(1,1,0,1)];
                    @previous          =  (0,0,0,1,$hier_cnt); 
                    $previous[0]       = 0; #out of if block
                    $previous[3]       = 1; #with one line in if_no_begin block 
                    $hier_add          = 1; #add back
                }
                elsif($line =~ m/^ *else *if *\(/){                          # else if () , no begin, no end
                    $line_num          = __LINE__;
                    if($previous[2] == 1 || $previous[3] == 1 ) {                  # if-else with begin, or has one line  
                        $hier_cnt = $hier_cnt +1 ;
                    }
                    $hier[$hier_cnt] = [(1,1,0,0)]; #no begin
                    @previous        =  (1,1,0,0,$hier_cnt); 
                }
                elsif($line =~ m/^ *if *\(/){                                # if () , no begin
                    $line_num        = __LINE__;
                    $hier_cnt        = $hier_cnt + 1;
                    $hier[$hier_cnt] = [(1,1,0,0)];
                    @previous        =  (1,1,0,0,$hier_cnt); 
                }
                elsif($line =~ m/^ *end *else *if.*\) *begin/){             # end else if () begin
                    $line_num        = __LINE__;
                    #previou is also [1,1,1,0, $hier_cnt], so keep
                }
                elsif($line =~ m/^ *end *else *if.*\)/){                    # end else if (), no begin 
                    $line_num        = __LINE__;
                    #previou is also [1,1,1,0, $hier_cnt], so keep
                    $if_begin        = $if_begin - 1;
                    $hier[$hier_cnt][2] = 0; #no begin
                    $previous[2] =0;  
                }
                elsif($line =~ m/^ *end *else *begin/){                     # end else begin
                    #change if-else = 0 for else
                    $line_num        = __LINE__;
                    $hier[$hier_cnt] = [(1,0,1,0)]; 
                    @previous        =  (1,0,1,0,$hier_cnt);          
                }
                elsif ($line =~ m/^ *else.*begin/){                         # else begin, no end
                    $line_num        = __LINE__;
                    $if_begin        = $if_begin + 1;
                    if($previous[2] == 1 || $previous[3] == 1 ) {
                        $hier_cnt = $hier_cnt +1 ;
                    }
                    $hier[$hier_cnt] = [(1,0,1,0)];
                    @previous        =  (1,0,1,0,$hier_cnt);
                }
                elsif ($line =~ m/^ *begin/){                               # only begin
                    $line_num           = __LINE__;
                    $if_begin           = $if_begin + 1;
                    $hier[$hier_cnt][2] = $hier[$hier_cnt][2]+1 ;          #add begin
                    $previous[2]        = 1 ;
                }
                elsif ($line =~ m/^ *else/){                                # else, no begin, no end
                    $line_num           = __LINE__;
                    if($previous[2] == 1 || $previous[3] == 1 ) {
                        $hier_cnt = $hier_cnt +1 ;
                    }
                    $hier[$hier_cnt] = [(1,0,0,0)];
                    @previous        =  (1,0,0,0,$hier_cnt);
                    if ( $line =~ /^ *else *case[xz]? *\(/){
                        $line_num           = __LINE__;
                        $hier_cnt = $hier_cnt +1 ;
                        $hier[$hier_cnt] = [(1,0,1,0)];
                        @previous        =  (1,0,1,0,$hier_cnt);
                    }
                    
                }
                elsif($line =~ m/^ *for *\(.*\) *begin/ ){                  # "for" begin  
                    $line_num           = __LINE__;
                    $hier_cnt           = $hier_cnt + 1;
                    $if_begin           = $if_begin + 1;                   #add begin
                    $hier[$hier_cnt][0] = $hier[$hier_cnt-1][0]; #keep if_en
                    $hier[$hier_cnt][1] = $hier[$hier_cnt-1][1]; #keep if_else
                    $hier[$hier_cnt][2] = 1; #add begin
                    $hier[$hier_cnt][3] = 0;
                    $previous[0]        = $hier[$hier_cnt][0];
                    $previous[1]        = $hier[$hier_cnt][1];
                    $previous[2]        = 1 ;
                    $previous[3]        = 0 ;
                    $previous[4]        = $line_cnt ;
                }
                elsif($line =~ m/^ *for *\(.*\)/ ){                         # for, no begin
                    $line_num           = __LINE__;
                    $hier_cnt = $hier_cnt + 1;
                    $hier[$hier_cnt][0] = $hier[$hier_cnt-1][0]; #keep if_en
                    $hier[$hier_cnt][1] = $hier[$hier_cnt-1][1]; #keep if_else
                    $hier[$hier_cnt][2] = 0; #don't add begin
                    $hier[$hier_cnt][3] = 0;
                    $previous[0]        = $hier[$hier_cnt][0];
                    $previous[1]        = $hier[$hier_cnt][1];
                    $previous[2]        = 0 ;
                    $previous[3]        = 0 ;
                    $previous[4]        = $line_cnt ;
                }
                elsif($line =~ m/^ *case[xz]? *\(.*\)/ ){                   #for case, casex, casez
                    $line_num           = __LINE__;
                    $hier_cnt = $hier_cnt + 1;
                    $hier[$hier_cnt][0] = 1; #same as if_en
                    $hier[$hier_cnt][1] = 0; #regard it as "else"
                    $hier[$hier_cnt][2] = 1; #regard it has "begin"
                    $hier[$hier_cnt][3] = 0;
                    $previous[0]        = 1;
                    $previous[1]        = 0;
                    $previous[2]        = 1 ;
                    $previous[3]        = 0 ;
                    $previous[4]        = $line_cnt ;
                }
                elsif($line =~m/^ *default *: *begin/){                      #case  default branch with begin
                    $line_num        = __LINE__;
                    $if_begin        = $if_begin + 1;
                    if($previous[2] == 1 || $previous[3] == 1 ) {            # if-else with begin, or has one line 
                        $hier_cnt = $hier_cnt + 1;
                    }
                    $hier[$hier_cnt] = [(1,0,1,0)];
                    @previous        =  (1,0,1,0,$hier_cnt);
                }
                elsif($line =~m/^ *default *:/){                            #case  default branch without begin
                    $line_num           = __LINE__;
                    if($previous[2] == 1 || $previous[3] == 1 ) {           # if-else with begin, or has one line 
                        $hier_cnt = $hier_cnt + 1;
                    }
                    $hier[$hier_cnt] = [(1,0,0,0)];
                    @previous        =  (1,0,0,0,$hier_cnt);
                    if($line =~ /.*: *if *\(.*\) *begin/) {                    #with begin
                        $hier_cnt = $hier_cnt + 1;
                        $hier[$hier_cnt] = [(1,1,1,0)];                     
                        @previous        =  (1,1,1,0,$hier_cnt);
                    } 
                    elsif($line =~ /.*: *if *\(/){                             #without begin
                        $hier_cnt = $hier_cnt + 1;
                        $hier[$hier_cnt] = [(1,1,0,0)];                    
                        @previous        =  (1,1,0,0,$hier_cnt);
                    }
                }
                elsif($line =~m/^ *(([\w']+)|(\w+(\[\w+\])?)|(`\w+)) *: *begin/){      #case other branch with begin as AAAA,2'b00,3'd7,4'hf, `DEF
                    $line_num        = __LINE__;
                    $if_begin        = $if_begin + 1;
                    if($previous[2] == 1 || $previous[3] == 1 ) {           # if-else with begin, or has one line 
                        $hier_cnt = $hier_cnt + 1;
                    }
                    $hier[$hier_cnt] = [(1,1,1,0)];
                    @previous        =  (1,1,1,0,$hier_cnt);
                }
                elsif($line =~m/^.*, *(([\w']+)|(\w+(\[\w+\])?)|(`\w+)) *: *begin/){      #case other branch with begin as "," AAAA,2'b00,3'd7,4'hf, `DEF
                    $line_num        = __LINE__;
                    $if_begin        = $if_begin + 1;
                    if($previous[2] == 1 || $previous[3] == 1 ) {           # if-else with begin, or has one line 
                        $hier_cnt = $hier_cnt + 1;
                    }
                    $hier[$hier_cnt] = [(1,1,1,0)];
                    @previous        =  (1,1,1,0,$hier_cnt);
                }
                elsif($line =~m/^ *(([\w']+)|(\w+(\[\w+\])?)|(`\w+)) *:/){          #case other branch without begin  2'b00
                    $line_num        = __LINE__;
                    if($previous[2] == 1 || $previous[3] == 1 ) {           # if-else with begin, or has one line 
                        $hier_cnt = $hier_cnt + 1;
                    }
                    $hier[$hier_cnt] = [(1,1,0,0)];
                    @previous        =  (1,1,0,0,$hier_cnt);
                    if($line =~ /.*: *if *\(.*\) *begin/) {                    #with begin
                        $line_num        = __LINE__;
                        $hier_cnt = $hier_cnt + 1;
                        $hier[$hier_cnt] = [(1,1,1,0)];                      
                        @previous        =  (1,1,1,0,$hier_cnt);
                    } 
                    elsif($line =~ /.*: *if *\(/){                             #without begin
                        $line_num        = __LINE__;
                        $hier_cnt = $hier_cnt + 1;
                        $hier[$hier_cnt] = [(1,1,0,0)];                      
                        @previous        =  (1,1,0,0,$hier_cnt);
                    }
                    elsif($line =~/.*: *case[xz]? *\(/){                        #xxxx : case
                        $line_num        = __LINE__;
                        $hier_cnt = $hier_cnt + 1;
                        $hier[$hier_cnt] = [(1,1,1,0)];                      
                        @previous        =  (1,1,1,0,$hier_cnt);
                    }
                }
                elsif($line =~m/^.*, *(([\w']+)|(\w+(\[\w+\])?)|(`\w+)) *:/){          #case other branch without begin  2'b00
                    $line_num        = __LINE__;
                    if($previous[2] == 1 || $previous[3] == 1 ) {           # if-else with begin, or has one line 
                        $hier_cnt = $hier_cnt + 1;
                    }
                    $hier[$hier_cnt] = [(1,1,0,0)];
                    @previous        =  (1,1,0,0,$hier_cnt);
                    if($line =~ /.*: *if *\(.*\) *begin/) {                    #with begin
                        $line_num        = __LINE__;
                        $hier_cnt = $hier_cnt + 1;
                        $hier[$hier_cnt] = [(1,1,1,0)];                      
                        @previous        =  (1,1,1,0,$hier_cnt);
                    } 
                    elsif($line =~ /.*: *if *\(/){                             #without begin
                        $line_num        = __LINE__;
                        $hier_cnt = $hier_cnt + 1;
                        $hier[$hier_cnt] = [(1,1,0,0)];                      
                        @previous        =  (1,1,0,0,$hier_cnt);
                    }
                    elsif($line =~/.*: *case[xz]? *\(/){                        # xxxx: case 
                        $line_num        = __LINE__;
                        $hier_cnt = $hier_cnt + 1;
                        $hier[$hier_cnt] = [(1,1,1,0)];                      
                        @previous        =  (1,1,1,0,$hier_cnt);
                    }
                }
                elsif($always_begin == 1 && $if_begin == 0  && $line =~ m/^ *end/ && $line !~m/^ *end.*<=/) {        #always begin end, if_begin cnt inside =0;
                    $line_num           = __LINE__;
                    $always_begin       = 0;
                    $always_blk         = 0;
                    if($error_flag == 1) {  #check error flag
                        print LOGFILE "$always_print\n";
                    }
                    print ALLLOGFILE "$always_print\n";
                    $always_print =""; #clear $always_print
                }
                elsif($line =~ m/^ *endcase/) {                                    #end in word as end_xxx
                    if($previous[2]==1 || $previous[3]==1) {                       # xxx:begin 
                        $line_num           = __LINE__;
                        $hier_cnt = $hier_cnt -1 ;                                 #    A <= B;
                    }                                                              #end  //this end has minus one
                    else {
                        $line_num           = __LINE__;
                        $hier_cnt = $hier_cnt -2 ;                                 # to fix hier_cnt error if as XXX: A<=B;
                    } 
                    $previous[0] = $hier[$hier_cnt][0];                              #roll back previous
                    $previous[1] = $hier[$hier_cnt][1];                              #roll back previous
                    $previous[2] = $hier[$hier_cnt][2];                              #roll back previous
                    $previous[3] = $hier[$hier_cnt][3];                              #roll back previous
                    
                }
                elsif($line =~ m/^ *end\w+/) {                                    #end in word as end_xxx
                    $line_num           = __LINE__;
                }
                elsif($always_begin == 0 && ($if_begin == 0 || ($if_begin==1 && $line =~ m/^ *end/)) && $error_flag == 1 ){
                    #always block end
                    $always_blk         = 0;
                    if($if_begin == 0) {
                        $line_num           = __LINE__;
                        #DO not minus $hier_cnt
                    } 
                    else {
                        $line_num           = __LINE__;
                        $hier_cnt           = $hier_cnt -1 ;
                    }
                    print LOGFILE    "$always_print\n";
                    print ALLLOGFILE "$always_print\n";
                    $always_print =""; #clear $always_print
                    
                }
                elsif($line =~ m/^ *end/) {                                    #end, only end in one line
                    
                    if($hier_cnt == 0 && $hier[$hier_cnt][2]>=1 || $hier[$hier_cnt][2] >=2) {       #for "begin end without if/else
                        $line_num           = __LINE__;
                        $hier[$hier_cnt][2] = $hier[$hier_cnt][2] -1;
                    } 
                    else {  
                        $line_num           = __LINE__;
                        $hier_cnt           = $hier_cnt -1 ; 
                        if($hier[$hier_cnt][2]==0 && $hier_cnt!=0) {                               #-end high 1 hier without begin-end, hier back one more
                            $hier_cnt           = $hier_cnt -1 ; 
                        }
                    }
                    $if_begin           = $if_begin - 1;
                }
                elsif($line =~ m/[()&>!|~*%=]+.*<= / && $previous[0]==1 && $previous[2]==0 ) { 
                    #for complicated condition in "if/else if"
                    $line_num           = __LINE__;
                }
                elsif($line =~ m/(\w)+ *<= / && $previous[0]==1 && $previous[2]==0 ) {
                    #if (xxx) 
                    #    q<= d;  //hier_cnt--; but when check if need to print, hier_cnt should add back
                    $line_num           = __LINE__;
                    $hier_cnt           = $hier_cnt -1 ;
                    $previous[0]        = 0; #out of if block
                    $previous[3]        = 1; #with one line in if_no_begin block 
                    $hier_add           = 1; #add back
                        
                }
                elsif($line =~ m/.*\) *begin/) {     #for if (xxxxxxxxxx
                                                    #        xxxxxx) begin
                    $line_num        = __LINE__;
                    $if_begin        = $if_begin + 1;
                    $hier[$hier_cnt] = [(1,1,1,0)];                      
                    @previous        =  (1,1,1,0,$hier_cnt);
                }
                else{
                    $line_num           = __LINE__;
                }

                if($print_en) {
                    print "$space//-------> \$line_num=$line_num, \$hier_cnt=$hier_cnt ,\$always_blk = $always_blk, \$always_begin = $always_begin,\$hier\[\$hier_cnt\] = $hier[$hier_cnt][2] ";
                    if($hier_cnt < 0){
                        
                        print "[FATAL]: $vfile,force \$hier_cnt 0 ";
                        $hier_cnt = 0;
                        $fatal_exist= 1;
                    }
                } 

                $if_blk = 0;
                for( my $i =1; $i <= ($hier_cnt+$hier_add) ; $i=$i+1) {
                    if($hier[$i][1] == 1 ) {
                        $if_blk = 1;
                    }
                }    



                #Check regisger assignment
                #if($if_blk== 0){
                    if( $line =~ m/ *(if|for|case|casex|casez) *\(.*<=.*\)/){
                        #condition as if(a<=b)
                    }
                    elsif( $line=~ m/([^ ]+) *<= *(#[^ ])? *([^ ;]*) */){
                        if($print_en) {print ",\$left=$1,\$right=$3, "} ;
                            $check_en = 1;

                        if( exists($reg_hash{$1}{width}))  {
                            if($reg_hash{$1}{width} <= $get_filter) {
                                #if width <= N or if there is "Q<= Q" above
                                $check_en  = 0;
                            }
                            $left_num  = $reg_hash{$1}{left};
                            $right_num = $reg_hash{$1}{right};
                        }


                        if( $1 ne $3 && $check_en) {
                        }
                        elsif( $line=~ m/([^ ]+) *<= *(#[^ ])? *([^ ;]*) *([^ ;]*)/ && $check_en ){  #for A<= #1 A + 1;
                            if($4 ne "") {
                                if($print_en) {print "\$4=$4,"};
                            } else {
                                $reg_hash{$1}{check} = 0;  #remove check
                            }
                        }

                        if($if_blk == 0) { 
                            $error_line = 1;
                            if(exists($reg_hash{$1}{check})) {
                                if($reg_hash{$1}{check} == 0) { 
                                    $error_line = 0;
                                    if($print_en) {print "modify error_flag, "};

                                }
                            } 

                            if($error_line == 1) {
                                $error_flag = 1;
                                $error_file = 1; 
                                $err_cnt_total  = $err_cnt_total + 1;
                                $err_cnt_per_file = $err_cnt_per_file + 1;
                                if (exists($reg_hash{$1}{width})) {
                                    $always_print = "$always_print$space ERROR: $1\[$left_num:$right_num\]***************should add assignment condition for power saving!"
                                }
                                else {
                                    $always_print = "$always_print$space ERROR: $1***************should add assignment condition for power saving!"
                                }
                            }
                        }

                    }
                    #else {
                    #    if($print_en) { print "Script can not handle!" };
                    #}
                #}
                if($print_en) {print "\$if_blk = $if_blk, \$if_begin = $if_begin, \$error_flag=$error_flag\n" } ;
               
                $always_print = "$always_print \n";
                

            }
        }
            
    }     
    if($fatal_exist) {
        print FATALFILE "$vfile\n"
    }
    
    if ($vfile =~ m/\/rdl\//){
        $err_cnt_rdl = $err_cnt_rdl + $err_cnt_per_file;
    }
    else {
        $err_cnt_local = $err_cnt_local + $err_cnt_per_file;
    }
    return $error_file;
}


