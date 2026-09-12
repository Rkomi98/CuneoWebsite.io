# -*- coding: utf-8 -*-
import pandas as pd
from datavolley import read_dv
import os
from flask import Flask, render_template, request # Import request
import re

# Initialize Flask app
app = Flask(__name__)

# Assign path for DataVolley files -- TODO to be changed!
#dvw_path_folder = "C:/Users/mirko/OneDrive - Politecnico di Milano/Altro/Volley/Conco2425/Olbia/"
dvw_path_folder =  "C:/Users/mirko/Documents/GitHub/CuneoWebsite.io/Scoreboard"
file_extension = ".dvw"

# Get a list of all files with the specified extension in the directory
file_list = [f for f in os.listdir(dvw_path_folder) if f.endswith(file_extension)]
print(f"Found {len(file_list)} .dvw files.")

# Initialize an empty DataFrame to store combined data
combined_df = pd.DataFrame()

def process_file(path):
    dv_instance = read_dv.DataVolley(os.path.join(dvw_path_folder, path))
    dv_instance.home_setswon = int(dv_instance.home_setswon or 0)
    dv_instance.visiting_setswon = int(dv_instance.visiting_setswon or 0)
    df = dv_instance.get_plays()
    print(df.columns)  # Debugging line to see the columns
    print(df.head())   # Optional: See the first few rows
    return df, dv_instance

# Process each file and combine data
for file_name in file_list:
    print(f"Processing file: {file_name}")  # Debugging line
    df_temp, dv_instance = process_file(file_name)
    combined_df = pd.concat([combined_df, df_temp], ignore_index=True)

def summarize_volleyball_set(plays):
    teams = plays['team'].dropna().unique()
    home_team = plays['home_team'].iloc[0]
    away_team = plays['visiting_team'].iloc[0]

    summary_data = []
    set_scores = []
    current_set = 1
    current_home_score = 0
    current_away_score = 0
    set_score_displayed = "0 - 0"

    current_timeouts = {'home': 0, 'away': 0}
    current_substitutions = {'home': 0, 'away': 0}

    home_set_wins = 0
    away_set_wins = 0

    def calculate_player_points(team):
        team_plays = plays[plays['team'] == team]
        player_points = {}
        for _, row in team_plays.iterrows():
            if row['skill'] in ['Attack', 'Serve', 'Block'] and row['evaluation_code'] == '#':
                player = row['player_name']
                if player not in player_points:
                    player_points[player] = {'Attack': 0, 'Serve': 0, 'Block': 0}
                player_points[player][row['skill']] += 1
        return player_points

    home_player_points = calculate_player_points(home_team)
    away_player_points = calculate_player_points(away_team)

    def include_all_players(players_df, player_points):
        all_players_points = {}
        for _, row in players_df.iterrows():
            name = row['player_name']
            if name not in player_points:
                all_players_points[name] = {'Attack': 0, 'Serve': 0, 'Block': 0}
            else:
                all_players_points[name] = player_points[name]
        return all_players_points

    def last_non_null_score(column, index, plays):
        return plays[column].iloc[index] if not pd.isna(plays[column].iloc[index]) else None

    home_player_points = include_all_players(dv_instance.players_home, home_player_points)
    away_player_points = include_all_players(dv_instance.players_visiting, away_player_points)

    summary_data.append({'team_name': home_team, 'home_team_points': home_player_points})
    summary_data.append({'team_name': away_team, 'visiting_team_points': away_player_points})

    for index, row in plays.iterrows():
        home_score = last_non_null_score('home_team_score', index, plays)
        away_score = last_non_null_score('visiting_team_score', index, plays)

        if home_score is not None:
            current_home_score = home_score
        if away_score is not None:
            current_away_score = away_score

        set_score_displayed = f"{current_home_score} - {current_away_score}"

        set_ended_by_code = row['code'].startswith('**') and row['code'].endswith('set')

        print(f"\nRow {index}: Code='{row['code']}', Set {current_set}, Score='{set_score_displayed}', Set Scores: {set_scores}") # DEBUG PRINT

        # In the loop, update current_set AFTER processing all set data
        if set_ended_by_code:
            set_result = set_score_displayed
            set_scores.append(set_result)
            # Move all resets AFTER appending to summary_data
            if current_home_score > current_away_score:
                home_set_wins += 1
            else:
                away_set_wins += 1
            current_set +=1
            # Finally reset scores and other counters for the next set
            current_home_score = 0
            current_away_score = 0
            set_score_displayed = "0 - 0"
            current_timeouts = {'home': 0, 'away': 0}
            current_substitutions = {'home': 0, 'away': 0}


        if row['code'].startswith('*T'):
            current_timeouts['home'] += 1
        elif row['code'].startswith('aT'):
            current_timeouts['away'] += 1
        if row['code'].startswith('*c'):
            current_substitutions['home'] += 1
        elif row['code'].startswith('ac'):
            current_substitutions['away'] += 1

    summary_data.append({
        'current_set': current_set,
        'team_set_wins': f"{home_set_wins} - {away_set_wins}",
        'timeouts': current_timeouts,
        'past_set_scores': set_scores,
        'set_score': set_score_displayed,
    })

    return summary_data

