# lenka_mackova_sql_final
Sql project pro Engeto
v tabulce jsem si pomohla s with, kde jsme si vytvorila jednotlive tabulky, ktere jsem ve vyslednem selectu spojila dohormady a vyselektovala jen urcite informace.
- jako hlavni klice jsem zvolila datum a country z tabulky covid19_basic_differences
- dale jsem pouzila tabulka - lookup_table, countries, religions,seasons,weather,covid19-test,life_expectancy,a economies.
- pri uprave nekterych tabulek je pouzito pretypovani, protoze nektere nazvy zemi se v tabulkach lisi, a v pripade jejich spojeni vznikaji nezadouci null hodnoty.
- bohuzel v tabulce weather je velmi malo hodnot a vsechny hodnoty jsou platne pro evropu. Tabulku jsem pripojila pomoci joinu, ve vysledku ale sloupce ve vysledne tabulce jsou hlavne hodnoty null. Zde pro nas muze byt ukazatel vlivu poctu hodin destivych srazek a vetru na sireni covidu nebo prumerna denni teplota pouze pro evropsky kontinent.
- casovy usek vyslednych dat u covidu jsem omezila na rok 2020 v rozmei 01-03-2020 az 01-11-2020, hlavne z toho duvodu,ze v tomto obdobi mame nejkompletnejsi zaznamy ke covid19.
- ekonomicke data jsem omezila na obdobi roku 2015-2019, v roce 2020 nejsou z velke casti dostupne, takze jsem zvolila udaje, kde je mozno si udelat celkovy obrazek o vyvoji ekonomik sveta.
- jsou zde obsazeny sloupce seasons a vikend, ktery urcuje rocni obdobi a ktery muze poslouzit k zjisteni souvislost rocniho obdobi s sirenim covidu a zda je souvislost i mezi pracovnim tydnem nebo vikendem s jeho sirenim a take s provadenim testu na covid.
