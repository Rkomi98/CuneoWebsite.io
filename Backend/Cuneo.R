#install.packages(c("datavolley", "ovlytics"))
library(datavolley)
library(ggplot2)
library(dplyr)
library(scales)
#library(formattable) 
#library(ovlytics)

filename <- "Assets/&##Backup##_R00 HONDA O-ALLIANZ V.dvw" #C:/Users/mirko/Documents/GitHub/CuneoWebsite.io/
#d <- dir("C:/Users/mirko/OneDrive - Politecnico di Milano/Altro/Volley/Conco2324/Parella Torino/Ritorno/", pattern = "dvw$", full.names = TRUE)

teamName = 'HONDA OLIVERO S.BERNARDO CUNEO'
x <- dv_read(filename)
serve_idx <- find_serves(plays(x))
table(plays(x)$team[serve_idx])

d <- dir("Assets/", pattern = "dvw$", full.names = TRUE) #C:/Users/mirko/Documents/GitHub/CuneoWebsite.io/
lx <- list()
## read each file
for (fi in seq_along(d)) lx[[fi]] <- dv_read(d[fi], insert_technical_timeouts = FALSE)
## now extract the play-by-play component from each and bind them together
px <- list()
for (fi in seq_along(lx)) px[[fi]] <- plays(lx[[fi]])
px <- do.call(rbind, px)


#, end_zone == 5
table_data <- px %>% 
  dplyr::filter(skill == "Serve", team == teamName) %>% 
  group_by(player_name) %>% 
  dplyr::summarize(
    N_battute = n(),
    count_perfette = sum(evaluation_code == "#", na.rm = TRUE),
    count_positive = sum(evaluation_code == "+", na.rm = TRUE),
    #count_escalamative = sum(evaluation_code == "!", na.rm = TRUE),
    #count_negative = sum(evaluation_code == "-", na.rm = TRUE),
    count_errori = sum(evaluation_code == "=", na.rm = TRUE),
    positività = percent((count_positive + count_perfette)/N_battute, digits = 1),
    efficienza = percent((count_positive + count_perfette - count_errori)/N_battute, digits = 1),
  )

data_plot <- table_data

table_data

# Calculate cumulative statistics for the team
team_total <- table_data %>%
  summarise(
    N_battute = sum(N_battute),
    count_perfette = sum(count_perfette),
    count_positive = sum(count_positive),
    count_errori = sum(count_errori),
    positività = percent(sum(count_positive + count_perfette) / sum(N_battute), digits = 1),
    efficienza = percent(sum(count_positive + count_perfette - count_errori) / sum(N_battute), digits = 1)
  ) %>%
  mutate(player_name = "TOT. Squadra")  # Add a player_name for the team total row

# Combine the team total row with the original table data
table_data_with_total <- bind_rows(table_data, team_total)

# Print the table with the team total row
table_data_with_total

library(kableExtra)

# Apply custom CSS styling to the entire table
# Reorder columns to make positività the second column
table_data <- table_data_with_total %>%
  #select(-efficienza) %>%
  select(1, 7, everything())

# Apply custom CSS styling to the entire table
styled_table <- table_data %>%
  kable("html") %>%
  kable_styling(full_width = FALSE, htmltable_class = 'styled-table', html_font = '"Be Vietnam Pro", sans-serif') %>%
  row_spec(9, bold = TRUE) %>%
  column_spec(2, background = ifelse(table_data$efficienza >= percent(0.3), "lightgreen",ifelse(table_data$efficienza > percent(0.25) & table_data$efficienza < percent(0.3), "yellow", "lightcoral")))

  #row_spec(which(table_data$efficienza > 0.2 & table_data$efficienza < 0.3), background = "yellow") %>%
  #row_spec(which(table_data$efficienza <= 0.2), background = "lightcoral")

# Save the styled table to an HTML file
writeLines(as.character(styled_table), "Battuta_tab.html")


library(plotly)

