import os
import sys
import glob
import json
import pathlib
import warnings

warnings.filterwarnings("ignore")

try:
    import pandas as pd
    import geopandas as gpd
    from shapely.geometry import Point
    import simplekml
except Exception as e:
    print("Missing required packages. Please install with:")
    print("pip install pandas geopandas shapely simplekml openpyxl")
    sys.exit(1)


BASE_DATA_DIR = r""
ICON_DIR = r""
SCRIPT_DIR = r""
OUTPUT_DIR = r""

os.makedirs(OUTPUT_DIR, exist_ok=True)


def find_first_icon(icon_dir: str):
    exts = ("*.png", "*.jpg", "*.jpeg", "*.gif")
    for ext in exts:
        files = glob.glob(os.path.join(icon_dir, ext))
        if files:
            return files[0]
    return None

def slugify(s: str) -> str:
    return "".join(c if c.isalnum() else "_" for c in s.strip()).strip("_").lower()

def pick_from_list(label: str, options: list) -> str:
    if not options:
        print(f"No options available for {label}.")
        sys.exit(1)
    print(f"\nSelect {label}:")
    for i, opt in enumerate(options, 1):
        print(f"{i}. {opt}")
    while True:
        raw = input(f"Enter number (1-{len(options)}): ").strip()
        if raw.isdigit():
            idx = int(raw)
            if 1 <= idx <= len(options):
                return options[idx - 1]
        print("Invalid selection. Try again.")

def read_any_tabular(path: str) -> pd.DataFrame:
    p = pathlib.Path(path)
    if p.suffix.lower() in [".xlsx", ".xls"]:
        return pd.read_excel(path)
    elif p.suffix.lower() in [".csv"]:
        return pd.read_csv(path)
    else:
        raise ValueError(f"Unsupported file type: {p.suffix}")

def locate_data_file(data_dir: str) -> str:
    
    candidates = []
    for pattern in ["*PV*Sample*.xlsx", "*.xlsx", "*.xls", "*.csv"]:
        candidates = glob.glob(os.path.join(data_dir, pattern))
        if candidates:
            break
    if not candidates:
        raise FileNotFoundError("No input dataset found in Data folder.")
    return candidates[0]

def normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [c.strip() for c in df.columns]
    return df

def find_column(df: pd.DataFrame, candidates: list):
    cols = {c.lower(): c for c in df.columns}
    for cand in candidates:
        if cand.lower() in cols:
            return cols[cand.lower()]
    return None

def ensure_required_columns(df: pd.DataFrame):
    
    col_map = {
        "project_name": ["Project Name", "Name", "Project", "Plant Name"],
        "capacity_mw": ["Capacity (MW)", "Capacity MW", "Capacity_MW", "Capacity", "AC Capacity (MW)", "DC Capacity (MW)"],
        "technology_type": ["Technology Type", "Technology", "Tech", "Technology Tpe"],  
        "status": ["Status", "Project Status", "Stage"],
        "location_accuracy": ["Location Accuracy", "Location accuracy", "Accuracy"],
        "region": ["Region", "World Region", "Macro Region"],
        "country": ["Country", "Country/Area", "Nation"],
        "latitude": ["Latitude", "Lat", "LATITUDE"],
        "longitude": ["Longitude", "Lon", "Long", "LON", "LONGITUDE"],
    }
    resolved = {}
    for key, cands in col_map.items():
        col = find_column(df, cands)
        resolved[key] = col

    
    needed_for_geo = ["latitude", "longitude"]
    for k in needed_for_geo:
        if resolved[k] is None:
            raise ValueError(f"Missing required coordinate column: {k}")

    
    if resolved["country"] is None:
        raise ValueError("Missing required column: Country (or Country/Area).")

    
    return resolved

