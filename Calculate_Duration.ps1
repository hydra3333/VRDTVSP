#----- 
param ( [Parameter(Mandatory=$True)] [string]$start_date_time, [Parameter(Mandatory=$True)] [string]$end_date_time, [Parameter(Mandatory=$True)] [string]$prefix_id ) 
#[console]::BufferWidth = 512 
#echo "Calculate Duration" 
# 
Function FormatDuration([TimeSpan]$Duration) { 
    $DurHours = [math]::floor($Duration.TotalHours) 
    $DurMins  = [math]::floor($Duration.Minutes) 
    $DurSecs  = $Duration.Seconds 
    $DurMs    = $Duration.Milliseconds 
    if ($DurHours-1){$PlHours='s'} else {$PlHours=''} 
    if ($DurMins -1){$PlMins='s'}  else {$PlMins=''} 
    if ($DurSecs -1){$PlSecs='s'}  else {$PlSecs=''} 
    #if ($DurMs   -1){$PlMs='s'}    else {$PlMs=''} 
    #echo "in function, prefix_id={$prefix_id}" 
    return "{0}_Duration: {1} hour$($PlHours) {2} minute$($PlMins) {3}.{4} second$($PlSecs)" -f $prefix_id,$DurHours,$DurMins,$DurSecs,$DurMs 
} 
# START TEST 
#echo "outside function, prefix_id={$prefix_id}" 
#FormatDuration( (New-TimeSpan -Hours 25 -Minutes 45 -Seconds 01) ) 
# END TEST 
$dt_start_date_time=[datetime]::parse($start_date_time) 
$dt_end_date_time=[datetime]::parse($end_date_time) 
#echo "start_date_time='$start_date_time'" 
#echo "dt_start_date_time='$dt_start_date_time'" 
#echo "end_date_time='$end_date_time'" 
#echo "dt_end_date_time='$dt_end_date_time" 
#echo (-join('Duration in seconds: ', ($dt_end_date_time - $dt_start_date_time).TotalSeconds)) 
FormatDuration( ($dt_end_date_time - $dt_start_date_time) ) 
#----- 