fig <- plot_ly(data_plot, 
               x = ~positività*100, 
               y = ~efficienza*100,
               type = 'scatter', 
               mode = 'markers', 
               hovertemplate = paste('<i>Player</i>: %{text}',
                                     '<br><b>Positività (%)</b>: %{x})',
                                     '<br><b>Efficienza (%)</b>: %{y}',
                                     '<br><b>Battuta</b>: %{marker.size}<extra></extra>'),
               color = ~positività,
               marker = list(size = ~N_battute, sizemode = "area", sizeref = 0.005, opacity = 0.5),
               text = ~player_name
)

fig <- fig %>% layout(title = 'Qualità Battuta',
                      xaxis = list(title = 'Positività', showgrid = TRUE),
                      yaxis = list(title = 'Efficienza', showgrid = TRUE)
)

fig

# Assuming you have your data frame 'data_plot' with columns 'player_name' and 'efficienza'

# Calculate the color based on efficienza values
data_plot$color <- ifelse(data_plot$efficienza < 0.25, "red",
                          ifelse(data_plot$efficienza > 0.30, "green", "yellow"))


fig <- plot_ly(
  x = data_plot$player_name,
  y = round(data_plot$efficienza, digits = 2),
  marker = list(color = data_plot$color),
  name = "Efficienza in Battuta",
  type = "bar",
  text = round(data_plot$efficienza, digits = 2), textposition = 'auto', marker = list(color = 'rgb(158,202,225)', line = list(color = 'rgb(8,48,107)', width = 1.5)))

fig <- fig %>% layout(title = "Efficienza in Battuta",

         xaxis = list(title = ""),

         yaxis = list(title = ""))


fig

# Customize other plot settings as needed


library(htmlwidgets)

# Assuming 'fig' is your Plotly figure
saveWidget(fig, "Battuta.html")

#, end_zone == 5
table_data <- px %>% 
  dplyr::filter(skill == "Reception", team == teamName) %>% 
  group_by(player_name) %>% 
  dplyr::summarize(
    N_receptions = n(),
    count_perfette = sum(evaluation_code == "#", na.rm = TRUE),
    count_positive = sum(evaluation_code == "+", na.rm = TRUE),
    #count_escalamative = sum(evaluation_code == "!", na.rm = TRUE),
    #count_negative = sum(evaluation_code == "-", na.rm = TRUE),
    count_errori = sum(evaluation_code == "=", na.rm = TRUE),
    positività = percent((count_positive + count_perfette)/N_receptions, digits = 0),
    efficienza = percent((count_positive + count_perfette - count_errori)/N_receptions, digits = 0),
  )

data_plot <- table_data

table_data

# Compute total statistics for the team
total_stats <- table_data %>%
  summarise(
    N_receptions = sum(N_receptions),
    count_perfette = sum(count_perfette),
    count_positive = sum(count_positive),
    count_errori = sum(count_errori),
    positività = percent(sum(count_positive + count_perfette) / sum(N_receptions)),
    efficienza = percent(sum(count_positive + count_perfette - count_errori) / sum(N_receptions))
  ) %>%
  mutate(player_name = "TOT. Squadra")  # Add a player_name for the team total row

# Combine the team total row with the original table data
table_data_with_total <- bind_rows(table_data, total_stats)

# Print the table with the team total row
table_data_with_total

table_data <- table_data_with_total %>%
  #select(-efficienza) %>%
  select(everything())

# Apply custom CSS styling to the entire table
styled_table <- table_data %>%
  kable("html") %>%
  kable_styling(full_width = FALSE, htmltable_class = 'styled-table', html_font = '"Be Vietnam Pro", sans-serif') %>%
  row_spec(nrow(table_data), bold = TRUE) %>%
  column_spec(2, 
              background = case_when(
                (table_data$player_name == "Serena Scognamillo" | table_data$player_name == "Federica Ferrario") ~ ifelse(table_data$efficienza >= percent(0.56), "lightgreen", ifelse(table_data$efficienza > percent(0.48) & table_data$efficienza < percent(0.56), "yellow", "lightcoral")),
                (table_data$player_name == "Lena Stigrot" | table_data$player_name == "Anna Haak") ~ ifelse(table_data$efficienza >= percent(0.37), "lightgreen", ifelse(table_data$efficienza > percent(0.31) & table_data$efficienza < percent(0.37), "yellow", "lightcoral")),
                (table_data$player_name == "Alice Tanase" | table_data$player_name == "Madison Kubik") ~ ifelse(table_data$efficienza >= percent(0.43), "lightgreen", ifelse(table_data$efficienza > percent(0.37) & table_data$efficienza < percent(0.43), "yellow", "lightcoral")),
                TRUE ~ ifelse(table_data$efficienza >= percent(0.42), "lightgreen", ifelse(table_data$efficienza > percent(0.41) & table_data$efficienza < percent(0.42), "orange", "red"))
              )
              )

