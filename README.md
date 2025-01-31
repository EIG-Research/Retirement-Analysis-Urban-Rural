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


Both the SIPP and the SCF provide information on respondents' access to retirement plan benefits, their participation in these benefits, and whether their employers offer matching benefits.

<h3>Retirement plan access is defined as follows:</h3>

<h4>SIPP</h4>

      Has access to a retirement plan:
            EMJOB_401 == 1 OR      Any 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through main employer or business during the reference period.
            EMJOB_IRA == 1 OR      Any IRA or Keogh account(s) provided through main employer or business during the reference period.
            EMJOB_PEN == 1         Any defined-benefit or cash balance plan(s) provided through main employer or business during the reference period.

      Does not have access to a retirement plan: 
            EMJOB_401 == 2 OR         No 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through main employer or business 
            EMJOB_IRA == 2 OR         No IRA or Keogh account(s) provided through main employer or business during the reference period.
            EMJOB_PEN == 2 OR         No defined-benefit or cash balance plan(s) provided through main employer or business during the reference period.
            EOWN_THR401  == 2 OR      Did not own any 401k, 403b, 503b, or Thrift Savings Plan accounts during the reference period.
            EOWN_IRAKEO  == 2 OR      Did not own any IRA or Keogh accounts during the reference period.
            EOWN_PENSION == 2         Did not participate in a defined-benefit pension or cash balance plan during the reference period.

<h4>SCF</h4>

<h3>Retirement participation is defined as follows:</h3>

<h4>SIPP</h4>

      Participates in a retirement plan:
            ESCNTYN_401 == 1 OR      During the reference period, respondent contributed to the 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through their main employer or business.
            EECNTYN_401 == 1 OR      Main employer or business contributed to respondent's 401k, 403b, 503b, or Thrift Savings Plan account(s) during the reference period.
            ESCNTYN_PEN == 1 OR      During the reference period, respondent contributed to the defined-benefit or cash balance plan(s) provided through their main employer or business.
            ESCNTYN_IRA == 1         During the reference period, respondent contributed to the IRA or Keogh account(s) provided through their main employer or business.
      
      Does not participate in a retirement plan:
            ESCNTYN_401 == 2 OR      During the reference period, respondent did not contribute to the 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through their main employer or business.      
            ESCNTYN_PEN == 2 OR      During the reference period, respondent did not contribute to the defined-benefit or cash balance plan(s) provided through their main employer or business.
            ESCNTYN_IRA == 2 OR      During the reference period, respondent did not contribute to the IRA or Keogh account(s) provided through their main employer or business.
            EOWN_THR401  == 2 OR      Did not own any 401k, 403b, 503b, or Thrift Savings Plan accounts during the reference period.
            EOWN_IRAKEO  == 2 OR      Did not own any IRA or Keogh accounts during the reference period.
            EOWN_PENSION == 2         Did not participate in a defined-benefit pension or cash balance plan during the reference period.

<h4>SCF</h4>

<h3>Employer matching is defined as follows:</h3>

<h4>SIPP</h4>

      Employer offers matching benefits:
            EECNTYN_401 == 1 OR     Main employer or business contributed to respondent's 401k, 403b, 503b, or Thrift Savings Plan account(s) during the reference period.
            EECNTYN_IRA == 1 OR     Main employer or business contributed to respondent's IRA or Keogh account(s) during the reference period.

      Employer does not offer matching benefits: 
      EECNTYN_401 == 2 OR      Main employer or business did not contribute to respondent's 401k, 403b, 503b, or Thrift Savings Plan account(s) during the reference period.
      EECNTYN_IRA == 2 OR      Main employer or business did not contribute to respondent's IRA or Keogh account(s) during the reference period.
      EOWN_THR401  == 2 OR      Did not own any 401k, 403b, 503b, or Thrift Savings Plan accounts during the reference period.
      EOWN_IRAKEO  == 2 OR      Did not own any IRA or Keogh accounts during the reference period.
      EOWN_PENSION == 2         Did not participate in a defined-benefit pension or cash balance plan during the reference period.

<h4>SCF</h4>

***

<h2>Data Quality Concerns</h2>

(robustness checks....)


