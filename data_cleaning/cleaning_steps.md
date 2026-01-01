• Fixed inconsistent city and state names

• Unified product categories referring to the same meaning

• Validated and corrected datetime data types

• Verified the complete order lifecycle sequence (purchase → approval → carrier → delivery)

• Isolated logical date inconsistencies into separate tables instead of deleting them

• Investigated zero freight values and validated that they are not data errors

• Removed only meaningless duplicates, preserving informative records

• Cleaned corrupted and broken review comments in order_reviews table

• Performed a full numeric sanity check to ensure no negative or illogical values across all numerical columns

• Checked missing values
