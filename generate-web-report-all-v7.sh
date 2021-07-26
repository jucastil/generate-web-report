#!/bin/bash

#################################################################
#	  generate-web-report : it creates a web report after the logs
### NOTE: it is customized for "SB" storage ####
#	  created by : Juan
#	  created : Wed Oct 28 10:55:43 CET 2020
# 	last mod: Mon Jul 26 11:12:57 CEST 2021
################################################################

DATE=`date +%Y-%m-%d`

USERTEMP="/root/help/temp.txt"
USERLIST="/root/help/user_list.txt"
USEREXCLUDE="/root/help/user_exclude.txt"

### original log files - we mine from here
SBDATA_Q="/root/help/data-"$DATE.log
SBHOME_Q="/root/help/home-"$DATE.log
### take always yesterday's log
SBDATA_O=`ls -Art /root/logs/data* | tail -n2 | head -1`
SBHOME_O=`ls -Art /root/logs/home* | tail -n2 | head -1`

### main results
RAWREPORT="/root/help/"$DATE-raw.log
WEB_INDEX="/root/help/index-"$DATE".html"

### sbdata web bubbles
SBDATAINPUT=$RAWREPORT
SBDATALIST="/root/help/sbdata_points.txt"
SBDATAHEADER="/root/help/sbdata_header.txt"
SBDATATAIL="/root/help/sbdata_tail.txt"
WEB_SBDATA="/root/help/sbdata_bubbles-"$DATE.php
### sbhome web bubbles
HOMEINPUT=$RAWREPORT
HOMELIST="/root/help/home_points.txt"
HOMEHEADER="/root/help/home_header.txt"
HOMETAIL="/root/help/home_tail.txt"
WEB_SBHOME="/root/help/home_bubbles-"$DATE.php
### LOCAL web bubbles
LOCALHEADER="/root/help/local_header.txt"
LOCALMIDDLE="/root/help/local_middle.txt"
LOCALTAIL="/root/help/local_tail.txt"
WEB_LOCAL="/root/help/local_bubbles-"$DATE.php

function generate_local_bubbles(){
	
	### create a php file with both plots
	### build the php file
	cp $LOCALHEADER $WEB_LOCAL
	### add home cloud data	
	cat $HOMELIST >> $WEB_LOCAL
	### add the middle part
	cat $LOCALMIDDLE >> $WEB_LOCAL
	### add sbdata 
	cat $SBDATALIST >> $WEB_LOCAL
	### add the end
	cat $LOCALTAIL >> $WEB_LOCAL
	
	### change the line with date (not OK on OSX)
	DATELINE=`grep -n "<h2>" $WEB_LOCAL | cut -d : -f 1`
	sed -i "${DATELINE}s/.*/\<h2\>`date +%Y-%m-%d-%H:%M`\<\/h2\>/" $WEB_LOCAL
}

function generate_home_bubbles(){

   	### CSV readout, dumpt in file only if value not empty
	while read y
	do
    		#echo "Line contents are : $y "
    		echo $y | awk -F "," '{ if ( $9 =="" || $10 == "" || $13 == "" ) print "Some score for the student ",$2,"is missing " $9" "$10" "$13; else print " \{ x:" $9 ", y:" $10 ", z:" $13 ", name: \"" $2"\"\}," }' 2>/dev/null
	done < $HOMEINPUT > $HOMELIST
	## Clean the output
	sed -i  '/Some score/d' $HOMELIST
	### build the php file
	cp $HOMEHEADER $WEB_SBHOME
	while read z
	do
    		echo $z
	done < $HOMELIST >> $WEB_SBHOME
	### add the end of the php file
	cat $HOMETAIL >> $WEB_SBHOME

	### change the line with date (not OK on OSX)
	DATELINE=`grep -n "<h2>" $WEB_SBHOME | cut -d : -f 1`
	sed -i "${DATELINE}s/.*/\<h2\>`date +%Y-%m-%d-%H:%M`\<\/h2\>/" $WEB_SBHOME

} ##-----------------------------------

