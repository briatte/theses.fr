# README

A set of R scripts to scrape information from the French PhD portal [theses.fr](http://theses.fr), which is maintained by the [ABES](http://abes.fr/), the French agency responsible for higher education bibliographic records.

The code relies on the [XML API](https://punktokomo.abes.fr/2011/07/12/theses-fr-lapi-xml-des-theses/) of the website, which is briefly described in [Chapter 3](http://documentation.abes.fr/aidethesesfr/accueil/ch03.html) of its documentation manual.

# HOWTO

Run the following makefile to go through the full scraping routine:

```R
library(dplyr)
library(rvest)
library(stringr)
library(readr)

source("1_dir.r")
source("2_phd.r")
source("3_nfo.r")
```

- `1_dir.r` collects the unique identifiers (PPNs) of PhD supervisors from a given set of research areas (see below).
- `2_phd.r` collects the unique identifiers (URLs) of PhD dissertations supervised or examined by the supervisors.
- `3_nfo.r` collects available information on the PhD dissertations.

By default, the first script will PhD supervisors identified with the "Social sciences, sociology and anthropology" (ID 300) and "Political science" (ID 320) research areas.

Some of the pages collected by the first two scripts will fail to scrape due to XML syntax errors or to temporary download errors, so make sure that you let each script iterate several times to fix network errors.

The code will take several hours to complete if the set of PhD supervisors is large. The default selection coded in the first script will return over 8,000 supervisors and over 40,000 dissertations.

The package dependencies are listed at the top of each script:

* The `dplyr` package is used to manipulate data frames.
* The `rvest` package is used to scrape the data source.
* The `stringr` package is used to manipulate strings.
* The `readr` package is used to read and write CSV files.

The separate script `network_of_disciplines.r` shows one way to use the data to represent disciplinary associations in the sample of dissertations produced by the routine described above.

# DATA

`dir.csv` contains __PhD supervisors__:

* `page` is the page number from the initial search query (integer)
* `personne` is the name of the PhD supervisor (character)
* `personneNP` is the name of the PhD supervisor, reversed, i.e. family name first (character)
* `ppn` is the unique identifier of the supervisor (character)
* `actif` indicates whether the supervisor is still active (`oui`) or not (`non`) (character)

`phd.csv` contains __PhD dissertations__:

* `ppn` is the unique identifier of a supervisor linked to the PhD dissertation (character)
* `title` is the title of the dissertation, in French (character)
* `phd` is the unique identifier of the dissertation (character)

The `phd.csv` contains many duplicated dissertations due to the fact that several supervisors can be linked to the same dissertation (as supervisors, co-supervisors or members of the examination board).

`nfo.csv` contains __PhD details__:

* `phd` is the unique identifier of the dissertation (character)
* `date_start` is the start date of the dissertation when available (character, yyyy-mm-dd)
* `date_end` is the start date of the dissertation when available (character, yyyy-mm-dd)
* `discipline` is the [Dewey decimal code](https://en.wikipedia.org/wiki/Dewey_Decimal_Classification) of the dissertation when available (character)
* `author` is the author of the dissertation (character, "family name, first name")
* `supervisor` is the supervisor of the dissertation (character, "family name, first name")
* `jury` is the examination board of the dissertation when available (character)
* `institution` is the university in which the PhD candidate is/was registered (character)
* `organization` is the research lab to which the PhD candidate was affiliated (character)
* `title` is the title of the dissertation, in French (character)

The raw XML files on which the `nfo.csv` dataset is based will be downloaded to the `data` folder. These files do _not_ contain the full information that is displayed on the Web page of the dissertation to which they correspond.

The variables stored in `nfo.csv` are relatively messy:

- The `date_start` and `date_end` variables are mutually exclusive: the data does not contain the start date of completed PhD dissertations. In a few cases, both dates are missing.
- The `discipline` and `supervisor` variables might contain more than one value for a single dissertation, in which case the values are separated by semicolons.
- The `jury` variable is formatted as "family name 1, first name 1 family name 2, first name 2" and so on. It sometimes contains duplicated names, and sometimes (but not always) contains the name of the supervisor.
- The `institution` variable might contain more than one value, in which case the values are separated by " -- ". In most cases, the first value is a university, and the second value is a doctoral school. In the case of joint PhDs, the string contains two universities.
- The `discipline`, `supervisor`, `jury` and `organization` variables contain varying amounts of missing values (only a few for the `discipline` and `supervisor` variables, lots for the `jury` and `organization` variables).

The `ppn` (supervisors) and `phd` (dissertations) variables are valid URLs at the `theses.fr` address. The `phd` variable is the French "[National PhD Number](http://documentation.abes.fr/sudoc/formats/unmb/zones/029.htm)" (_numéro national de thèse_).
