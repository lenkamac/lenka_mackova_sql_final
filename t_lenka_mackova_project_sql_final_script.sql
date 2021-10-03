CREATE TABLE t_lenka_mackova_project_SQL_final(
	WITH countries_all AS (
		SELECT 
				CASE WHEN country = 'Czech Republic' THEN 'Czechia'  	
					 WHEN country = 'Korea, South' THEN 'South Korea'
					 WHEN country = 'United States' THEN 'US'
				            ELSE country END AS country,
				  c.iso3 ,
		          c.capital_city,
		          c.surface_area,
		          c.median_age_2018
		FROM  countries c
	),
	covid_diff AS (
		-- select z tabulky covid19_basic_differences
		SELECT 
			cbd.`date` AS datum ,
			cbd.country ,
			lt.population AS populations_all ,
			lt.iso3 AS iso,
			cbd.confirmed 
		FROM covid19_basic_differences cbd 
		LEFT JOIN lookup_table lt
			ON cbd.country = lt.country 
			AND lt.province is null
		WHERE cbd.`date` BETWEEN '2020-03-01' AND '2020-11-01'
		ORDER BY cbd.date, cbd.country
	),
	cov_tests AS (
		-- select z tabulky covid19-tests
			SELECT  
				CAST(ct2.date as date) as datum,
				ct2.country as all_country,
				ct2.tests_performed as tests_perform,
				ct2.ISO as iso
			FROM (
				SELECT
					CASE WHEN country = 'Czech Republic' THEN 'Czechia'
					 	WHEN country = 'Korea, South' THEN 'South Korea'
					 	WHEN country = 'United States' THEN 'US'
				     ELSE country 
				     END AS country,
				    ct.`date` ,
					ct.ISO,
					ct.tests_performed
				FROM covid19_tests ct 
			)  ct2
			WHERE ct2.date BETWEEN '2020-03-01' AND '2020-11-01'
			ORDER BY ct2.date
	),
	life_exp AS (
		-- select a vypocty pro life_expectancy 
		SELECT a.country, a.life_exp_1965 , b.life_exp_2015, a.iso3,
		    	ROUND( b.life_exp_2015 - a.life_exp_1965, 2 ) as life_exp_diff_2015_1965
		FROM (
		    SELECT 
			    CASE WHEN country = 'Czech Republic' THEN 'Czechia'
						 WHEN country = 'Korea, South' THEN 'South Korea'
						 WHEN country = 'United States' THEN 'US'
					            ELSE country END AS country ,
			    le.life_expectancy as life_exp_1965,
			    le.iso3
		    FROM life_expectancy le 
		    WHERE year = 1965
		    	AND le.iso3  IS NOT NULL
		    ) a 
		    JOIN (
		    	SELECT 
		    		CASE WHEN country = 'Czech Republic' THEN 'Czechia'
						 WHEN country = 'Korea, South' THEN 'South Korea'
						 WHEN country = 'United States' THEN 'US'
					            ELSE country END AS country,
		    		le.life_expectancy AS life_exp_2015
		    	FROM life_expectancy le 
		    	WHERE year = 2015
		    		AND le.iso3  IS NOT NULL
		    	) b
		    ON a.country = b.country
		GROUP BY a.country
	),
	populations_density AS (
		-- select a vypocty pro hustotu obyvatel = vazeny prumer hustoty ob. , kde se bere v potaz velikost zeme a celkova populace
		SELECT 
			 c2.country,
			 c2.iso3,
			ROUND(AVG(lt.population / c2.surface_area),2) as density 
		FROM (
			SELECT
				CASE WHEN country = 'Czech Republic' THEN 'Czechia'
						 WHEN country = 'Korea, South' THEN 'South Korea'
						 WHEN country = 'United States' THEN 'US'
					            ELSE country END AS country,
					c.iso3 ,
					c.surface_area 
				FROM countries c 		
			) c2
		LEFT JOIN lookup_table lt 
			ON c2.iso3  = lt.iso3
			AND lt.province IS NULL
		GROUP BY country
	),
	season AS (
		-- tvorba sloupce rocni obdobi
		SELECT 
			s.`date` ,
			s.seasons 
		FROM seasons s 
		WHERE s.`date` BETWEEN '2020-03-01' AND '2020-11-01'
	),
	weekend AS (
		-- ukaztal pracovniho dne nebo vikendu v binar
		SELECT
			cbd.`date` ,
			cbd.country ,
			CASE WHEN WEEKDAY(cbd.`date`) IN (5, 6) THEN 1 
				ELSE 0 
			END AS weekend
		FROM covid19_basic_differences cbd 
		WHERE cbd.`date` BETWEEN '2020-03-01' AND '2020-11-01'
	),
	economy AS (
		-- zakladni udaje z tabulky economies
		SELECT  
		    CASE WHEN country = 'Czech Republic' THEN 'Czechia'
					 WHEN country = 'Korea, South' THEN 'South Korea'
					 WHEN country = 'United States' THEN 'US'
				            ELSE country END AS country , 
			e.year, 
		    ROUND( e.GDP / 1000000, 2 ) AS GDP_mil_dollars , 
		    e.gini ,
		    e.taxes ,
		    e.mortaliy_under5 AS mortality_under_5
		FROM economies e
		WHERE e.`year` BETWEEN '2015' AND '2019'
	),
	religions AS (
		-- procentualni zastoupeni nabozenstvi pro jednotlive zeme v roce 2020
		SELECT r3.country AS rel_country , r3.religion  AS country_religion, 
			round( r3.population / r2.total_population_2020 * 100, 2 ) AS religion_share_2020
		FROM (
			SELECT
				CASE WHEN country = 'Czech Republic' THEN 'Czechia'
							 WHEN country = 'Korea, South' THEN 'South Korea'
							 WHEN country = 'United States' THEN 'US'
						            ELSE country END AS country,
					r2.`year` ,
					r2.religion ,
					r2.population 
			FROM religions r2	
			) r3
		JOIN (
			SELECT 
			    CASE WHEN country = 'Czech Republic' THEN 'Czechia'
						 WHEN country = 'Korea, South' THEN 'South Korea'
						 WHEN country = 'United States' THEN 'US'
					            ELSE country END AS country ,
			  	r.year, 
			 	sum(r.population) AS total_population_2020
			 FROM religions r 
			 WHERE r.year = 2020 and r.country != 'All Countries'
			 GROUP BY r.country
			) r2
		ON r3.country = r2.country
		AND r3.year = r2.year
		AND r3.population > 0
	),
	avg_day_temp AS (
		-- prumerna deni teplota pocitano v rozmezi 06:00:00 do 18:00:00
		SELECT 
			avg_col.datum,
			avg_col.city,
			AVG(avg_col.day_temp) as avg_day_temperatur 
		FROM (
			SELECT 
				CAST(RTRIM(REPLACE(wi.date, '00:00:00', '')) as date ) AS datum,
				CAST(wi.city as varchar(255)) AS city,
				CAST(REGEXP_REPLACE(wi.temp ,'[^0-9]','')as float) AS day_temp,
				TIME(wi.`time`) AS hours
			FROM (
				SELECT
					CASE WHEN city = 'Prague' THEN 'Praha'
						 WHEN city = 'Warsaw' THEN 'Warszawa'
						 WHEN city = 'Vienna' THEN 'Wien'
						 WHEN city = 'Brussels' THEN 'Bruxelles [Brussel]'
				            ELSE city END AS city, 
					w.date,
					w.time,
					w.temp
				FROM weather w 
				WHERE w.time BETWEEN '06:00:00' AND '18:00:00'
					AND w.date BETWEEN '2020-03-01' AND '2020-11-01'
					AND city is not NULL 
				) AS wi
			)AS avg_col
		GROUP BY avg_col.datum, avg_col.city
		ORDER BY datum
	),
	max_wind_day AS (
		-- maximalni rychlost vetru pro dany den a mesto
		SELECT 
			max_wind.datum,
			max_wind.city,
			MAX(max_wind.wind_day )AS max_day_wind 
		FROM (
			SELECT
				CAST(RTRIM(REPLACE(wi.date, '00:00:00', '')) as date ) AS datum,
				CAST(wi.city as varchar(255)) AS city,
				CAST(REGEXP_REPLACE(wi.wind,'[^0-9]','')as float) AS wind_day
			FROM (
				SELECT
					CASE WHEN city = 'Prague' THEN 'Praha'
						 WHEN city = 'Warsaw' THEN 'Warszawa'
						 WHEN city = 'Vienna' THEN 'Wien'
						 WHEN city = 'Brussels' THEN 'Bruxelles [Brussel]'
				            ELSE city END AS city,
					w.date,
					w.wind
				FROM weather w 
				WHERE w.date BETWEEN '2020-03-01' AND '2020-11-01'
					AND city IS NOT NULL
				) AS wi
			) AS max_wind
		GROUP BY max_wind.datum, max_wind.city
		ORDER BY max_wind.datum
	),
	hours_rain AS (
		-- pocet hodin, kdy na uzemi prselo
		SELECT  
			sum_hours_rain.datum AS datum,
			sum_hours_rain.city AS city,
			SUM(hours_rain) AS daily_sum_hours
		FROM (
			SELECT 
				rain_day_hours.datum AS datum,
				rain_day_hours.city AS city,
				CASE WHEN rain_day_hours.rain_day > 0 THEN 3
					ELSE 0
				END AS hours_rain
			FROM (
				SELECT
					CAST(RTRIM(REPLACE(wi.date, '00:00:00', '')) as date ) AS datum,
					CAST(wi.city as varchar(255)) AS city,
					CAST(RTRIM(REPLACE (wi.rain, 'mm', '')) AS float) AS rain_day,
					TIME(wi.`time`) AS hours
				FROM (
					SELECT
						CASE WHEN city = 'Prague' THEN 'Praha'
						 WHEN city = 'Warsaw' THEN 'Warszawa'
						 WHEN city = 'Vienna' THEN 'Wien'
						 WHEN city = 'Brussels' THEN 'Bruxelles [Brussel]'
				            ELSE city END AS city,
						w.date,
						w.time,
						w.rain
					FROM weather w 
					WHERE w.date BETWEEN '2020-03-01' AND '2020-11-01'
						AND city is not NULL
					) AS wi
				) AS rain_day_hours
			) AS sum_hours_rain
		GROUP BY sum_hours_rain.datum,sum_hours_rain.city, sum_hours_rain.hours_rain
	)
	SELECT  -- vysledny select a jednotlive sloupce
	 	cdf.datum,
	 	we.weekend,
	 	s2.seasons,
	 	ca.country,
	 	ca.capital_city,
	 	cdf.populations_all,
	 	popd.density,
	 	cdf.confirmed,
	 	te.tests_perform,
	 	lifex.life_exp_1965,
	 	lifex.life_exp_2015,
	 	lifex.life_exp_diff_2015_1965,
	 	ca.median_age_2018,
	 	eco.year,
	 	eco.GDP_mil_dollars,
	 	eco.gini,
	 	eco.taxes,
	 	eco.mortality_under_5,
	 	relig.country_religion,
	 	relig.religion_share_2020,
	 	adt.avg_day_temperatur,
		mwd.max_day_wind,
		hr.daily_sum_hours
	FROM countries_all ca 
	LEFT JOIN covid_diff cdf 
		ON ca.iso3 = cdf.iso
	LEFT JOIN cov_tests te 
			ON cdf.datum = te.datum
			AND cdf.iso = te.iso
	LEFT JOIN life_exp lex 
		ON cdf.iso = lex.iso3
	LEFT JOIN life_exp lifex 
		ON ca.iso3 = lifex.iso3
	LEFT JOIN populations_density popd 
		ON ca.iso3 = popd.iso3
	LEFT JOIN season s2 
		ON cdf.datum = s2.`date`
	LEFT JOIN weekend we 
		ON cdf.datum = we.date
		AND ca.country = we.country
	LEFT JOIN economy eco
		ON ca.country = eco.country 
	LEFT JOIN religions relig
		ON cdf.country = relig.rel_country
	LEFT JOIN avg_day_temp adt 
		ON cdf.datum = adt.datum
		AND ca.capital_city = adt.city
	LEFT JOIN max_wind_day mwd 
		ON cdf.datum = mwd.datum
		AND ca.capital_city = adt.city
	LEFT JOIN hours_rain hr 
		ON cdf.datum = hr.datum
		AND ca.capital_city = hr.city
)