function generate_sbdata_bubbles(){

	### CSV readout, dumpt in file only if value not empty
	while read y
	do
    		#echo "Line contents are : $y "
    		echo $y | awk -F "," '{ if ( $4 =="" || $5 == "" || $8 == "" ) print "Some score for the student ",$2,"is missing " $4" "$5" "$8; else print " \{ x:" $4 ", y:" $5 ", z:" $8 ", name: \"" $2"\"\}," }' 2>/dev/null
	done < $SBDATAINPUT > $SBDATALIST
	## Clean the output
	sed -i  '/Some score/d' $SBDATALIST

	### build the php file
	cp $SBDATAHEADER $WEB_SBDATA
	while read z
	do
   		 echo $z
	done < $SBDATALIST >> $WEB_SBDATA

	### add the end of the php file
	cat $SBDATATAIL >> $WEB_SBDATA

	### change the line with date (not OK on OSX)
	DATELINE=`grep -n "<h2>" $WEB_SBDATA | cut -d : -f 1`
	sed -i "${DATELINE}s/.*/\<h2\>`date +%Y-%m-%d-%H:%M`\<\/h2\>/" $WEB_SBDATA

} ##-----------------------------------

function build_userlist_from_groups(){
	
	## build a user-based table
	for i in `getent group my_group | sed 's/,/ /g'`; do
		echo $i;
	done > $USERLIST

	#sed 's/mailaus:\*:9012://g;s/jucastil_a//g'  $USERLIST

} ##-----------------------------------

function build_userlist_from_quotas(){

	### read from the mmrepquota files, store repeated users on a list
	quota1=$1
	quota2=$2
	
	while IFS= read -r line; do echo $line | awk '{print $1}'; done < $quota1 >> $USERTEMP
	while IFS= read -r line; do echo $line | awk '{print $1}'; done < $quota2 >> $USERTEMP
	
	sort -u $USERTEMP  > $USERLIST  
	
	### cleanup of the list
	sed -i '/[0-9]/d' $USERLIST
	sed -i '/Name/d' $USERLIST
	sed -i '/Block/d' $USERLIST
	sed -i '/root/d' $USERLIST
	sed -i '/rpcuser/d' $USERLIST
	sed -i '/ghi.scratch/d' $USERLIST
	sed -i '/cesshared/d' $USERLIST
	### remove old users or functional accounts
	for baduser in `cat $USEREXCLUDE`; do 
		#echo $i
		sed -i '/"$baduser"/d' $USERLIST
	done
	
	rm $USERTEMP
	
} ##------------------------------------

