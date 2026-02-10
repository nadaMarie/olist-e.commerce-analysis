# 📊 Olist E-Commerce End-to-End Data Analysis

## 📌 Project Overview
This project presents an end-to-end data analysis of the Brazilian Olist e-commerce dataset.
The goal is to evaluate delivery performance, seller efficiency, customer behavior, payments, cancellations, and product demand, and extract business-driven insights using SQL.

## 🧹 Data Cleaning & Preparation
Before analysis, extensive data cleaning and validation were performed across 9 relational tables to ensure accuracy and analytical reliability:

• Fixed inconsistent city and state names

• Unified product categories referring to the same meaning

• Validated and corrected datetime data types

• Verified the complete order lifecycle sequence
(purchase → approval → carrier → delivery)

• Isolated logical date inconsistencies into separate tables instead of deleting them

• Investigated zero freight values and validated that they are not data errors

• Removed only meaningless duplicates, preserving informative records

• Cleaned corrupted and broken review comments in order_reviews table

• Performed a full numeric sanity check to ensure no negative or illogical values across all numerical columns

• Checked missing values

## 🗂️ Data Modeling
• Built a relational data model connecting orders, sellers, customers, products, payments, and reviews using dbdiagram.io and Tableau during the visualization stage

• Ensured referential integrity across all joins

• Designed the model to support lifecycle-based and performance-based analysis

## 🔍 Analysis Sections
### 1.Delivery & Logistics Performance
• On-time vs delayed deliveries

• Delay magnitude and distribution

• Logistics vs seller responsibility 

• State-level and remote region analysis

### 2.Seller Performance
• Sellers contributing disproportionately to delays

• Handling time vs logistics time comparison

• Benchmarking sellers within the same customer state

### 3.Customer Behavior & Satisfaction
• Impact of delays on review scores

• Repeat behavior after delayed experiences

• Delay experience segmentation

### 4.System Performance
• Order approval time analysis

• Detection of rare system bottlenecks

### 5.Payments & Revenue Impact
• Payment method distribution

• Installments vs order value

• Revenue contribution by payment behavior

### 6.Cancellations Analysis
• Cancellation timing within order lifecycle

• Relationship with price and estimated delivery time

• Seasonal cancellation patterns

### 7.Products & Categories
• Most and least ordered products per category

• Category price positioning

• Seasonal demand patterns

### 8.Demand & Promotional Opportunities
• Identification of low-demand months for targeted offers

## 📊 Dashboard
• Tableau Public Dashboard:
https://public.tableau.com/views/Olist_E-commerce_Project/Executive_Overview?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

## 🧠 Key Insights
• 82% of delivery delays are logistics-dominated, while 9% are seller-dominated

• Customer satisfaction remains relatively stable across states, even in remote regions

• A small subset of sellers significantly underperform compared to regional norms

• Order approval is fast for 86% of orders, but a small fraction experiences extreme delays exceeding one week

• Installment payments increase average order value and total revenue

• Most cancellations occur after approval and before carrier, indicating seller-side issues

## 🔸 Recommendations
• Expand seller coverage in high-demand states to reduce delivery pressure

• Invest in logistics optimization to minimize delivery delays

• Develop retention strategies targeting repeat customers

• Promote categories with low order volume through targeted offers (e.g., Security and Kitchenware, which are priced higher than Health & Beauty)

• Launch promotional campaigns during low-demand months such as September and October

## 🛠️ Tools Used
• SQL (MySQL)

• Excel (Power Query) (Data Cleaning)

• Window Functions & CTEs

• dbdiagram.io (Data Modeling)

• Tableau (Visualization)
