from pathlib import Path

import pandas as pd
import streamlit as st


ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "data" / "cleaned_retail.csv"
RFM_PATH = ROOT / "outputs" / "rfm_segments.csv"
COHORT_PATH = ROOT / "outputs" / "cohort_retention.csv"


st.set_page_config(page_title="Online Retail Dashboard", layout="wide")


@st.cache_data
def load_data():
    df = pd.read_csv(DATA_PATH)
    df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"])
    df["CustomerID"] = df["CustomerID"].astype("Int64")
    df["Revenue"] = df["Quantity"] * df["UnitPrice"]
    return df


@st.cache_data
def load_rfm():
    return pd.read_csv(RFM_PATH)


@st.cache_data
def load_cohort():
    return pd.read_csv(COHORT_PATH)


df = load_data()
rfm = load_rfm()
cohort = load_cohort()

sales = df[(df["Quantity"] > 0) & (df["UnitPrice"] > 0)].copy()
sales["Month"] = sales["InvoiceDate"].dt.to_period("M").astype(str)

st.title("Online Retail Sales Dashboard")

min_date = sales["InvoiceDate"].min().date()
max_date = sales["InvoiceDate"].max().date()
date_range = st.sidebar.date_input("Invoice date range", value=(min_date, max_date), min_value=min_date, max_value=max_date)

countries = sorted(sales["Country"].dropna().unique())
selected_countries = st.sidebar.multiselect("Countries", countries, default=["United Kingdom"] if "United Kingdom" in countries else countries[:5])

if len(date_range) == 2:
    start_date, end_date = date_range
    sales = sales[(sales["InvoiceDate"].dt.date >= start_date) & (sales["InvoiceDate"].dt.date <= end_date)]

if selected_countries:
    sales = sales[sales["Country"].isin(selected_countries)]

total_revenue = sales["Revenue"].sum()
total_orders = sales["InvoiceNo"].nunique()
total_customers = sales["CustomerID"].nunique()
average_order_value = total_revenue / total_orders if total_orders else 0

kpi1, kpi2, kpi3, kpi4 = st.columns(4)
kpi1.metric("Total Revenue", f"${total_revenue:,.0f}")
kpi2.metric("Orders", f"{total_orders:,}")
kpi3.metric("Customers", f"{total_customers:,}")
kpi4.metric("Average Order Value", f"${average_order_value:,.2f}")

tab_sales, tab_customers, tab_cohort = st.tabs(["Sales", "RFM Segments", "Cohort Retention"])

with tab_sales:
    left, right = st.columns(2)
    monthly = sales.groupby("Month", as_index=False)["Revenue"].sum()
    top_products = sales.groupby("Description", as_index=False)["Revenue"].sum().sort_values("Revenue", ascending=False).head(10)
    top_countries = sales.groupby("Country", as_index=False)["Revenue"].sum().sort_values("Revenue", ascending=False).head(10)

    left.subheader("Monthly Revenue")
    left.line_chart(monthly, x="Month", y="Revenue")

    right.subheader("Top Products by Revenue")
    right.bar_chart(top_products, x="Description", y="Revenue")

    st.subheader("Top Countries by Revenue")
    st.bar_chart(top_countries, x="Country", y="Revenue")

with tab_customers:
    left, right = st.columns(2)
    segment_summary = (
        rfm.groupby("Segment")
        .agg(Customers=("CustomerID", "count"), Revenue=("Monetary", "sum"), AverageSpend=("Monetary", "mean"))
        .sort_values("Revenue", ascending=False)
        .reset_index()
    )

    left.subheader("Customer Count by Segment")
    left.bar_chart(segment_summary, x="Segment", y="Customers")

    right.subheader("Revenue by Segment")
    right.bar_chart(segment_summary, x="Segment", y="Revenue")

    st.subheader("RFM Segment Summary")
    st.dataframe(segment_summary, use_container_width=True)

    st.subheader("Top Customers")
    st.dataframe(rfm.sort_values("Monetary", ascending=False).head(20), use_container_width=True)

with tab_cohort:
    st.subheader("Customer Retention by Monthly Cohort")
    retention_matrix = cohort.pivot(index="CohortMonth", columns="CohortIndex", values="RetentionRate").fillna(0)
    st.dataframe(retention_matrix.style.format("{:.2f}%").background_gradient(cmap="Blues"), use_container_width=True)