# Save the styled table to an HTML file
writeLines(as.character(styled_table), "Ricezione_tab.html")

fig <- plot_ly(data_plot, 
               x = ~positività*100, 
               y = ~efficienza*100,
               type = 'scatter', 
               mode = 'markers', 
               hovertemplate = paste('<i>Player</i>: %{text}',
                                     '<br><b>Positività(%)</b>: %{x}',
                                     '<br><b>Efficienza(%)</b>: %{y}',
                                     '<br><b>Ricezione</b>: %{marker.size}<extra></extra>'),
               color = ~positività,
               marker = list(size = ~N_receptions, sizemode = "area", sizeref = 0.005, opacity = 0.5),
               text = ~player_name
)

fig <- fig %>% layout(title = 'Qualità Ricezione',
                      xaxis = list(title = 'Positività', showgrid = TRUE),
                      yaxis = list(title = 'Efficienza', showgrid = TRUE)
)
fig

# Assuming you have your data frame 'data_plot' with columns 'player_name' and 'efficienza'

# Calculate the color based on efficienza values
data_plot <- table_data %>%
  mutate(color = case_when(
    (player_name %in% c("Serena Scognamillo", "Federica Ferrario") & efficienza >= percent(0.56)) | 
    (player_name %in% c("Lena Stigrot", "Anna Haak") & efficienza >= percent(0.37)) | 
    (player_name %in% c("Alice Tanase", "Madison Kubik") & efficienza >= percent(0.43)) |
    efficienza >= percent(0.42) ~ "lightgreen",
    
    (player_name %in% c("Serena Scognamillo", "Federica Ferrario") & efficienza > percent(0.48) & efficienza < percent(0.56)) | 
    (player_name %in% c("Lena Stigrot", "Anna Haak") & efficienza > percent(0.31) & efficienza < percent(0.37)) | 
    (player_name %in% c("Alice Tanase", "Madison Kubik") & efficienza > percent(0.37) & efficienza < percent(0.43)) |
    (efficienza > percent(0.41) & efficienza < percent(0.42)) ~ "orange",
    
    (player_name %in% c("Serena Scognamillo", "Federica Ferrario") & efficienza <= percent(0.48) ) | 
    (player_name %in% c("Lena Stigrot", "Anna Haak") & efficienza <= percent(0.31)) | 
    (player_name %in% c("Alice Tanase", "Madison Kubik") & efficienza <= percent(0.37)) |
    efficienza < percent(0.41) ~ "lightcoral",
    
    TRUE ~ NA_character_
  ))



fig <- plot_ly(
  x = data_plot$player_name,
  y = round(data_plot$efficienza, digits = 2),
  marker = list(color = data_plot$color),
  name = "Efficienza in Ricezione",
  type = "bar",
  text = round(data_plot$efficienza, digits = 2), textposition = 'auto', marker = list(color = 'rgb(158,202,225)', line = list(color = 'rgb(8,48,107)', width = 1.5)))

fig <- fig %>% layout(title = "Efficienza in Ricezione",

         xaxis = list(title = ""),

         yaxis = list(title = ""))


fig

saveWidget(fig, "Ricezione.html")