def get_team_players(players_df, player_points):
    team_players = []

    # Iterate through each player row in the DataFrame
    for _, player in players_df.iterrows():
        name = player['player_name']  # Ensure this column exists in the DataFrame
        short_name = player.get('short_name', name)
        print(short_name)
        role = player.get('role', '')  # Default to an empty string if role is missing
        player_number = player.get('player_number', 'N/A')  # Default to 'N/A' if missing

        # Get the player's points from player_points, default to 0 if not found
        points = player_points.get(name, {'Attack': 0, 'Serve': 0, 'Block': 0})

        formatted_player = {
            'name': name,
            'short_name': short_name,
            'role': role,
            'number': player_number,
            'display_name': name if role != 'C' else f"<b>{name}</b>",  # Bold for captain
            'background_color': 'yellow' if role == 'L' else 'transparent',  # Yellow for libero
            'points': {
                'attack': points.get('Attack', 0),
                'serve': points.get('Serve', 0),
                'block': points.get('Block', 0),
                'total': sum(points.values())  # Sum of all points
            }
        }
        team_players.append(formatted_player)

    return team_players

def print_team_summary(team_summary):
    print(f"\n{team_summary['team_name']} Team:")
    for player in team_summary['players']:
        # Ensure Block points are always printed
        block_points = player.get('block_points', 0)  # Default to 0 if block_points is not found

        print(f"  {player['player_name']}: "
              f"{player['total_points']} points "
              f"(Attack: {player['attack_points']}, "
              f"Serve: {player['serve_points']}, "
              f"Block: {block_points})")  # Ensure Block points are displayed

    print(f"  Team Total: {team_summary['team_total']} points")


# Flask route to render the scoreboard
@app.route('/')
def show_scoreboard():
    # Get the template name from the query parameters, default to 'scoreboard_minimal.html'
    template_name_param = request.args.get('template')
    if template_name_param:
        template_file = f'Scoreboard_minimal_{template_name_param}.html'
    else:
        template_file = 'Scoreboard_minimal.html' # Default template
    path_html = 'C:/Users/mirko/Documents/GitHub/CuneoWebsite.io/Scoreboard/templates/'

    # Check if the template file exists, if not, default to 'Scoreboard_minimal.html'
    template_path = os.path.join(path_html, template_file)
    if not os.path.exists(template_path):
        template_file = 'Scoreboard_minimal.html'
        print(f"Template file '{template_name_param}' not found, defaulting to 'Scoreboard_minimal.html'")

    
    # Generate summary data for the scoreboard
    summary_data = summarize_volleyball_set(combined_df)

    # Retrieve points dictionaries for both teams
    home_team_points = summary_data[0]['home_team_points']
    visiting_team_points = summary_data[1]['visiting_team_points']

    # Retrieve full player lists and match with points
    home_team_players = get_team_players(dv_instance.players_home, home_team_points)
    visiting_team_players = get_team_players(dv_instance.players_visiting, visiting_team_points)

    # Render HTML template with the summary data
    return render_template(template_file,
                           home_team_players=home_team_players,
                           visiting_team_players=visiting_team_players,
                           summary_data=summary_data)

# Run the Flask app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)