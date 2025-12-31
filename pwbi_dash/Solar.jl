Solar Total MW (All) = 
VAR AllRows =
    UNION(
        SELECTCOLUMNS('Solar 20 MW+', "Capacity", 'Solar 20 MW+'[Capacity (MW)]),
        SELECTCOLUMNS('Solar 1-20 MW', "Capacity", 'Solar 1-20 MW'[Capacity (MW)])
    )
RETURN
SUMX(AllRows, [Capacity])


Solar Top Technology = 
TOPN(1, VALUES('Solar 20 MW+'[Technology Type]), [Solar Total MW (All)], DESC)


Solar Title (All) = 
"Solar — Total " & FORMAT([Solar Total MW (All)], "#,0") & " MW"


Solar Rows w/Coords (All) = 
VAR With20 =
    COUNTROWS(
        FILTER('Solar 20 MW+',
            NOT ISBLANK('Solar 20 MW+'[Latitude]) &&
            NOT ISBLANK('Solar 20 MW+'[Longitude])
        )
    )
VAR With120 =
    COUNTROWS(
        FILTER('Solar 1-20 MW',
            NOT ISBLANK('Solar 1-20 MW'[Latitude]) &&
            NOT ISBLANK('Solar 1-20 MW'[Longitude])
        )
    )
RETURN COALESCE(With20,0) + COALESCE(With120,0)


Solar Rows w/Coords (All) = 
VAR With20 =
    COUNTROWS(
        FILTER('Solar 20 MW+',
            NOT ISBLANK('Solar 20 MW+'[Latitude]) &&
            NOT ISBLANK('Solar 20 MW+'[Longitude])
        )
    )
VAR With120 =
    COUNTROWS(
        FILTER('Solar 1-20 MW',
            NOT ISBLANK('Solar 1-20 MW'[Latitude]) &&
            NOT ISBLANK('Solar 1-20 MW'[Longitude])
        )
    )
RETURN COALESCE(With20,0) + COALESCE(With120,0)


Solar Median MW (All) = 
VAR AllCap =
    UNION(
        SELECTCOLUMNS('Solar 20 MW+', "cap", 'Solar 20 MW+'[Capacity (MW)]),
        SELECTCOLUMNS('Solar 1-20 MW', "cap", 'Solar 1-20 MW'[Capacity (MW)])
    )
RETURN
PERCENTILEX.INC(AllCap, [cap], 0.5)


Solar Max Plant MW (All) = 
VAR AllRows =
    UNION(
        SELECTCOLUMNS('Solar 20 MW+', "Capacity", 'Solar 20 MW+'[Capacity (MW)]),
        SELECTCOLUMNS('Solar 1-20 MW', "Capacity", 'Solar 1-20 MW'[Capacity (MW)])
    )
RETURN
MAXX(AllRows, [Capacity])


Solar HHI by Tech (All) = 
VAR Stack =
    UNION(
        SELECTCOLUMNS(
            'Solar 20 MW+',
            "Tech", 'Solar 20 MW+'[Technology Type],
            "mw",   'Solar 20 MW+'[Capacity (MW)]
        ),
        SELECTCOLUMNS(
            'Solar 1-20 MW',
            "Tech", 'Solar 1-20 MW'[Technology Type],
            "mw",   'Solar 1-20 MW'[Capacity (MW)]
        )
    )
VAR ByTech =
    SUMMARIZE(
        Stack,
        [Tech],
        "TotalMW", SUMX(FILTER(Stack, [Tech] = EARLIER([Tech])), [mw])
    )
VAR TotalMW = [Solar Total MW (All)]
RETURN
SUMX(ByTech, VAR share = DIVIDE([TotalMW], TotalMW) RETURN share * share)


Solar Countries (All) = 
VAR AllCountries =
    DISTINCT(
        UNION(
            SELECTCOLUMNS('Solar 20 MW+', "Country", 'Solar 20 MW+'[Country/Area]),
            SELECTCOLUMNS('Solar 1-20 MW', "Country", 'Solar 1-20 MW'[Country/Area])
        )
    )
RETURN COUNTROWS(AllCountries)


Solar Avg Plant MW (All) = 
DIVIDE([Solar Total MW (All)], [Solar # Plants (All)])


Solar Active MW (All) = 
VAR Active20 =
    CALCULATE(
        SUM('Solar 20 MW+'[Capacity (MW)]),
        'Solar 20 MW+'[Status] IN {"Operational","Operating","Active","Online","Commissioned"}
    )
VAR Active120 =
    CALCULATE(
        SUM('Solar 1-20 MW'[Capacity (MW)]),
        'Solar 1-20 MW'[Status] IN {"Operational","Operating","Active","Online","Commissioned"}
    )
RETURN COALESCE(Active20,0) + COALESCE(Active120,0)


Solar Active % (All) = 
DIVIDE([Solar Active MW (All)], [Solar Total MW (All)])


Solar % Rows w/Coords (All) = 
DIVIDE([Solar Rows w/Coords (All)], [Solar # Plants (All)])


Solar # Plants (All) = 
VAR AllProjects =
    UNION(
        SELECTCOLUMNS('Solar 20 MW+', "Project", 'Solar 20 MW+'[Project Name]),
        SELECTCOLUMNS('Solar 1-20 MW', "Project", 'Solar 1-20 MW'[Project Name])
    )
RETURN
COUNTROWS(AllProjects)


Dim Technology = DISTINCT( UNION( SELECTCOLUMNS('Solar 20 MW+', "Tech", 'Solar 20 MW+'[Technology Type]),
                                  SELECTCOLUMNS('Solar 1-20 MW', "Tech", 'Solar 1-20 MW'[Technology Type]) ) )


Dim Subregion = DISTINCT( UNION( SELECTCOLUMNS('Solar 20 MW+', "Subregion", 'Solar 20 MW+'[Subregion]),
                                 SELECTCOLUMNS('Solar 1-20 MW', "Subregion", 'Solar 1-20 MW'[Subregion]) ) )


Dim Status = DISTINCT( UNION( SELECTCOLUMNS('Solar 20 MW+', "Status", 'Solar 20 MW+'[Status]),
                              SELECTCOLUMNS('Solar 1-20 MW', "Status", 'Solar 1-20 MW'[Status]) ) )


Dim Region = DISTINCT( UNION( SELECTCOLUMNS('Solar 20 MW+', "Region", 'Solar 20 MW+'[Region]),
                                SELECTCOLUMNS('Solar 1-20 MW', "Region", 'Solar 1-20 MW'[Region]) ) )


Dim Country = DISTINCT(
    UNION(
        SELECTCOLUMNS('Solar 20 MW+', "Country", 'Solar 20 MW+'[Country/Area]),
        SELECTCOLUMNS('Solar 1-20 MW', "Country", 'Solar 1-20 MW'[Country/Area])))