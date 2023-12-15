# Seattle Bike Counters
- **Data published date: 2019-04-02**
- **Tidytuesday Week: 14**
***
<br>

### Packages
Pkg Status:
 - <a href="https://csv.juliadata.org/stable/">CSV</a> v0.10.11
 - <a href="https://github.com/jkrumbiegel/Chain.jl">Chain</a> v0.5.0
 - <a href="https://dataframes.juliadata.org/stable/">DataFrames</a> v1.6.1
 - <a href="https://github.com/TidierOrg">Tidier</a> v1.2.0
 - <a href="https://categoricalarrays.juliadata.org/stable/">CategoricalArrays</a> v0.10.8

### Data
Data source: <a href="https://www.seattle.gov/transportation/document-library/citywide-plans/modal-plans/bicycle-master-plan">Seattle Dept of Transportation</a>

Data attributes:
|variable|class|description|
|-|-|-|
|date|date (mdy hms am/pm)|Date of data upload|
|crossing|character|The Street crossing/intersection|
|direction|character|North/South/East/West - varies by crossing|
|bike_count|double|Number of bikes counted for each hour window|
|ped_count|double|Number of pedestrians counted for each hour window|

### Wrangling and Viz

For this testing, I only used TidierPlots for vizualisation.
The options are limited for now

### Insights
