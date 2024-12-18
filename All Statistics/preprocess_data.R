# File: preprocess_data.R
library(datavolley)
library(dplyr)
library(tidyr)

#TODO TO be changed with path you are using in your own PC!
setwd("C:/Users/mirko/Documents/GitHub/CuneoWebsite.io/All Statistics")

# Data processing function
process_data <- function() {
  # Read and process DVW files
  #d <- list.files("Scout/", pattern = "dvw$", full.names = TRUE)
  d <- list.files("B1_Scout/", pattern = "dvw$", full.names = TRUE)
  lx <- list()
  # Read each file with error handling
  for (fi in seq_along(d)) {
    tryCatch({
      lx[[fi]] <- dv_read(d[fi], insert_technical_timeouts = FALSE)
    }, error = function(e) {
      message("Error reading file ", d[fi], ": ", e$message)
      # If the error is specifically about the [3SCOUT] section, try to read without it
      if (grepl("\\[3SCOUT\\]", e$message)) {
        message("Attempting to read file without [3SCOUT] section")
        file_content <- readLines(d[fi])
        scout_index <- grep("\\[3SCOUT\\]", file_content)
        if (length(scout_index) > 0) {
          file_content <- file_content[1:(scout_index-1)]
          temp_file <- tempfile(fileext = ".dvw")
          writeLines(file_content, temp_file)
          lx[[fi]] <- dv_read(temp_file, insert_technical_timeouts = FALSE)
          file.remove(temp_file)
        }
      }
    })
  }

    ## now extract the play-by-play component from each and bind them together
  px <- list()
  for (fp in seq_along(lx)) px[[fp]] <- plays(lx[[fp]])
  px <- do.call(rbind, px)
  
  unique_player_names <- unique(px$player_name)
  print(unique_player_names)
  unique_player_names <- unique_player_names[!is.na(unique_player_names)]
  print(unique_player_names)
  
  battuta_table <- px %>%
    filter(skill == "Serve") %>%
    group_by(player_name) %>%
    summarize(
      Bat_Tot = n(),
      Bat_Positiva = sum(evaluation_code == '#' | evaluation_code == '+' | evaluation_code == '!') / n(),
      Bat_Perfetta = sum(((evaluation_code == '#')) / n()),
    )
  
  ricezione_table <- px %>%
    filter(skill == "Reception") %>%
    group_by(player_name) %>%
    summarize(
      Rice_Tot = n(),
      Rice_Positiva = sum(evaluation_code == '#' | evaluation_code == '+') / n(),
      Ace = sum(evaluation_code == '=') / n(),
      Rice_Efficienza = (sum(evaluation_code == '#') + sum(evaluation_code == '+') - sum(evaluation_code == '=')-sum(evaluation_code == '/')) / n()
    )
  
  attack_table <- px %>%
    filter(skill == "Attack") %>%
    group_by(player_name) %>%
    summarize(
      Att_Tot = n(),
      Att_Perfetto = sum(evaluation_code == '#') / n(),
      Att_Efficienza = (sum(evaluation_code == '#') - sum(evaluation_code == '=') - + sum(evaluation_code == '/') ) / n()
    )
  
  muro_table <- px %>%
    filter(skill == "Block") %>%
    group_by(player_name) %>%
    summarize(
      Muro_tot = n(),
      Muro_positivo = sum(evaluation_code == '#' | evaluation_code == '+' | evaluation_code == '!') / n(),
      Muro_negativo = sum(evaluation_code == '-' | evaluation_code == '=' | evaluation_code == '/') / n(),
    )
  
  punti_totali_table <- px %>%
    filter(skill %in% c("Block", "Attack", "Serve")) %>%
    group_by(player_name) %>%
    summarize(Punti_tot = sum(evaluation_code == '#'))
  
  errori_table <- px %>%
    filter(skill %in% c("Block", "Attack", "Serve", "Reception", "Set")) %>%
    group_by(player_name) %>%
    summarize(Err = sum(evaluation_code == '='))
  
  efficiency_table <- punti_totali_table %>%
    left_join(errori_table, by = "player_name")
  
  efficiency_table <- efficiency_table %>%
    mutate(Eff = Punti_tot - Err)
  
  # Read and process SQ files for roles
  #sq_files <- list.files("Elenco Giocatori Squadra", pattern = "\\.sq$", full.names = TRUE)
  sq_files <- list.files("B1_SQ", pattern = "\\.sq$", full.names = TRUE)
  # Initialize an empty list to store the dataframes
  df_list <- list()
  
  # Loop through each .sq file
  for (file in sq_files) {
    file_content <- readLines(file)
    team_line <- strsplit(file_content[2], "\t")[[1]] #Team :-)
    team_name <- team_line[2]
    data_lines <- file_content[-c(1, 2)]
    split_data <- strsplit(data_lines, "\t")
    df <- do.call(rbind, lapply(split_data, function(x) c(x[3], x[9], x[10])))
    df <- as.data.frame(df, stringsAsFactors = FALSE)
    colnames(df) <- c("Cognome", "Nome", "Ruolo")
    df$player_name <- paste(df$Nome, df$Cognome)
    df <- df %>%
      mutate(role = case_when(
        Ruolo == "1" ~ "Libero",
        Ruolo == "2" ~ "Schiacciatore",
        Ruolo == "3" ~ "Opposto",
        Ruolo == "4" ~ "Centrale",
        Ruolo == "5" ~ "Palleggiatore",
        TRUE ~ "Unknown"
      ))
    # Add the team name column to each row
    df$team <- team_name
    # Add the processed dataframe to the list
    df_list[[file]] <- df
  }
  # Combine all dataframes into one
  combined_role_df <- do.call(rbind, df_list)
  
  # Select only the relevant columns
  role <- combined_role_df %>%
    select(player_name, role, team)
  
  # Get all unique player names from all tables
  all_players <- unique(c(
    battuta_table$player_name,
    ricezione_table$player_name,
    attack_table$player_name,
    muro_table$player_name,
    efficiency_table$player_name
  ))
  
  # Create a base dataframe with all player names
  final_table <- data.frame(player_name = all_players)
  
  # Join all tables
  final_table <- final_table %>%
    left_join(battuta_table, by = "player_name") %>%
    left_join(ricezione_table, by = "player_name") %>%
    left_join(attack_table, by = "player_name") %>%
    left_join(muro_table, by = "player_name") %>%
    left_join(efficiency_table, by = "player_name")
  #%>% left_join(role, by = "player_name") 
  
  final_table[is.na(final_table)] <- 0
  
  final_table <- final_table%>% left_join(role, by = "player_name") 
  
  # Identifying percentage columns based on naming patterns
  percentage_columns <- grep(
    pattern = "Positiv|Perfett|Efficienza|positivo|negativo|Ace",
    x = names(final_table),
    value = TRUE
  )
  # Convert the columns to numeric and then to percentages
  final_table[percentage_columns] <- lapply(final_table[percentage_columns], function(x) {
    x <- as.numeric(as.character(x))  # Convert to numeric
    round(x * 100, 2)                 # Multiply by 100 and round to 2 decimal places
  })
  
  return(final_table)
}

# Run the data processing
final_table <- process_data()

# Save the processed data
saveRDS(final_table, "final_table_ItalyB1.rds")
#warnings()
