library(dplyr)
library(rvest)
library(stringr)
library(readr)

f <- "dir.csv"

# query
q <- str_c(
  "http://www.theses.fr/personnes/?q=",
  "fq=dateSoutenance:[1965-01-01T23:59:59Z%2BTO%2B2016-12-31T23:59:59Z]",
  # line below sets query to 'sc. soc., socio., anthropo.' and 'sc. po.'
  "checkedfacets=role=directeurThese;oaiSetSpec=ddc:300;oaiSetSpec=ddc:320;",
  "start=0&status=&access=&prevision=",
  "filtrepersonne=",
  "zone1=titreRAs",
  "val1=&op1=AND",
  "zone2=auteurs",
  "val2=&op2=AND",
  "zone3=etabSoutenances",
  "val3=&op3=AND",
  "zone4=dateSoutenance",
  "val4a=",
  "val4b=",
  "type=",
  "format=xml",
  sep = "&"
)

# find page sequence
j <- read_xml(q) %>%
  xml_node("result") %>%
  xml_attr("numFound") %>%
  as.integer %>%
  seq(0, ., by = 10)

# loop until there are no pages left
while (length(j) > 0) {
  
  if (!file.exists(f)) {
    
    d <- data_frame()
    
  } else {
    
    # append to existing data
    d <- read_csv(f)
    d$ppn[ d$ppn == "null" ] <- NA
    
    j <- j[ !j %in% d$page ]
    
  }
  
  # number of existing data rows
  n <- nrow(d)
  
  cat("Scraping", length(j), "pages...\n")
  
  # scrape in random order
  for (i in sample(j)) {
    
    cat("[", "DIR", str_pad(i, 6, side = "left"), "]")
    
    p <- try(
      str_c("start=", i) %>%
        str_replace(q, "start=0", .) %>%
        read_xml,
      silent = TRUE)
    
    if (!"try-error" %in% class(p)) {
      
      p <- data_frame(
        page = i %>% as.integer,
        personne = xml_nodes(p, "str[name='personne']") %>% xml_text,
        personneNP = xml_nodes(p, "str[name='personneNP']") %>% xml_text,
        ppn = xml_nodes(p, "str[name='ppn']") %>% xml_text,
        actif = xml_nodes(p, "str[name='actif']") %>% xml_text#,
        #nbTheses = xml_nodes(p, "str[name='nbTheses']") %>% xml_text
      )
      
      d <- rbind(d, p)
      
      cat(":", nrow(d), "rows", sum(!is.na(d$ppn)), "PPNs\n")
      write_csv(d, f)
      
    } else {
      
      cat(":", p[1])

    }
    
  }
  
  # break if no new data found
  if (nrow(d) == n) {
    
    cat("Stopping: no new data\n")
    break
    
  }

}

cat("Done :", nrow(d), "rows", sum(!is.na(d$ppn)), "PPNs.\n")