#  end_zone == 5
table_data <- px %>% 
  dplyr::filter(skill == "Attack", team == teamName) %>% 
  group_by(player_name) %>% 
  dplyr::summarize(
    N_attacks = n(),
    count_perfette = sum(evaluation_code == "#", na.rm = TRUE),
    count_positive = sum(evaluation_code == "+", na.rm = TRUE),
    #count_escalamative = sum(evaluation_code == "!", na.rm = TRUE),
    #count_negative = sum(evaluation_code == "-", na.rm = TRUE),
    count_errori = sum(evaluation_code == "=", na.rm = TRUE),
    positività = percent((count_positive + count_perfette)/N_attacks, digits = 0),
    efficienza = percent((count_positive + count_perfette - count_errori)/N_attacks, digits = 0),
  )

data_plot <- table_data

table_data

# Compute the total statistics
total_stats <- table_data %>%
  summarise(
    N_attacks = sum(N_attacks),
    count_perfette = sum(count_perfette),
    count_positive = sum(count_positive),
    count_errori = sum(count_errori),
    positività = percent(sum(count_positive + count_perfette) / sum(N_attacks)),
    efficienza = percent(sum(count_positive + count_perfette - count_errori) / sum(N_attacks))
  ) %>%
  mutate(player_name = "TOT. Squadra")  # Add a player_name for the team total row

# Add the total row to the table data
table_data <- bind_rows(table_data, total_stats)

table_data <- table_data %>%
  #select(-efficienza) %>%
  select(everything())

# Apply custom CSS styling to the entire table
styled_table <- table_data %>%
  kable("html") %>%
  kable_styling(full_width = FALSE, htmltable_class = 'styled-table', html_font = '"Be Vietnam Pro", sans-serif') %>%
  row_spec(nrow(table_data), bold = TRUE) %>%
  column_spec(2, background = case_when(
                (table_data$player_name == "Anna Adelusi" | table_data$player_name == "Terry Ruth Enweonwu") ~ ifelse(table_data$efficienza >= percent(0.27), "lightgreen", ifelse(table_data$efficienza > percent(0.24) & table_data$efficienza < percent(0.27), "yellow", "lightcoral")),
                (table_data$player_name == "Anna Haak" | table_data$player_name == "Lena Stigrot") ~ ifelse(table_data$efficienza >= percent(0.34), "lightgreen", ifelse(table_data$efficienza > percent(0.30) & table_data$efficienza < percent(0.34), "yellow", "lightcoral")),
                (table_data$player_name == "Alice Tanase" | table_data$player_name == "Madison Kubik") ~ ifelse(table_data$efficienza >= percent(0.24), "lightgreen", ifelse(table_data$efficienza > percent(0.20) & table_data$efficienza < percent(0.24), "yellow", "lightcoral")),
                (table_data$player_name == "Saly Thior" | table_data$player_name == "Amandha Sylves" | table_data$player_name == "Anna Hall" | table_data$player_name == "Beatrice Molinaro") ~ ifelse(table_data$efficienza >= percent(0.44), "lightgreen", ifelse(table_data$efficienza > percent(0.38) & table_data$efficienza < percent(0.44), "yellow", "lightcoral")),
                TRUE ~ ifelse(table_data$efficienza >= percent(0.42), "lightgreen", ifelse(table_data$efficienza > percent(0.41) & table_data$efficienza < percent(0.42), "orange", "red"))
              )
              )

# Save the styled table to an HTML file
writeLines(as.character(styled_table), "Attacco_tab.html")

fig <- plot_ly(data_plot, 
               x = ~positività, 
               y = ~efficienza,
               type = 'scatter', 
               mode = 'markers', 
               hovertemplate = paste('<i>Player</i>: %{text}',
                                     '<br><b>Positività(%)</b>: %{x}',
                                     '<br><b>Efficienza(%)</b>: %{y}',
                                     '<br><b>Attacchi</b>: %{marker.size}<extra></extra>'),
               color = ~positività,
               marker = list(size = ~N_attacks, sizemode = "area", sizeref = 0.005, opacity = 0.5),
               text = ~player_name
)

fig <- fig %>% layout(title = 'Qualità Attacco',
                      xaxis = list(title = 'Positività', showgrid = FALSE),
                      yaxis = list(title = 'Efficienza', showgrid = FALSE)
)

