#
# Description: Counts physical pages for printing PDFs
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
pdfcount: count physical pages for printing PDFs
Usage: pdfcount [--single] [directory]

pdfcount will count the number of pages in PDFs either in the specified directory
or the current directory if not directory is specified. By default it will provide
a total of the number of physical pages required to print them assuming they'll be
printed double-sided.

Use of the --single option will provide a similar count but for single-sided
printing.
EOT
#'
	exit 0
fi

mode=double
if [[ "$1" == "--single" ]]; then
	mode=single
	shift
fi
dir=${1:-.}

total_pages=0
for pdf in "${dir}"/*.pdf; do
    if [[ -f "$pdf" ]]; then
    	found_pdfs=true
        pages=$(pdfinfo "$pdf" | grep "Pages:" | awk '{print $2}')
        if [[ $mode == double ]]; then
        	physical=$(( (pages + 1) / 2 ))
        else
        	physical=$pages
        fi
        suffix_1=
        suffix_2=
        [[ "$pages" -gt 1 ]] && suffix_1=s
        [[ "$physical" -gt 1 ]] && suffix_2=s
        total_pages=$((total_pages + physical))
        echo "$pdf: $pages page${suffix_1} = $physical physical sheet${suffix_2}"
    fi
done
if [[ -n "$found_pdfs" ]]; then
	echo "---"
	echo "Total physical sheets: $total_pages"
else
    echo "No PDF files found in ${dir}"
    exit 1
fi