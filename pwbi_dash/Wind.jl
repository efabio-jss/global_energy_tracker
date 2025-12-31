Wind Total MW = SUM(Wind[Capacity (MW)])


Wind Top Technology = 
VAR S =
    SUMMARIZE(Wind, Wind[Installation Type], "mw", [Wind Total MW])
RETURN
MAXX(TOPN(1, S, [mw], DESC), Wind[Installation Type])


Wind Title = 
"Wind — " &
IF(HASONEVALUE(Wind[Region]), VALUES(Wind[Region]), "All Regions") &
" | " & FORMAT([Wind Total MW], "#,0") & " MW"


Wind Rows w/Coords = 
COUNTROWS(
    FILTER(Wind, NOT ISBLANK(Wind[Latitude]) && NOT ISBLANK(Wind[Longitude]))
)


Wind P95 MW = 
PERCENTILEX.INC(ALLSELECTED(Wind), Wind[Capacity (MW)], 0.95)


Wind Other Install MW = 
[Wind Total MW] - [Wind Onshore MW] - [Wind Offshore MW]


Wind Onshore MW = 
CALCULATE(
    [Wind Total MW],
    KEEPFILTERS(
        FILTER(Wind, CONTAINSSTRING(LOWER(Wind[Installation Type]), "onshore"))
    )
)


Wind Offshore MW = 
CALCULATE(
    [Wind Total MW],
    KEEPFILTERS(
        FILTER(Wind, CONTAINSSTRING(LOWER(Wind[Installation Type]), "offshore"))
    )
)


Wind Median MW = 
PERCENTILEX.INC(ALLSELECTED(Wind), Wind[Capacity (MW)], 0.5)


Wind Max Plant MW = MAX(Wind[Capacity (MW)])


Wind HHI by InstallType = 
VAR ByType =
    SUMMARIZE(
        Wind,
        Wind[Installation Type],
        "mw", [Wind Total MW]
    )
VAR Total = [Wind Total MW]
RETURN
SUMX(ByType, VAR share = DIVIDE([mw], Total) RETURN share * share)


Wind Countries = DISTINCTCOUNT(Wind[Country/Area])


Wind Avg Plant MW = DIVIDE([Wind Total MW], [Wind # Plants])


Wind Active MW = 
CALCULATE(
    [Wind Total MW],
    Wind[Status] IN {"Operational","Operating","Active","Online","Commissioned"}
)


Wind Active % = DIVIDE([Wind Active MW], [Wind Total MW])


Wind % Rows w/Coords = DIVIDE([Wind Rows w/Coords], [Wind # Plants])


Wind % of Total = 
VAR total = [Wind Total MW]
RETURN DIVIDE([Wind Total MW], total)


Wind # Plants = COUNTROWS(Wind)


# Aux Coluns

Wind Capacity Bin = 
SWITCH(
    TRUE(),
    Wind[Capacity (MW)] < 1, "< 1 MW",
    Wind[Capacity (MW)] < 5, "1–5 MW",
    Wind[Capacity (MW)] < 10, "5–10 MW",
    Wind[Capacity (MW)] < 20, "10–20 MW",
    Wind[Capacity (MW)] < 50, "20–50 MW",
    Wind[Capacity (MW)] < 100, "50–100 MW",
    Wind[Capacity (MW)] < 500, "100–500 MW",
    "≥ 500 MW"
)


Wind Capacity Bin Order = 
SWITCH(
    TRUE(),
    Wind[Wind Capacity Bin] = "< 1 MW", 1,
    Wind[Wind Capacity Bin] = "1–5 MW", 2,
    Wind[Wind Capacity Bin] = "5–10 MW", 3,
    Wind[Wind Capacity Bin] = "10–20 MW", 4,
    Wind[Wind Capacity Bin] = "20–50 MW", 5,
    Wind[Wind Capacity Bin] = "50–100 MW", 6,
    Wind[Wind Capacity Bin] = "100–500 MW", 7,
    8
)