clear all

set maxvar 10000

* 2023
* note -- SIPP pu2023.dta is too large for github storage, download from the census here:
* https://www.census.gov/programs-surveys/sipp/data/datasets/2023-data/2023.html
* 2023 SIPP in Stata format

cd "/Users/sarah/Documents/GitHub/Retirement-Analysis-Urban-Rural/Data/SIPP/2023"

use "pu2023.dta", clear

keep SHHADID SPANEL SSUID SWAVE PNUM MONTHCODE WPFINWGT TAGE EEDUC ESEX ERACE TMETRO_INTV EJB1_JBORSE EJB1_CLWRK TPTOTINC EMJOB_401 EMJOB_IRA EMJOB_PEN EOWN_THR401 EOWN_IRAKEO EOWN_PENSION ESCNTYN_401 EECNTYN_401 EORIGIN TJB1_JOBHRS1 ESCNTYN_PEN ESCNTYN_IRA EECNTYN_IRA TVAL_RET TJB1_IND TIRAKEOVAL TTHR401VAL
	
export delimited  "pu2023.csv", replace
