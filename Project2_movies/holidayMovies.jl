# HOLIDAY MO:
# week-14
# = +++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Pkgs ====================================================
## Standard
using Downloads, Dates, Statistics

## Loaded
using CSV, DataFrames, CategoricalArrays
using AlgebraOfGraphics, CairoMakie
using Tidier, Chain

# Load Data ===============================================

url_rds = "https://raw.githubusercontent.com/rfordatascience/"
url_data= "tidytuesday/master/data/2023/2023-12-12/holiday_movies.csv"

ddd = CSV.File(Downloads.download(url_rds * url_data)) |> DataFrame;


# Data wrangling  ==========================================
ddd |> size
ddd |> describe

dd = @chain ddd begin 
    @select(
        tconst, year, genres,
        type = title_type,
        time = runtime_minutes,
        rating = average_rating,
        votes = num_votes)  
    @mutate(time = as_integer(time))
end

parse.(Int64, dd.time[1:2])
# EDA ======================================================


## by type
bytype = @chain dd begin
    groupby(:type)
    combine(nrow => :total)
    sort(:total, rev  = true)
end

## by  genres
split.(dd.genres, " ,")
idr = nrow(dd)
collect(1:nrow(dd))
gdf = @chain dd begin
    @select(tconst, genres)
    @separate(genres, [g1, g2, g3], ",")
    # @mutate(rowid = row_number()) *not needed if a idcol is present
    @pivot_longer(g1:g3, names_to = "group", values_to = "genres")  # -rowid
end

@chain gdf begin
    @count(genres, sort = true)
end

gdf10  = @chain gdf begin
    @drop_missing(genres)  # or dropmissing  [required for cat_lump]
    @mutate(genres = cat_lump(genres,9))
    @group_by(genres)
    @tally(sort = true)
end


## By year

byyear = @chain dd begin
    @count(year)
end

# rating by genre (top10)

@chain dd begin
    @select(tconst, rating, time, votes)
    @left_join(gdf, tconst)
    @drop_missing(genres)
    @mutate(genres = cat_lump(genres, 9))
    @group_by(genres)
    @summarise(avg = round(mean(rating), digits = 2))
end

avg_df = @chain dd begin
    @select(tconst, rating, time, votes)
    @left_join(gdf, tconst)
    @drop_missing(genres)
    @mutate(genres = cat_lump(genres, 9))
end

function avgfunc(df::DataFrame, group_col::Symbol, summary_col::Symbol)
    sort(
        combine(
            groupby(df, group_col), 
            summary_col => (x -> round(mean(skipmissing(x)), digits=2)) => :avg),
        :avg, rev = true)
end

avg_df
avg_rtg = avgfunc(avg_df, :genres, :rating)
avg_votes = avgfunc(avg_df, :genres, :votes)
avg_time = avgfunc(avg_df, :genres, :time)



# Viz =======================================================

# AlgebraOfGraphics + CairoMakie
set_aog_theme!()
update_theme!(fontsize=30, markersize=40, Axis=(title="MyDefaultTitle",))
#axis = (width = 225, height = 225)


draw(
    data(dd) * frequency() * mapping(:type);
    axis=(title="Distribution By Movie Type",)
)

## by type
bytype

plot(
    bytype,  # Use the @df macro to refer to the DataFrame
    mapping=:type => :total,  # Specify the mapping of variables
    Geom.bar,  # Use the bar geometry
    Scale.x_discrete,  # Use discrete scale for x-axis
    
)

plot(
    result,
    mapping=:Group => :rounded_mean_summary,  # Specify the mapping of variables
    Geom.bar,  # Use the bar geometry
    Scale.x_discrete,  # Use discrete scale for x-axis
    Guide.xlabel("Group"),  # Label for x-axis
    Guide.ylabel("Rounded Mean Value")  # Label for y-axis
)



# by  genres
gdf10


## By year
byyear


## time
avg_df



# rating by genre (top10)

avg_rtg

avg_votes

avg_time



# save("figure.png", fig, px_per_unit = 3) # save high-resolution png