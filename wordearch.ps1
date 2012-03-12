param([String]$inputfile)

# Check if input file is valid
if (($inputfile -eq "") -or !(Test-Path $inputfile)) {
	Write-Error "Input file $inputfile does not exist."
	Exit
}

[int]$n_Rows = 0						# number of rows
[int]$n_Cols= 0						# number of columns
[Array]$wordGrid = @()				# A 2d array containing the words
[bool]$wrap = $false					# True if wrap, false if not
[int]$n_Words = 0						# number of words
[Array]$findWords = @()				# words to find
[bool]$correct_col = $true			# true if the number of columns matches the columns specified

# Read in the file (Assumes input file is correctly formatted)
$n_line = 0
get-content $inputfile | %{
	# Read in rows and columns
	if ($n_line -eq 0) {
		$row_column_split = $_.split(" ")
		$n_Rows = $row_column_split[0]; $n_Cols = $row_column_split[1]
	}
	# Read in the wordsearch grid
	elseif ($n_line -le $n_Rows) {
		$wordGrid += $_
		if ($_.length -ne $n_Cols) { $correct_col = $false }
	}
	# Read in the wrap value
	elseif ($n_line -eq ($n_Rows + 1)) {
		if ($_ -eq "WRAP") { $wrap = $true }
	}
	# Read in number of words
	elseif ($n_line -eq ($n_Rows + 2)) {
		$n_Words = $_
	}
	# Read in words to find
	else {
		$findWords += $_
	}

	$n_line++
}

# Write warning if number of columns specified does not match number of columns provided
if (!$correct_col) {
	Write-Warning "Number of columns specified and number of columns provided do not match."
}
# Write warning if # words stated does not match with number of words provided
if ($findWords.length -ne $n_Words) {
	Write-Warning "Number of words specified and number of words provided do not match."
}

# Check if a coordinate is within the range
function withinRange {
	param([int]$x_coord, [int]$y_coord)

	if (($x_coord -lt 0) -or ($y_coord -lt 0) -or ($x_coord -ge $n_Rows) -or ($y_coord -ge $n_Cols)) {
		return $false
	}
	else {
		return $true
	}
}

# A function to search words given x and y directions
function findWord {
	param([String]$word, [int]$index, [int]$row_current, [int]$col_current, [int]$row_dir, [int]$col_dir, [int]$row_start, [int]$col_start)

	if ($index -ge $word.length) {
		return $true
	}
	elseif (!$wrap -and !(withinRange $row_current $col_current)) {
		return $false
	}

	if ($word[$index] -eq $wordGrid[$row_current][$col_current]) {
		$GLOBAL:row_last = $row_current
		$GLOBAL:col_last = $col_current

		$row_current += $row_dir
		$col_current += $col_dir
		# Wrap around if not in range
		if ($wrap) {
			if ($row_current -lt 0) { $row_current = $n_Rows - 1 }
			elseif ($row_current -ge $n_Rows) { $row_current = 0 }
			if ($col_current -lt 0) { $col_current = $n_Cols - 1 }
			elseif ($col_current -ge $n_Cols) { $col_current = 0 }
		}

		if (($row_start -eq $row_current) -and ($col_start -eq $col_current) -and ($index -ne ($word.length - 1))) {
			return $false
		}
		else {
			findWord $word ($index + 1) $row_current $col_current $row_dir $col_dir $row_start $col_start
		}
	}
	else {
		return $false
	}
}

# Array of directions
$directions = @(@(0,1), @(1,0), @(0,-1), @(-1,0), @(1,1), @(-1,-1), @(1,-1), @(-1,1))

# The last x and y coordinate visited by the findWord function
$GLOBAL:row_last = 0
$GLOBAL:col_last = 0

# Go through each word of interest
foreach ($word in $findWords) {
	[String]$output_message = "NOT FOUND"
	# Go through each row
	[int]$grid_row = 0
	$wordGrid | %{
		$gridRow = $_.ToCharArray()
		[int]$grid_col = 0
		# Go through all the columns
		foreach ($gridLetter in $gridRow) {
			# look in 8 directions
			foreach ($direction in $directions) {
				$found = findWord $word 0 $grid_row $grid_col $direction[0] $direction[1] $grid_row $grid_col
				if ($found) {
					$output_message = "($grid_row,$grid_col) ($GLOBAL:row_last,$GLOBAL:col_last)"
				}
			}
			$grid_col++
		}
		$grid_row++
	}
	Write-Host $output_message
}
