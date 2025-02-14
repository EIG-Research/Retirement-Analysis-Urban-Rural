<h1>INSERT POST TITLE HERE</h1>

This respository includes the data and necessary code to support EIG's analysis of retirement descriptives. You can find the analysis on our website [here](INSERT LINK).

All links are current at the time of publication. Contact Sarah Eckhardt with any questions at sarah@eig.org.

****

<h2>Data Sources</h2>

1. Survey of Income and Program Participation (SIPP): available for download from the Census [here](https://www.census.gov/programs-surveys/sipp.html)

      SIPP is a nationally representative longitudinal survey that provides information on the dynamics of income, employment, household composition, and government program participation. As the survey interviews individuals for several years over monthly surveys, it provides information about changes in household composition and economic circumstances over time.

      We rely on the 2023 SIPP survey for the analysis in this piece.

2. Survey of Consumer Finances (SCF): available for download from the Federal Reserve [here](https://www.federalreserve.gov/econres/scfindex.htm)

      SCF is a triennial cross-sectional survey of U.S. families. The survey data include information on families’ balance sheets, pensions, income, and demographic characteristics.

      We rely on the 2022 SCF survey for the analysis in this piece. SCF is not the primary dataset used in this piece as geographic variables are not available in the public sample, but as the primary source for retirement savings values, we use it for robustness checks.

3. Census 2017 Industry Codes: available for download from the Census [here](https://www2.census.gov/programs-surveys/demo/guidance/industry-occupation/2017-industry-code-list-with-crosswalk.xlsx)

4. Census Current Population Survey (CPS) downloaded from IPUMS [here](https://cps.ipums.org/cps/)

   CPS is a monthly survey covering a wealth of information about the socioeconomic state of the United States.

   We rely on the 2023 sample for the analysis in this piece.

****


<h2>Methodology</h2>

The universe covers 18-65 year old non-government employees, working full time (35 or more hours a week), and earning a non-zero income.

<h3>Workforce population estimates</h3>

The CPS is a more reliable estimator of the U.S. population and labor force than the SIPP. For this reason we use the CPS's estimates of the 18-65 year old, non-government full-time laborforce, by metro and non-metro status. These estimates are applied to the SIPP's retirement plan access, participation, and employer matching estimates to obtain the total number of workers who are left out.

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

            Has access to a retirement plan:
                  PARTICIPATES == yes      If the employee particiaptes, they have access
                  x4136 == 1               Does (your/his/her/his or her) employer offer any such plans? (1 = yes)

            Does not have access to a retirement plan: 
                  Otherwise
                  

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
            EOWN_THR401  == 2 OR     Did not own any 401k, 403b, 503b, or Thrift Savings Plan accounts during the reference period.
            EOWN_IRAKEO  == 2 OR     Did not own any IRA or Keogh accounts during the reference period.
            EOWN_PENSION == 2        Did not participate in a defined-benefit pension or cash balance plan during the reference period.

<h4>SCF</h4>

see [DCPLANCJ](https://www.federalreserve.gov/econres/files/bulletin.macro.txt)

      Participates in a retirement plan:
            x11032 > 0 OR                     What is the balance of (your/his/her/his or her) pension account now?
            x11132 > 0 OR
            x11032 == -1 OR                   What is the balance of (your/his/her/his or her) pension account now? (-1 = nothing; but account exists)
            x11132 == -1 OR
            x5316 == 1 AND x6461 == 1 OR      Payment from a current job
            x5324 == 1 AND x6466 == 1 OR

      Does not participate in a retirement plan:
            Otherwise

<h3>Employer matching is defined as follows:</h3>

<h4>SIPP</h4>

      Employer offers matching benefits:
            EECNTYN_401 == 1 OR     Main employer or business contributed to respondent's 401k, 403b, 503b, or Thrift Savings Plan account(s) during the reference period.
            EECNTYN_IRA == 1 OR     Main employer or business contributed to respondent's IRA or Keogh account(s) during the reference period.

      Employer does not offer matching benefits: 
            EECNTYN_401 == 2 OR      Main employer or business did not contribute to respondent's 401k, 403b, 503b, or Thrift Savings Plan account(s) during the reference period.
            EECNTYN_IRA == 2 OR      Main employer or business did not contribute to respondent's IRA or Keogh account(s) during the reference period.
            EOWN_THR401  == 2 OR     Did not own any 401k, 403b, 503b, or Thrift Savings Plan accounts during the reference period.
            EOWN_IRAKEO  == 2 OR     Did not own any IRA or Keogh accounts during the reference period.
            EOWN_PENSION == 2        Did not participate in a defined-benefit pension or cash balance plan during the reference period.

<h4>SCF</h4>

      Employer offers matching benefits:
            x11047 == 1               Does your (employer/the business) make contributions to this plan?
            x11147 == 1

      Employer does not offer matching benefits: 
            Otherwise


***
<h2>Random Forest</h2>

We select the random forest as our non-parametric estimator for the following reasons:
1. Random forests do well with combining categorical and numerical data types; our model has both.
2. It handles non-linear relationships; and like all non-parametric estimators makes minimal assumptions about the underlying distribution.
3. Random forests are robust, being built on n-many decision trees, which makes it well-equipped to manage noisy data, and high-variance trees. This is particularly useful for the SIPP, which is noisy.
4. It allows for constructing probability predictions of dependent variables based on different input values of independent variables.

Our random forest models consist of 500 decision trees. Each model is run 100 times (5,000 trees in total) to construct a confidence interval on the RF estimator.

For display, we use the RF importance estimates to predict the probabilities that a set of agents with different attributes will have access to an employer-based retirement plan. We start with a representative agent with median age, education, income, and employer size, living in a metropolitan area and working in the largest industry group. We perturb each variable by changing its value to its minimum and maximum and report how much the predicted probability changes as a result.


*** 
<h2>Robustness checks</h2>

We run sample-size robustness checks on industry, and industry X metro cuts. We check sample sizes, design effects, and the size of standard errors and confidence intervals. Industry based analysis stands up to the robustness checks; industry X metro cuts do not. See [robustness_checks.Rmd](https://github.com/SarahMEckhardt/Retirement-Analysis-Urban-Rural/blob/main/Code/robustness%20checks.Rmd)
