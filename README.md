<h1>INCERT POST TITLE HERE</h1>

This respository includes the data and necessary code to support EIG's analysis of retirement descriptives. You can find the analysis on our website [here](INCERT LINK).

All links are current at the time of publication. Contact Sarah Eckhardt with any questions at sarah@eig.org.

****

<h2>Data Sources</h2>

1. Survey of Income and Program Participation (SIPP): available for download from the Census [here](https://www.census.gov/programs-surveys/sipp.html)

      SIPP is a nationally representative longitudinal survey that provides information on the dynamics of income, employment, household composition, and government program participation. As the survey interviews individuals for several years over monthly surveys, it provides information about changes in household composition and economic circumstances over time.

      We rely on the 2023 SIPP survey for the majority of the analysis in this piece. Historical survey versions are used for generational cuts.

2. Survey of Consumer Finances (SCF): available for download from the Federal Reserve [here](https://www.federalreserve.gov/econres/scfindex.htm)

      SCF is a triennial cross-sectional survey of U.S. families. The survey data include information on families’ balance sheets, pensions, income, and demographic characteristics.

      We rely on the 2022 SCF survey for the majority of the analysis in this piece.

3. Census 2017 Industry Codes: available for download from the Census [here](https://www2.census.gov/programs-surveys/demo/guidance/industry-occupation/2017-industry-code-list-with-crosswalk.xlsx)

****


<h2>Methodology</h2>

The universe covers 18-65 year old non-government employees, working full time (35 or more hours a week), and earning a non-zero income.

<h3>Universe Definitions:</h3>

<h4>SIPP</h4>

      full time: EJB1_JBORSE == 1
      non-government: EJB1_CLWRK == 5 | EJB1_CLWRK == 6
      age range: TAGE >= 18 & TAGE <= 65
      non-zero income: TPTOTINC > 0

<h4>SCF</h4>

      full time: x4511 == 1
      non-government: x7402 < 9370
      age range: x14 >= 18 & x14 <= 65
      non-zero income: x4112 > 0


Both the SIPP and the SCF provide information on respondents' access to retirement account benefits, their participation in these benefits, and whether their employers offer matching benefits.

<h3>Retirement account access is defined as follows:</h3>

<h4>SIPP</h4>

      Yes:
            EMJOB_401 == 1 OR
            EMJOB_IRA == 1 OR
            EMJOB_PEN == 1

      No: 
            EMJOB_401 == 2 OR
            EMJOB_IRA == 2 OR
            EMJOB_PEN == 2 OR
            EOWN_THR401  == 2 OR
            EOWN_IRAKEO  == 2 OR
            EOWN_PENSION == 2


<h4>SCF</h4>

<h3>Retirement participation is defined as follows:</h3>

<h4>SIPP</h4>

<h4>SCF</h4>

<h3>Employer matching is defined as follows:</h3>

<h4>SIPP</h4>
<h4>SCF</h4>

***

<h2>Data Quality Concerns</h2>

(robustness checks....)


