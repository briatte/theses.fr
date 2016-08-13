library(dplyr)
# library(rvest)
library(stringr)
library(readr)

library(ggnetwork)
library(ggplot2)
library(network)

d <- read_csv("nfo.csv")

e <- d$discipline[ str_count(d$discipline, ";") > 0 ]
e <- lapply(e, function(x) {
  x <- str_split(x, ";") %>% unlist %>% unique
  expand.grid(i = x, j = x, stringsAsFactors = FALSE) %>%
    filter(i != j)
}) %>% bind_rows

e <- apply(e, 1, str_c, collapse = "///") %>%
  table %>%
  as.data.frame %>%
  mutate(i = str_extract(., "^\\d{3}"),
         j = str_extract(., "\\d{3}$")) %>%
  select(i, j, w = Freq) %>%
  arrange(-w)

e <- filter(e, w > 8)

# same-id ties
e$color = (str_sub(e$i, 1, 1) == str_sub(e$j, 1, 1))
e$color[ e$color ] = str_sub(e$i[ e$color ], 1, 1)
e$color[ str_length(e$color) > 1 ] = "x"

n <- network(e[, 1:2], directed = FALSE)
set.edge.attribute(n, "weight", e[, 3])
set.edge.attribute(n, "size", as.integer(10 * log10(n %e% "weight")) / 10)
set.edge.attribute(n, "color", e$color)

n %v% "degree" <- sna::degree(n)
n %v% "id" <- str_sub(network.vertex.names(n), 1, 1)

topics <- c(
  "0" = "0xx: gen",
  "1" = "1xx: phil-psy",
  "2" = "2xx: rel",
  "3" = "3xx: soc",
  "4" = "4xx: lang",
  "5" = "5xx: sci",
  "6" = "6xx: tech",
  "7" = "7xx: art",
  "8" = "8xx: lit",
  "9" = "9xx: hist-geo",
  "x" = "grey"
)

colors <- c(RColorBrewer::brewer.pal(11, "Set3")[ -9 ], "#d9d9d9")
names(colors) <- names(topics)

ggplot(ggnetwork(n), aes(x, y, xend = xend, yend = yend)) +
  geom_edges(aes(size = log10(weight), color = color), alpha = 0.5) +
  geom_nodelabel(aes(fill = id, #size = degree,
                    label = vertex.names), label.size = 0) +
  # scale_color_gradient(low = "grey90", high = "tomato") +
  scale_color_manual("", values = colors, labels = topics) +
  scale_fill_manual("", values = colors, labels = topics) +
  scale_size_continuous(range = c(0.5, 2.5)) +
  guides(color = FALSE, size = FALSE) +
  theme_blank()

table(n %v% "id")

# ggsave("network_of_disciplines.png", width = 12, height = 10)
# ggsave("network_of_disciplines.pdf", width = 12, height = 10)