function build_userlist_from_ls(){

  ## note that this needs to be customized
	for i in /data/projects/* ; do echo $i | sed 's|/data/projects/||g'; done >> $USERTEMP
	for i in /home/* ; do echo $i | sed 's|/home/||g'; done >> $USERTEMP
	### remove duplicates and order
	sort -u $USERTEMP  > $USERLIST  
	### cleaup the list
	sed -i '/username/d' $USERLIST
	rm $USERTEMP
	
}

function build_user_webspaces(){

	users=$1
	for i in `cat $users`; do 
		rm "/root/help/users/"$i.html
		cp "/root/help/user_header.txt" "/root/help/users/"$i.html
		### header
		echo "<th>Entry</th> <th>group </th> <th>DATA total(G) </th> <th>DATA inodes</th> <th>projects size (G)</th> <th>projects total files</th> <th>projects small files</th>  <th >HOME total (G)</th> <th >HOME inodes </th> <th>HOME size (G)</th>  <th >HOME total files </th> <th >HOME total small files </th> " >> "/root/help/users/"$i.html
		### read from Tarballs, format it as HTML

		
		for entry in `ls /home/admin/logs/storage/*raw.log`; do printf "<tr bgcolor=\"white\" align=\"center\">  <td>"$entry | sed 's/-raw.log//g' | sed 's/\/sb_home\/admin\/logs\/storage\///g' ; grep -h "$i" $entry | awk -F "," '{print "</td>  <td> "$3"</td>  <td> "$4"</td> <td> "$5"</td>  <td> "$6"</td>  <td> "$7"</td>  <td> "$8" </td>  <td>"$9"</td>  <td> "$10" </td>  <td>"$11"</td>  <td> "$12"</td>  <td> "$13"</td></tr>"}'; done  >> "/root/help/users/"$i.html
		
		### add botton to index.html
		echo "</table><br><br><br><br><br>" >> "/root/help/users/"$i.html
		echo "<hr><br><br><br></DIV>" >> "/root/help/users/"$i.html
		echo "</body></html>" >> "/root/help/users/"$i.html
		### remove malformed line, if any
		sed -i '/Binary/d' "/root/help/users/"$i.html
	done
}

function build_info_array(){
	
	### grep from the list of files the names of the users, print the info
	Q_SBDATA=$1
	Q_SBHOME=$2
	O_SBDATA=$3
	O_SBHOME=$4
	for i in `cat $USERLIST`; do
		### note : match EXACT username (no username_TAR)
		SBDATA_SIZE=`grep -w $i $Q_SBDATA | awk '{print $4}'`
		SBDATA_N_QUOTA=`grep -w $i  $Q_SBDATA  | awk '{print $10}'`
		SBHOME_SIZE=`grep -w $i $Q_SBHOME | awk '{print $4}'`
		SBHOME_N_QUOTA=`grep -w $i  $Q_SBHOME  | awk '{print $10}'`
		#grep $i $SMALL_SBDATA;
		SBDATA_N_FIND_T=`grep -w $i $O_SBDATA | awk '{print $3}' | sed 's/G//g';`
		SBDATA_N_FIND_A=`grep -w $i $O_SBDATA | awk '{print $5}';`
		SBDATA_N_FIND_S=`grep -w $i $O_SBDATA | awk '{print $9}';`
		#echo "	"$SBDATA_N_FIND_A" "$SBDATA_N_FIND_S;
		#grep $i $SMALL_SBHOME;
		HOME_N_FIND_T=`grep -w $i $O_SBHOME | awk '{print $3}' |  sed 's/G//g';`
		HOME_N_FIND_A=`grep -w $i $O_SBHOME | awk '{print $5}';`
		HOME_N_FIND_S=`grep -w $i $O_SBHOME | awk '{print $9}';`
		fullusername=`getent passwd "$i" | awk -F: '{ print $5}'`
		usergroupid=`id -g $i`
		usergroupname=`getent group $usergroupid | cut -d: -f1`
		#echo " user" $i"  groupid" $usergroupid " name "$usergroupname
		echo $fullusername","$i","$usergroupname","$SBDATA_SIZE","$SBDATA_N_QUOTA","$SBDATA_N_FIND_T","$SBDATA_N_FIND_A","$SBDATA_N_FIND_S","$SBHOME_SIZE","$SBHOME_N_QUOTA","$HOME_N_FIND_T","$HOME_N_FIND_A","$HOME_N_FIND_S;
	done > $RAWREPORT

} ##-----------------------------------

function build_index_html(){

	DATAFILE=$1
	### builds index.html
	cp /root/help/main_header.txt /root/help/header.tmp
	echo "<th>User</th> <th>Username</th> <th>Group</th> <th>DATA total(G) </th> <th>DATA inodes</th> <th>projects size (G)</th> <th>projects total files</th> <th>projects small files</th>  <th >HOME total (G)</th> <th >HOME inodes </th> <th>HOME size (G)</th>  <th >HOME total files </th> <th >HOME total small files </th> " >> /root/help/header.tmp
	### reads RAWREPORT, replace commas by table tags, add hyperlinks to usernames
	while IFS= read -r line; do echo $line | awk -F "," '{print "<tr bgcolor=\"white\"align=\"center\"> <td>" $1"</td>  <td> <a href=\"users/"$2".html\">"$2"</a></td>  <td>"$3"</td>  <td>"$4"</td>  <td>"$5"</td>  <td>"$6"</td>  <td>"$7"</td>  <td>"$8"</td>  <td>"$9"</td>  <td>"$10"</td>  <td>"$11"</td>  <td>"$12"</td>  <td>"$13"</td> <td>"$14"</td> </tr>"}' ; done < $DATAFILE >> "/root/help/header.tmp"
	
	### add botton to index.html
	echo "</table><br><br><br><br><br>" >> "/root/help/header.tmp"
	echo "<hr><br><br><br></DIV>" >> "/root/help/header.tmp"
	echo "</body></html>" >> "/root/help/header.tmp"
	sed -i "87s/.*/\<h2\> Last update : `date +%Y-%m-%d-%H:%M`\<\/h2\>/" "/root/help/header.tmp" #### change the date
	## clean up a little
	sed -i '/bad_user/d' "/root/help/header.tmp"	
	mv "/root/help/header.tmp" $WEB_INDEX
	
} ##-----------------------------------


