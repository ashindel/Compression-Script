## Script Testing File

# Simple html script maker
get-eventlog -LogName system -Newest 5 -EntryType error | Select-Object -Property index, source, message | ConvertTo-Html | out-file C:\Users\ajs573\Documents\DB-Dump-Compression-Repo\Scripts\test.htm -Append