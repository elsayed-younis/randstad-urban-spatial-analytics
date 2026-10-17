# 🌍 Randstad Urban Spatial Analytics

**Enterprise Cloud-Native Spatial Lakehouse & 15-Minute City Benchmark**
*Snowflake · dbt (Fusion Engine) · Uber H3 · Overture Maps*

[![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Cloud-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![dbt](https://img.shields.io/badge/dbt-Fusion%20Engine%202.0-FF694B?style=for-the-badge&logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![Uber H3](https://img.shields.io/badge/Uber%20H3-Spatial%20Indexing%20Res%208-000000?style=for-the-badge&logo=uber&logoColor=white)](https://h3geo.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Data Scale](https://img.shields.io/badge/Entities-4.72M%2B-brightgreen?style=for-the-badge)](https://github.com/elsayed-younis/randstad-urban-spatial-analytics)
[![Runtime](https://img.shields.io/badge/Gold%20Mart%20Runtime-8.23s-blue?style=for-the-badge)](https://github.com/elsayed-younis/randstad-urban-spatial-analytics)

> ⚡ **4.72M+ spatial entities** ingested from Overture Maps · projected onto an **H3 Res-8 hexagonal grid** · Gold mart materialized in **8.23 seconds** on an X-Small warehouse.

---

## 📑 Table of Contents

- [📌 Executive Summary](#-executive-summary)
- [🏗️ Architecture & Pipeline Flow](#-architecture--pipeline-flow)
- [🛠️ Tech Stack & Engineering Decisions](#-tech-stack--engineering-decisions)
- [📊 Ingestion & Data Scale](#-ingestion--data-scale)
- [📐 Geospatial Methodology & Urban Analytics](#-geospatial-methodology--urban-analytics)
- [🔍 Data Quality & Automated Testing](#-data-quality--automated-testing)
- [⚡ Performance Benchmarks & Cost Governance](#-performance-benchmarks--cost-governance)
- [📂 Repository Structure](#-repository-structure)
- [🚀 How to Reproduce](#-how-to-reproduce)
- [👤 Author](#-author)
- [📜 License](#-license)

---

## 📌 Executive Summary

Modern urban planning and real-estate spatial intelligence require combining disparate, high-volume vector datasets — building footprints, street networks, and public amenities — to evaluate urban density and accessibility. However, running traditional planar geometric intersections (`ST_INTERSECTS`, `ST_DWITHIN`) across millions of multi-polygons and line strings is computationally prohibitive, slow, and expensive on cloud infrastructure.

This project designs and implements an end-to-end, production-grade **Geospatial Data Lakehouse** covering the entire **Dutch Randstad metropolitan region** (Amsterdam, Rotterdam, The Hague, and Utrecht). Built on **Snowflake** and orchestrated via **dbt Cloud**, the pipeline ingests and cleans **4.72M+ entities** from the **Overture Maps Foundation** release and projects them onto an **Uber H3 Discrete Global Grid (Resolution 8)**.

The resulting analytical mart (`fct_randstad_urban_grid`) calculates building density, road infrastructure capacity, and a composite **15-Minute City Accessibility Score** across thousands of uniform hexagonal cells in just **8.23 seconds**.

---

## 🏗️ Architecture & Pipeline Flow

The project adheres to the **Medallion Architecture (Bronze → Silver → Gold)**, enforcing strict separation between raw ingestion, modular transformation views, and aggregated analytical tables:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                      Overture Maps (AWS S3)                            │
│           Buildings (~3.63M) │ Roads (~820k) │ Places (~268k)          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ AWS S3 External Stage / Ingestion
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   BRONZE LAYER (EURO_URBAN_DW.BRONZE_RAW)              │
│       raw_buildings_randstad │ raw_roads_randstad │ raw_places_randstad│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ dbt Cloud (Staging Views)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   SILVER LAYER (dbt Staging Models)                    │
│   - stg_buildings: Geometric cleaning, ST_AREA, ST_CENTROID            │
│   - stg_roads:     Road hierarchy, segment lengths via ST_LENGTH       │
│   - stg_places:    Re-classification into 4 core 15-min city pillars   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ H3 Spatial Indexing (Res 8) & Aggs
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   GOLD LAYER (dbt Marts - Final Table)                 │
│                     fct_randstad_urban_grid                            │
│   - Unified H3 hexagonal indexing (average cell area ~0.737 km²)       │
│   - Built-environment surface density & footprint aggregates           │
│   - Composite 15-Minute City Accessibility Index (0 - 100)             │
│   - Spatial typology tagging (Transit-Oriented, Suburban, Corridor)    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack & Engineering Decisions

| Technology | Purpose | Strategic Engineering Justification |
| --- | --- | --- |
| **Snowflake** | Cloud Data Warehouse | Native geospatial engine support (`GEOGRAPHY`, `GEOMETRY`, and built-in H3 functions) with micro-partitioning and credit auto-suspend safeguards. |
| **dbt Cloud (Fusion Engine 2.0)** | Data Transformation & DAG | Version-controlled SQL modeling, automated documentation, lineage tracking, and declarative schema data tests. |
| **Uber H3 System** | Spatial Discretization | Equal-area hexagonal tessellation eliminating edge distortion; replaces `O(N × M)` geometric cross-joins with `O(1)` alphanumeric hash joins. |
| **Overture Maps** | Authoritative Open Data | Open-standard, cloud-native spatial vector release with high geometric precision across the Netherlands. |
| **Git / GitHub** | CI/CD & Version Control | Trunk-based development workflow with feature branching and pull-request code reviews. |

---

## 📊 Ingestion & Data Scale

The bounding-box extent for the Dutch Randstad was extracted as:
`POLYGON((4.10 51.80, 5.30 51.80, 5.30 52.50, 4.10 52.50, 4.10 51.80))`

| Layer | Model / Target | Spatial Geometry | Entity Count | Metrics Derived |
| --- | --- | --- | --- | --- |
| **Bronze** | `raw_buildings_randstad` | Polygon | **3,630,000+** | Footprint boundaries, height, min/max bbox |
| **Bronze** | `raw_roads_randstad` | LineString | **820,000+** | Road segment lines, highway / street classes |
| **Bronze** | `raw_places_randstad` | Point | **268,000+** | POI coordinates, primary & secondary categories |
| **Silver** | `stg_buildings` | View | 3.63M | Footprint area (m²), building centroid point |
| **Silver** | `stg_roads` | View | 820k | Road length (m), 4-tier functional classification |
| **Silver** | `stg_places` | View | 268k | Filtered to 4 urban-living accessibility pillars |
| **Gold** | `fct_randstad_urban_grid` | Table | Hexagonal Grid | H3 Res-8 metrics, accessibility score, typology |

---

## 📐 Geospatial Methodology & Urban Analytics

### 1️⃣ Why Uber H3 Resolution 8?

- At **Resolution 8**, each hexagon covers an average area of **0.737 km²** with an edge length of approximately **461 meters**.
- The distance from the hexagon center to any vertex corresponds to a **5–8 minute walk**, making Res-8 the optimal spatial unit for micro-urban analysis and pedestrian accessibility audits without over-aggregating.

### 2️⃣ The 15-Minute City Accessibility Score

Points of interest are mapped to four essential urban pillars:

- 🚆 **Public Transit:** railway stations, metro, light rail, and bus stops.
- 🏥 **Healthcare:** hospitals, clinics, pharmacies, and general practitioners.
- 🎓 **Education:** primary/secondary schools, kindergartens, and higher education.
- 🛒 **Daily Retail:** supermarkets, bakeries, grocery stores, and local markets.

The **Accessibility Index** is calculated dynamically per hexagon:

**Accessibility Score = Σ (Pillar Present × 25)  →  [0, 100]**

### 3️⃣ Urban Fabric Typology

Each hexagon is classified into an operational planning typology via threshold logic:

- `Dense Transit-Oriented Urban`: ≥ 50 buildings and ≥ 2 transit access points.
- `Suburban Residential Fabric`: ≥ 20 buildings with moderate road density.
- `Transport Corridor / Rural Fringe`: high road-network throughput with low building footprints.
- `Sparse / Open Space`: buffer zones, agricultural fields, and natural reserves.

---

## 🔍 Data Quality & Automated Testing

The analytical mart is verified by automated `dbt test` assertions conforming to **dbt Fusion 2.0** standards (`dbt test --select fct_randstad_urban_grid` → ✅ 6 passed · 0 errored · 0 warned):

```yaml
version: 2

models:
  - name: fct_randstad_urban_grid
    description: "Gold analytical mart aggregating urban density, infrastructure capacity, and accessibility."
    columns:
      - name: h3_hex_id
        description: "Unique Uber H3 index at resolution 8."
        data_tests:
          - unique
          - not_null
      - name: hex_boundary_geom
        description: "Geographical polygon boundary of the H3 cell."
        data_tests:
          - not_null
      - name: fifteen_min_city_score
        description: "Composite accessibility score ranging from 0 to 100."
        data_tests:
          - not_null
      - name: urban_typology
        description: "Categorical classification of the urban fabric."
        data_tests:
          - not_null
          - accepted_values:
              arguments:
                values:
                  - 'Dense Transit-Oriented Urban'
                  - 'Suburban Residential Fabric'
                  - 'Transport Corridor / Rural Fringe'
                  - 'Sparse / Open Space'
```

---

## ⚡ Performance Benchmarks & Cost Governance

- **Execution Runtime:** the Gold mart (`fct_randstad_urban_grid`) compiles, performs H3 hashing across 4.7M+ entities, executes unions and aggregations, and materializes the physical table in **8.23 seconds** on an `X-Small` Snowflake warehouse.
- **Zero-Cost Staging:** all Silver-layer transformations are materialized as **views**, incurring no storage or compute refresh cost.
- **Credit Guardrails:** the warehouse is configured with an aggressive **60-second auto-suspend** policy, keeping total pipeline consumption well under **1 credit per full run**.

---

## 📂 Repository Structure

```text
randstad-urban-spatial-analytics/
├── analyses/
├── macros/
├── models/
│   ├── staging/
│   │   ├── _sources.yml                 # Source declarations for Bronze tables
│   │   ├── stg_buildings.sql            # Building footprints & ST_AREA calculations
│   │   ├── stg_places.sql               # POI amenity pillars categorization
│   │   └── stg_roads.sql                # Road hierarchy & length calculations
│   └── marts/
│       ├── fct_randstad_urban_grid.sql  # H3 Res-8 spatial aggregation mart
│       └── schema.yml                   # dbt data tests & model documentation
├── seeds/
├── snapshots/
├── tests/
├── .gitignore
├── dbt_project.yml                      # Core dbt configurations & materialization rules
└── README.md                            # Comprehensive architectural documentation
```

---

## 🚀 How to Reproduce

1. **Clone the repository:**

```bash
git clone https://github.com/elsayed-younis/randstad-urban-spatial-analytics.git
cd randstad-urban-spatial-analytics
```

2. **Configure the connection:** ensure Snowflake credentials (profiles.yml or dbt Cloud environment) with permissions on the target database `EURO_URBAN_DW`.

3. **Validate the setup:**

```bash
dbt debug
```

4. **Build the full pipeline:**

```bash
dbt build
```

---

## 👤 Author

**Elsayed Younis**
*Spatial Data Engineer | Cloud Analytics & GIS Architecture*

- **GitHub:** [@elsayed-younis](https://github.com/elsayed-younis)
- **Project:** [randstad-urban-spatial-analytics](https://github.com/elsayed-younis/randstad-urban-spatial-analytics)

---

## 📜 License

This project is licensed under the **MIT License**.

---

<div align="center">
  Built with ❤️ on Snowflake × dbt × Overture Maps × Uber H3
</div>