fig

# Add a new column 'color' based on the rules provided
data_plot <- table_data %>%
  mutate(color = case_when(
    (player_name %in% c("Anna Adelusi", "Terry Ruth Enweonwu") & efficienza >= percent(0.27)) | 
    (player_name %in% c("Anna Haak", "Lena Stigrot") & efficienza >= percent(0.34)) | 
    (player_name %in% c("Alice Tanase", "Madison Kubik") & efficienza >= percent(0.24)) |
    (player_name %in% c("Saly Thior", "Amandha Sylves", "Anna Hall", "Beatrice Molinaro") & efficienza >= percent(0.44)) |
    efficienza >= percent(0.42) ~ "lightgreen",
    
    (player_name %in% c("Anna Adelusi", "Terry Ruth Enweonwu") & efficienza > percent(0.24) & efficienza < percent(0.27)) | 
    (player_name %in% c("Anna Haak", "Lena Stigrot") & efficienza > percent(0.30) & efficienza < percent(0.34)) | 
    (player_name %in% c("Alice Tanase", "Madison Kubik") & efficienza > percent(0.20) & efficienza < percent(0.24)) |
    (player_name %in% c("Saly Thior", "Amandha Sylves", "Anna Hall", "Beatrice Molinaro") & efficienza > percent(0.38) & efficienza < percent(0.44)) |
    (efficienza > percent(0.41) & efficienza < percent(0.42)) ~ "orange",
    
    (player_name %in% c("Anna Adelusi", "Terry Ruth Enweonwu") & efficienza <= percent(0.24)) | 
    (player_name %in% c("Anna Haak", "Lena Stigrot") & efficienza <= percent(0.30)) | 
    (player_name %in% c("Alice Tanase", "Madison Kubik") & efficienza <= percent(0.20)) |
    (player_name %in% c("Saly Thior", "Amandha Sylves", "Anna Hall", "Beatrice Molinaro") & efficienza <= percent(0.38)) |
    efficienza < percent(0.41) ~ "lightcoral",
    
    TRUE ~ NA_character_
  ))


fig <- plot_ly(
  x = data_plot$player_name,
  y = round(data_plot$efficienza, digits = 2),
  marker = list(color = data_plot$color),
  name = "Efficienza in Attacco",
  type = "bar",
  text = round(data_plot$efficienza, digits = 2), textposition = 'auto', marker = list(color = 'rgb(158,202,225)', line = list(color = 'rgb(8,48,107)', width = 1.5)))

fig <- fig %>% layout(title = "Efficienza in Attacco",

         xaxis = list(title = ""),

         yaxis = list(title = ""))


fig

saveWidget(fig, "Attacco.html")

library(ggplot2)
library(htmlwidgets)

for (i in 1:6) {
  attack_rate <- px %>% 
    dplyr::filter(skill == "Attack", team == teamName, visiting_setter_position == i) %>%
    group_by(start_zone) %>% 
    dplyr::summarize(n_attacks = n()) %>%
    mutate(rate = n_attacks/sum(n_attacks)) %>% 
    ungroup

  attack_rate <- cbind(attack_rate, dv_xy(attack_rate$start_zone, end = "lower"))

  tm2i <- attack_rate$team == teams(px)[2]
  attack_rate[tm2i, c("x", "y")] <- dv_flip_xy(attack_rate[tm2i, c("x", "y")])

  attack_rate$rate_rounded <- round(attack_rate$rate, 2)

  fig2 <- ggplot(attack_rate, aes(x, y, fill = rate_rounded)) + 
    geom_tile() + 
    geom_text(aes(label = paste0(round(rate_rounded * 100, 2), "%")), color = "black", size = 3) +
    ggcourt(labels = teams(px)) +
    scale_fill_gradient2(name = "Attack rate (%)", labels = scales::percent_format(accuracy = 0.01))

  html_name <- paste0("Distribuzione", i, ".png")
  
  # Save the plot as an HTML file
  ggsave(html_name, plot = fig2, width = 8, height = 6, units = "in", dpi = 300)
}

