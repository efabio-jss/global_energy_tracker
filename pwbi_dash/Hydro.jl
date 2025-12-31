Hydro Total MW = SUM(Hydro[Capacity (MW)])


Hydro Top Installation Type = 
VAR S =
    SUMMARIZE(Hydro, Hydro[Technology Type], "mw", [Hydro Total MW])
RETURN
MAXX(TOPN(1, S, [mw], DESC), Hydro[Technology Type])


Hydro Title = 
"Hydro — " &
IF(HASONEVALUE(Hydro[Region]), VALUES(Hydro[Region]), "All Regions") &
" | " & FORMAT([Hydro Total MW], "#,0") & " MW"


Hydro Run-of-River MW = 
CALCULATE(
    [Hydro Total MW],
    KEEPFILTERS(
        FILTER(Hydro,
            CONTAINSSTRING(LOWER(Hydro[Technology Type]), "run")
            || CONTAINSSTRING(LOWER(Hydro[Technology Type]), "ror")
        )
    )
)


Hydro Run-of-River MW = 
CALCULATE(
    [Hydro Total MW],
    KEEPFILTERS(
        FILTER(Hydro,
            CONTAINSSTRING(LOWER(Hydro[Technology Type]), "run")
            || CONTAINSSTRING(LOWER(Hydro[Technology Type]), "ror")
        )
    )
)


Hydro Reservoir MW = 
CALCULATE(
    [Hydro Total MW],
    KEEPFILTERS(
        FILTER(Hydro, CONTAINSSTRING(LOWER(Hydro[Technology Type]), "reservoir"))
    )
)


Hydro Pumped Storage MW = 
CALCULATE(
    [Hydro Total MW],
    KEEPFILTERS(
        FILTER(Hydro, CONTAINSSTRING(LOWER(Hydro[Technology Type]), "Pumped"))
    )
)


Hydro P95 MW = 
PERCENTILEX.INC(ALLSELECTED(Hydro), Hydro[Capacity (MW)], 0.95)


Hydro Other Install MW = 
[Hydro Total MW] - [Hydro Pumped Storage MW] - [Hydro Run-of-River MW] - [Hydro Reservoir MW]


Hydro P95 MW = 
PERCENTILEX.INC(ALLSELECTED(Hydro), Hydro[Capacity (MW)], 0.95)


Hydro Other Install MW = 
[Hydro Total MW] - [Hydro Pumped Storage MW] - [Hydro Run-of-River MW] - [Hydro Reservoir MW]


Hydro Median MW = 
PERCENTILEX.INC(ALLSELECTED(Hydro), Hydro[Capacity (MW)], 0.5)


Hydro Max Plant MW = MAX(Hydro[Capacity (MW)])


Hydro HHI by InstallType = 
VAR ByType =
    SUMMARIZE(
        Hydro,
        Hydro[Technology Type],
        "mw", [Hydro Total MW]
    )
VAR Total = [Hydro Total MW]
RETURN
SUMX(ByType, VAR share = DIVIDE([mw], Total) RETURN share * share)


Hydro Countries = DISTINCTCOUNT(Hydro[Country])


Hydro Avg Plant MW = DIVIDE([Hydro Total MW], [Hydro # Plants])


Hydro Active MW = 
CALCULATE(
    [Hydro Total MW],
    Hydro[Status] IN {"Operational","Operating","Active","Online","Commissioned"}
)


Hydro Active % = DIVIDE([Hydro Active MW], [Hydro Total MW])


Hydro % Rows w/Coords = DIVIDE([Hydro Rows w/Coords], [Hydro # Plants])


Hydro % of Total = 
VAR total = [Hydro Total MW]
RETURN DIVIDE([Hydro Total MW], total)


Hydro # Plants = COUNTROWS(Hydro)


#Aux Coluns

Hydro Capacity Bin = 
SWITCH(
    TRUE(),
    Hydro[Capacity (MW)] < 1, "< 1 MW",
    Hydro[Capacity (MW)] < 5, "1–5 MW",
    Hydro[Capacity (MW)] < 10, "5–10 MW",
    Hydro[Capacity (MW)] < 20, "10–20 MW",
    Hydro[Capacity (MW)] < 50, "20–50 MW",
    Hydro[Capacity (MW)] < 100, "50–100 MW",
    Hydro[Capacity (MW)] < 500, "100–500 MW",
    "≥ 500 MW"
)


Hydro Capacity Bin Order = 
SWITCH(
    TRUE(),
    Hydro[Hydro Capacity Bin] = "< 1 MW", 1,
    Hydro[Hydro Capacity Bin] = "1–5 MW", 2,
    Hydro[Hydro Capacity Bin] = "5–10 MW", 3,
    Hydro[Hydro Capacity Bin] = "10–20 MW", 4,
    Hydro[Hydro Capacity Bin] = "20–50 MW", 5,
    Hydro[Hydro Capacity Bin] = "50–100 MW", 6,
    Hydro[Hydro Capacity Bin] = "100–500 MW", 7,
    8
)