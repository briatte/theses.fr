library(dplyr)
library(rvest)
library(stringr)
library(readr)

f <- "phd.csv"

j <- read_csv("dir.csv")$ppn %>%
  na.omit

# loop until there are no pages left
while (length(j) > 0) {
  
  if (!file.exists(f)) {
    
    d <- data_frame()
    
  } else {
    
    # append to existing data
    d <- read_csv(f)
    
    j <- j[ !j %in% d$ppn ]
    
  }
  
  # number of existing data rows
  n <- nrow(d)
  
  cat("Scraping", length(j), "pages...\n")
  
  # scrape in random order
  for (i in sample(j)) {
    
    cat("[", "PPN", str_pad(i, 6, side = "left"), "]")
    
    p <- try(
      str_c("http://www.theses.fr/", i) %>%
        read_html %>%
        html_nodes(".informations h2 a"),
      silent = TRUE)
    
    if ("try-error" %in% class(p)) {
      
      cat(":", p[1])
      
    } else if (!length(p)) {
      
      cat(": error (no data)\n")
      
    } else {
      
      p <- data_frame(
        ppn = i,
        title = html_text(p) %>% str_trim,
        phd = html_attr(p, "href")
      )
      
      d <- rbind(d, p)
      
      cat(":", nrow(d), "rows", n_distinct(d$phd), "PhDs\n")
      write_csv(d, f)
      
    }
    
  }
  
  # break if no new data found
  if (nrow(d) == n) {
    
    cat("Stopping: no new data\n")
    break
    
  }
  
}

# top supervisors by number of dissertations supervised or examined
group_by(d, ppn) %>%
  summarise(n = n()) %>%
  arrange(-n) %>%
  left_join(read_csv("dir.csv") %>%
              select(ppn, personne),
            by = "ppn")
