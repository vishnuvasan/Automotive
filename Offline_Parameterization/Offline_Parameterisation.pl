################################################################################
#
# Offline Parameterisation Tool
#
# Tool to Extract Parameter Values from DCM File and Create a new DCM
# With Updated Calibration Values
#
# Inputs 	:
# 				arg 0 :	DCM File
# 		
# 				arg 1 : Existing m Script with Parameter Values
#
# Outputs	:	DCM_Data_Extract.m in the Same Directory
#
# Usage		:   Command Prompt
#
# 				Extract_DCM_Data.pl <DCM_File_Name> <M_Script_File_Name>
#
#
# Date		:   18-12-2013
#
# Author	:   Vishnu Vasan Nehru
#
# License	: 	GPL
#
###############################################################################
use warnings;

my $DCM_File_Path=$ARGV[0];

my $PARAMETER_File_Path=$ARGV[1];

print "\n Input Arguments ==> \n";

print " DCM 		: $DCM_File_Path \n";

print " PARAMETER 	: $PARAMETER_File_Path \n\n";

my ($i,$j,$k,$l,$DCM_Value,$X_AXIS_PRESENT,$Y_AXIS_PRESENT,$VALUE_PRESENT,$MAP,$Map_Length);

my (@Split,@Parameters_List,@Map_Dimension);

my $Total_Parameters_Collected=0;

open DCM,"$DCM_File_Path" or die "$DCM_File_Path File Not Found.Execution Aborted!";

my @DCM=<DCM>;

close DCM;

my $DCM_File_Size=@DCM;

open PARAMETER,"$PARAMETER_File_Path" or die "$PARAMETER_File_Path File Not Found.Execution Aborted!";

my @PARAMETER=<PARAMETER>;

close PARAMETER;

my $No_Of_Parameters=@PARAMETER;

open DCM_DATA_EXTRACT,">DCM_Data_Output.m";

for($i=0;$i<=$No_Of_Parameters-1;$i++)
{	
	if($PARAMETER[$i]=~/\=/)
	{
		@Split=split("\=",$PARAMETER[$i]);

		push(@Parameters_List,$Split[0]);
	}
}

foreach my $Parameter (@Parameters_List)
{
	for($j=0;$j<=$DCM_File_Size-1;$j++)
	{
		if(($DCM[$j]=~/(\s)*$Parameter(\s).*/)&&($DCM[$j]!~/SSTX|SSTY/i))
		{
			$X_AXIS_PRESENT=$Y_AXIS_PRESENT=$VALUE_PRESENT=$MAP=0;			

			$k=$j+1;
	
			while($DCM[$k]!~/(\s*)END(\s*)/)
			{
				$k+=1;
			}

			for($l=$j;$l<=$k;$l++)
			{
				my @Total;
				if($DCM[$l]=~/(.*)ST\/X(.*)/){$X_AXIS_PRESENT=1;}
				if($DCM[$l]=~/(.*)ST\/Y(.*)/){$Y_AXIS_PRESENT=1;}
				if($DCM[$l]=~/(.*)WERT(.*)/){$VALUE_PRESENT=1;}
			}	
			for($l=$j;$l<=$k;$l++)
			{
				my @RawData;

				#Condition to be Valid to Pass through the Parameters
				if(($VALUE_PRESENT)&&(!$X_AXIS_PRESENT)&&(!$Y_AXIS_PRESENT))
				{
					if($DCM[$l]=~/^(\s*)WERT(.*)/)
					{
						$DCM[$l]=~s/WERT//;
						@RawData=split(/\s+/,$DCM[$l]);
						foreach(@RawData){if($_=~/^\s+$|^$/){shift(@RawData);}}
						my $size=@RawData;
						foreach(@RawData){push(@Total,$_);}
					}	
				}
				#Condition to be Valid to Pass through the Group Curves/Curves
				if(($VALUE_PRESENT)&&($X_AXIS_PRESENT)&&(!$Y_AXIS_PRESENT))
				{
					if($DCM[$l]=~/^(\s*)WERT(.*)/)
					{
						$DCM[$l]=~s/WERT//;
						@RawData=split(/\s+/,$DCM[$l]);
						foreach(@RawData){if($_=~/^\s+$|^$/){shift(@RawData);}}
						my $size=@RawData;
						foreach(@RawData){push(@Total,$_);}
					}	
				}
				#Condition to be Valid to Pass through the Array Indices/X Axis
				if((!$VALUE_PRESENT)&&($X_AXIS_PRESENT)&&(!$Y_AXIS_PRESENT))
				{
					if($DCM[$l]=~/^(\s*)ST\/X(.*)/)
					{
						$DCM[$l]=~s/ST\/X//;
						@RawData=split(/\s+/,$DCM[$l]);
						foreach(@RawData){if($_=~/^\s+$|^$/){shift(@RawData);}}
						my $size=@RawData;
						foreach(@RawData){push(@Total,$_);}
					}	
				}
				#Condition to be Valid to Pass through the Maps
				if(($VALUE_PRESENT)&&($X_AXIS_PRESENT)&&($Y_AXIS_PRESENT))
				{
					$MAP=1;
					@Map_Dimension=split($Parameter,$DCM[$j]);
					$Map_Length=$Map_Dimension[1];
					@Map_Dimension=split(/\s/,$Map_Length);
					$Map_Length=$Map_Dimension[1];
					$Map_Length=int($Map_Length);
					if($DCM[$l]=~/^(\s*)WERT(.*)/)
					{
						$DCM[$l]=~s/WERT//;
						@RawData=split(/\s+/,$DCM[$l]);
						foreach(@RawData){if($_=~/^\s+$|^$/){shift(@RawData);}}
						my $size=@RawData;
						foreach(@RawData){push(@Total,$_);}
					}	
				}
				if($l==$k)
				{				
					my $Total_Size=@Total;my $EVAL;
					if($Total_Size==1){foreach(@Total){$EVAL=eval($_);print DCM_DATA_EXTRACT "$Parameter\=$_";print DCM_DATA_EXTRACT ';',"\n";}}
					elsif($Total_Size>1)
					{
						print DCM_DATA_EXTRACT "$Parameter\=\[";
						if($MAP)
						{
							my $y;
							for($y=0;$y<=$Total_Size;$y++)
							{
								$EVAL=eval(($Total[$y]));	
								print DCM_DATA_EXTRACT "$Total[$y]\,";
								if(int($y+1) % int($Map_Length) == 0)
								{print DCM_DATA_EXTRACT "\; \n";}
							}
						}
						else
						{
							foreach(@Total){$EVAL=eval($_);print DCM_DATA_EXTRACT "$_\,";}
						}
						print DCM_DATA_EXTRACT "\]; \n";	
					}
					undef @Total;
				}
			}
		}
	}
	$Total_Parameters_Collected+=1;
}

print DCM_DATA_EXTRACT "\n Total Parameters Collected : $Total_Parameters_Collected \n";

close DCM_DATA_EXTRACT;


open DCM_DATA_EXTRACT,"DCM_Data_Output.m";

my @DCM_DATA_EXTRACT=<DCM_DATA_EXTRACT>;

close DCM_DATA_EXTRACT;

foreach(@DCM_DATA_EXTRACT){if($_=~s/\,\]\;/\]\;/g){}if($_=~s/\,\;/\;/g){}}

open DCM_DATA_EXTRACT,">DCM_Data_Output.m";

print DCM_DATA_EXTRACT @DCM_DATA_EXTRACT;

close DCM_DATA_EXTRACT;

