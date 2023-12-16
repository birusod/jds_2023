# HOLIDAY MO:
# week-14
# = +++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Pkgs ====================================================
## Standard
using Downloads, Dates, Statistics

## Loaded
using CSV, DataFrames
using Tidier, Chain
#using AlgebraOfGraphics, CairoMakie


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

#parse.(Int64, dd.time[1:2])
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

ff = DataFrame(a = ["1-1", "2-2", "3-3-3"]);
@separate(ff, a, [b, c, d], "-")
@select(ff, a)



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

using AlgebraOfGraphics, CairoMakie
set_aog_theme!()
update_theme!(fontsize=30, markersize=40, Axis=(title="MyDefaultTitle",))
#axis = (width = 225, height = 225)


draw(
    data(dd) * frequency() * mapping(:type);
    axis=(title="Distribution By Movie Type",)
)

## by type
bytype
plt_barplot = data(bytype) *
    mapping(
        :type,
        :total;
        color=:type) *
visual(BarPlot)
draw(plt_barplot)


draw(
    data(bytype) *
    mapping(
        :type, :total;
        color=:type) *
    visual(BarPlot);
    axis=(title="Distribution By Movie Type",)
    )



# by  genres
gdf5 = first(gdf10, 5)
labels = ["Comedy", "Drama", "Romance", "Family", "Other"]
draw(
    data(gdf5) *
    mapping(
        :genres, :n;
        color = :genres => sorter(labels)) *
    visual(BarPlot);
    axis=(;
        title = "Top 5 Most Frequent Genres",
        titlealign = :left, # using Makie.jl's symbols
        titlecolor = :blue, # using Makie.jl's symbols
        titlefont = "DejaVu Sans Mono",
        titlegap = 30,      # the gap between title and the plot
        titlesize = 32,
        ),
)

gdf10[!, :odr] = collect(1:10)
gdf10

draw(
    data(gdf10) *
    mapping(:odr => "", :n => "", color = :genres  => "Genre") *
    visual(BarPlot; width = .5),
    axis = (
        title  =  "Top 10 Most Frequent Genre",
        xticklabelrotation=45.0,
        xticklabelcolor = :white,
        xtickcolor = :white
    ),
    legend = (; position = :top, titleposition = :left)
)


## By year
byyear

draw(
    data(byyear) *
    mapping(
        :year, :n) *
    visual(BarPlot, color = (:firebrick),);
    axis=(
        title = "Distribution Of Movies By  Year",
        titlealign = :center, # using Makie.jl's symbols
        titlecolor = :firebrick, # using Makie.jl's symbols
        titlefont = "Roboto",
        titlegap = 100,      # the gap between title and the plot
        titlesize = 20,)
)

## time
avg_df
duration = filter(row -> row.time < 150, dropmissing(avg_df))
duration
draw(
    data(duration) * 
    mapping(:time => "Duration in minutes") * 
    histogram(bins=30);
    axis = (title = "Histogram of Duration",)
)



using AlgebraOfGraphics: density
mycolors = ["#FC7808", "#8C00EC", "#107A78"]
draw(
    data(duration) * 
    mapping(:time => "Duration in minutes") * 
    density();
    axis = (
        title = "Density of Duration",)
)


# votes vs rating
vr = filter(r -> r.votes < 8000 && r.votes > 2000, dd)
draw(
    data(vr) * 
    mapping(:votes, :rating, color = :type) * 
    visual(Scatter),
    axis = (title = "Scatterplot: Votes vs Rating By  Type",),
    palettes = (color =  mycolors,)
)


# type: boxplot
data(dd) * 
    mapping(:type => "", :rating, color = :type => (t -> "Type " * t ) => "TYPES") * 
    visual(BoxPlot) |> draw

# type: violin side = :v_cat, color = :v_cat
with_theme(
    theme_minimal(); 
    Axis = (; 
    bottomspinecolor = :red, 
    leftspinecolor = :blue,
    title = "Rating Distribution By Type",
    titlecolor = :firebrick, # using Makie.jl's symbols
    titlefont = "Roboto",
    titlesize = 30)
    ) do
    data(dd) * 
    mapping(
        :type => "", 
        :rating => "Average Rating", 
        color = :type => "TYPE") * 
    visual(Violin) |> draw
end


# rating by genre (top10)
with_theme(
    theme_minimal(); 
    Axis = (; 
    title = "Rating By Movie Genre",
    bottomspinecolor = :grey,
    xticklabelrotation=45.0,
    xticklabelfont = :bold,
    titlecolor = :dodgerblue, 
    titlesize = 30)
    ) do
    data(avg_rtg) * 
    mapping(:genres => "", :avg  => "Average") * 
    visual(BarPlot) |> draw
end


# votes by genre (top10)
avg_votes
with_theme(
    theme_minimal(); 
    Axis = (; 
    title = "Votes By Movie Genre",
    bottomspinecolor = :grey,
    xticklabelrotation=45.0,
    xticklabelfont = :bold,
    titlecolor = :crimson, 
    titlesize = 30)
    ) do
    data(avg_votes) * 
    mapping(:genres => "", :avg  => "Average") * 
    visual(BarPlot) |> draw
end



# Time by genre (top10)
with_theme(
    theme_minimal(); 
    Axis = (; 
    title = "Duration By Movie Genre",
    bottomspinecolor = :grey,
    xticklabelrotation=45.0,
    xticklabelfont = :bold,
    titlecolor = :darkgreen, 
    titlesize = 30)
    ) do
    data(avg_time) * 
    mapping(:genres => "", :avg  => "Average") * 
    visual(BarPlot) |> draw
end



# save("figure.png", fig, px_per_unit = 3) # save high-resolution png