library(dplyr)
library(rvest)
library(stringr)
library(readr)

dir.create("data", showWarnings = FALSE)

f <- "nfo.csv"

j <- read_csv("phd.csv")$phd %>%
  unique %>%
  sample

# exclude problematic (non-empty, invalid XML) file(s)
j <- j[ !j %in% c("s19430") ]

if (!file.exists(f)) {
  
  d <- data_frame()
  
} else {
  
  d <- read_csv(f)
  j <- j[ !j %in% d$phd ]
  
}

cat("Scraping", length(j), "files\n")

for (i in j) {
  
  cat("[", str_pad(i, 12, "left"), "]")
  
  r <- str_c("data/", i, ".xml")
  
  if (!file.exists(r)) {
    
    e <- try(str_c("http://www.theses.fr/", i, ".xml") %>%
          download.file(., r, mode = "wb", quiet = TRUE),
        silent = TRUE)
    
  }
  
  if (file.exists(r) && file.info(r)$size > 0) {
    
    r <- read_html(r)
    
    r <- data_frame(
      phd = i,
      date_start = html_node(r, "thesis created") %>% html_text %>%
        ifelse(str_length(.) == 10, ., NA), # some entries are missing/malformed
      date_end = html_node(r, "dateaccepted") %>% html_text %>%
        ifelse(str_length(.) == 10, ., NA), # some entries are missing/malformed
      discipline = html_nodes(r, "subject") %>% html_attr("rdf:resource") %>%
        na.omit %>%
        .[ str_detect(., "dewey") ] %>%
        str_replace_all("\\D", "") %>%
        str_c(collapse = ";") %>%  # multiple entries allowed
        ifelse(!length(.), NA, .), # some entries are missing
      author = c(
        html_node(r, "aut") %>% html_text,
        html_node(r, "dis") %>% html_text) %>%
        na.omit,
      supervisor = html_nodes(r, "ths") %>% html_text %>%
        str_c(collapse = ";") %>%  # multiple entries allowed
        ifelse(!length(.), NA, .), # some entries are missing
      jury = html_nodes(r, xpath = "//comment()") %>%
        html_text %>%
        .[ str_detect(., "^Jury ou rapporteurs") ] %>%
        ifelse(!length(.), NA, .) %>% # some entries are missing
        str_replace("Jury ou rapporteurs / Committee or readers ", ""),
      institution = html_nodes(r, "dgg") %>% html_text %>%
        str_c(collapse = " -- "), # university/-ies -- doctoral school
      organization = html_node(r, "contributor organization") %>% html_text %>%
        ifelse(!length(.), NA, .), # research affiliation
      title = html_node(r, "thesis title") %>% html_text
    )
        
    cat(":", r$author, "\n")
    
    stopifnot(nrow(r) == 1) # unique data row
    stopifnot(!is.na(r$author)) # nonmissing author
    
    d <- rbind(d, r)
    
  } else if (file.exists(r) && !file.info(r)$size) {
    
    cat(": no data\n")
    file.remove(r)
    
  } else {
    
    cat(":", e[1])
    
  }

  if (!which(i == j) %% 100) {
    
    write_csv(d, f)
    cat("\nSaved", nrow(d), "rows.\n")
    
  }
  
}

write_csv(d, f)