def build_geodata(df: pd.DataFrame, cols: dict) -> gpd.GeoDataFrame:
    
    def safe_col(name_key, default=""):
        src = cols.get(name_key)
        return src if src in df.columns else None

    gdf = df.copy()

    if safe_col("project_name") is None:
        gdf["Project Name"] = ""
        cols["project_name"] = "Project Name"
    if safe_col("capacity_mw") is None:
        gdf["Capacity (MW)"] = pd.NA
        cols["capacity_mw"] = "Capacity (MW)"
    if safe_col("technology_type") is None:
        gdf["Technology Type"] = ""
        cols["technology_type"] = "Technology Type"
    if safe_col("status") is None:
        gdf["Status"] = ""
        cols["status"] = "Status"
    if safe_col("location_accuracy") is None:
        gdf["Location Accuracy"] = ""
        cols["location_accuracy"] = "Location Accuracy"
    if safe_col("region") is None:
        gdf["Region"] = "Unknown"
        cols["region"] = "Region"

    
    lat_col, lon_col = cols["latitude"], cols["longitude"]
    gdf = gdf.dropna(subset=[lat_col, lon_col]).copy()
    gdf = gdf[(pd.to_numeric(gdf[lat_col], errors="coerce").notna()) &
              (pd.to_numeric(gdf[lon_col], errors="coerce").notna())].copy()

    gdf["__lat__"] = pd.to_numeric(gdf[lat_col], errors="coerce")
    gdf["__lon__"] = pd.to_numeric(gdf[lon_col], errors="coerce")
    gdf = gdf[gdf["__lat__"].between(-90, 90) & gdf["__lon__"].between(-180, 180)].copy()

    geometry = [Point(xy) for xy in zip(gdf["__lon__"], gdf["__lat__"])]
    gdf = gpd.GeoDataFrame(
        gdf,
        geometry=geometry,
        crs="EPSG:4326"
    )

    
    keep_cols = [
        cols["project_name"],
        cols["capacity_mw"],
        cols["technology_type"],
        cols["status"],
        cols["location_accuracy"],
        cols["region"],
        cols["country"],
    ]
    
    seen = set()
    keep_cols_clean = []
    for c in keep_cols:
        if c not in seen:
            keep_cols_clean.append(c)
            seen.add(c)

    out = gdf[keep_cols_clean + ["geometry"]].copy()
    rename_map = {
        cols["project_name"]: "Project Name",
        cols["capacity_mw"]: "Capacity (MW)",
        cols["technology_type"]: "Technology Type",
        cols["status"]: "Status",
        cols["location_accuracy"]: "Location Accuracy",
        cols["region"]: "Region",
        cols["country"]: "Country",
    }
    out = out.rename(columns=rename_map)
    return out

def export_geojson_gpkg(gdf: gpd.GeoDataFrame, out_base: str):
    geojson_path = f"{out_base}.geojson"
    gpkg_path = f"{out_base}.gpkg"
    gdf.to_file(geojson_path, driver="GeoJSON")
    gdf.to_file(gpkg_path, layer="projects", driver="GPKG")
    return geojson_path, gpkg_path

def export_kmz(gdf: gpd.GeoDataFrame, out_base: str, icon_path: str = None):
    kmz_path = f"{out_base}.kmz"
    kml = simplekml.Kml()
    shared_style = None
    if icon_path and os.path.isfile(icon_path):
        shared_style = simplekml.Style()
        shared_style.iconstyle.icon.href = icon_path
        shared_style.iconstyle.scale = 1.2

    for _, row in gdf.iterrows():
        geom = row.geometry
        if geom is None or geom.is_empty:
            continue
        pnt = kml.newpoint(
            name=str(row.get("Project Name", "")),
            coords=[(geom.x, geom.y)]
        )
        desc_items = {
            "Project Name": row.get("Project Name", ""),
            "Capacity (MW)": row.get("Capacity (MW)", ""),
            "Technology Type": row.get("Technology Type", ""),
            "Status": row.get("Status", ""),
            "Location Accuracy": row.get("Location Accuracy", ""),
            "Region": row.get("Region", ""),
            "Country": row.get("Country", ""),
        }
        html = "<![CDATA[<table border='1' cellpadding='4' cellspacing='0'>"
        for k, v in desc_items.items():
            html += f"<tr><th align='left'>{k}</th><td>{'' if pd.isna(v) else v}</td></tr>"
        html += "</table>]]>"
        pnt.description = html
        if shared_style:
            pnt.style = shared_style

    kml.savekmz(kmz_path)
    return kmz_path


def main():
    try:
        data_file = locate_data_file(BASE_DATA_DIR)
    except Exception as e:
        print(str(e))
        sys.exit(1)

    df = read_any_tabular(data_file)
    df = normalize_columns(df)
    cols = ensure_required_columns(df)
    gdf = build_geodata(df, cols)

    
    regions = sorted([str(x) if pd.notna(x) else "Unknown" for x in gdf["Region"].unique()])
    selected_region = pick_from_list("Region", regions)

    gdf_region = gdf[gdf["Region"].astype(str) == selected_region].copy()
    if gdf_region.empty:
        print("No records for selected Region.")
        sys.exit(0)

    countries = sorted([str(x) for x in gdf_region["Country"].dropna().unique()])
    selected_country = pick_from_list("Country", countries)

    gdf_final = gdf_region[gdf_region["Country"].astype(str) == selected_country].copy()
    if gdf_final.empty:
        print("No records for selected Country.")
        sys.exit(0)

    icon_path = find_first_icon(ICON_DIR)
    country_slug = slugify(selected_country)
    out_base = os.path.join(OUTPUT_DIR, f"solar_projects_{country_slug}")

    geojson_path, gpkg_path = export_geojson_gpkg(gdf_final, out_base)
    kmz_path = export_kmz(gdf_final, out_base, icon_path=icon_path)

    summary = {
        "input_file": data_file,
        "records_total": int(len(gdf)),
        "region_selected": selected_region,
        "country_selected": selected_country,
        "records_exported": int(len(gdf_final)),
        "outputs": {
            "geojson": geojson_path,
            "gpkg": gpkg_path,
            "kmz": kmz_path,
        },
        "icon_used": icon_path if icon_path else None,
    }
    print("\n" + json.dumps(summary, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