function is_bigger_than(){

	### modify the WEB_INDEX adding colors 
	### for user is value is bigger than $2
	
	### read the 
	user=$1
	###arg1=$2
	arg1="500000"
	arg2=$3
	#echo "	checking:" $user" "$arg1" "$arg2 
	if [[ "$arg2" -gt "$arg1" ]] ; then
		#echo "		WARNING: "$user" "$arg2" is greater than "$arg1
	        arg1="1000000"
                if [[ "$arg2" -gt "$arg1" ]]; then
		     arg1="2000000"
		     if [[ "$arg2" -gt "$arg1" ]]; then
			 arg1="3000000"
			 if [[ "$arg2" -gt "$arg1" ]]; then
			     arg1="4000000"
			     if [[ "$arg2" -gt "$arg1" ]]; then
				 sed -i "s/>$arg2/ bgcolor=\"#990000\" >$arg2/g" $WEB_INDEX
			     fi 
			     sed -i "s/>$arg2/ bgcolor=\"#cc0000\" >$arg2/g" $WEB_INDEX
			 fi
			 sed -i "s/>$arg2/ bgcolor=\"Red\" >$arg2/g" $WEB_INDEX	
		     fi
		     sed -i "s/>$arg2/ bgcolor=\"DarkOrange\" >$arg2/g" $WEB_INDEX    
		 fi
		 sed -i "s/>$arg2/ bgcolor=\"Gold\" >$arg2/g" $WEB_INDEX
	fi	 

	
	
} ##-----------------------------------

function colour_bigvalues(){

	DATAFILE=$1
	#### add colors depending on the table
	for i in `cat $DATAFILE`; do
		# if Q Nfiles is > 1M
		limit="500000"
		var1=`echo $i | awk 'BEGIN { FS = "," }{print $2}'; `  #user
		var2=`echo $i | awk 'BEGIN { FS = "," }{print $4}'; `  #SBDATA Q -G
		var3=`echo $i | awk 'BEGIN { FS = "," }{print $5}'; `  #SBDATA Q -N files
		var4=`echo $i | awk 'BEGIN { FS = "," }{print $6}'; `  #EM/projects G
		var5=`echo $i | awk 'BEGIN { FS = "," }{print $7}'; `  #EM/projects N
		var6=`echo $i | awk 'BEGIN { FS = "," }{print $8}'; `  #EM/projects N small
		var7=`echo $i | awk 'BEGIN { FS = "," }{print $9}'; `  #HOME Q -G
		var8=`echo $i | awk 'BEGIN { FS = "," }{print $10}'; `  #HOME Q -N files
		var9=`echo $i | awk 'BEGIN { FS = "," }{print $11}'; `  #HOME G
		var10=`echo $i | awk 'BEGIN { FS = "," }{print $12}'; `  #HOME N
		var11=`echo $i | awk 'BEGIN { FS = "," }{print $13}'; `  #HOME N small
		### check values
        	is_bigger_than $var1 $limit $var3
        	is_bigger_than $var1 $limit $var5
        	is_bigger_than $var1 $limit $var6
        	is_bigger_than $var1 $limit $var8
        	is_bigger_than $var1 $limit $var10
        	is_bigger_than $var1 $limit $var11

	done
} ##-----------------------------------

### dump quota info

### ------------------ Table header output -------------------------------------------------------- 
###                         Block Limits            |                     File Limits
### Name	fileset	type KB quota limit in_doubt grace | files quota limit in_doubt grace entryType
### -------------------------------------------------------------------------------------------------

/usr/lpp/mmfs/bin/mmrepquota -u -j sb_data --block-size G > $SBDATA_Q
/usr/lpp/mmfs/bin/mmrepquota -u -j sb_home --block-size G > $SBHOME_Q

### small cleanup when needed
sed -i '/bad_user/d' $SBHOME_Q

build_userlist_from_ls 		
#build_userlist_from_quotas $SBDATA_Q $SBHOME_Q  	   ### just read the files, get a list of common users
build_info_array $SBDATA_Q $SBHOME_Q $SBDATA_O $SBHOME_O   ### write RAWREPORT from common users and quotas
build_index_html $RAWREPORT  				   ### write index.html from RAWREPORT
build_user_webspaces $USERLIST				   ### write user.html files 
colour_bigvalues $RAWREPORT				   ### colour big values on the html file
generate_sbdata_bubbles					   ### generates sbdata_bubbles.php
generate_home_bubbles					   ### generate home_bubbles.php
generate_local_bubbles

###--------------------------------------------------
### now copy the results to webserver and clean up, 
###-------------------------------------------------------


#######################  END ###########################

