# Standardized Herb Data Gathering Template

This document outlines the standard column format for collecting and recording herb data using Microsoft Excel or Google Sheets. Following this format ensures files can be imported directly into the Zim Herbs platform without manual reformatting.

A ready-to-use spreadsheet template file is located at:
- **[zim_herbs_standard_template.csv](file:///d:/software_projects/flutterApps/zim_herbs_repo/docs/templates/zim_herbs_standard_template.csv)**

You can also download this file directly inside the app under **Admin Console → Herbs Catalog → "Import Excel/CSV" → "Download Template"**.

---

## 1. Column Specifications

| # | Column Header (Row 1) | Data Type | Required? | Description & Allowed Values | Example Value |
|---|---|---|:---:|---|---|
| 1 | `common_name_en` | Text | **Yes** | Primary English or common name of the plant | `Fever Tea (Zumbani)` |
| 2 | `scientific_name` | Text | Recommended | Genus and species binomial nomenclature | `Lippia javanica` |
| 3 | `name_shona` | Text | Optional | Vernacular name in ChiShona | `Zumbani` |
| 4 | `name_ndebele` | Text | Optional | Vernacular name in IsiNdebele | `Insuzwane` |
| 5 | `family` | Text | Optional | Botanical family name | `Verbenaceae` |
| 6 | `growth_habit` | Text | Optional | Plant habit: `Tree`, `Shrub`, `Herb`, `Climber`, `Creeper`, `Grass`, `Fern`, `Succulent` | `Shrub` |
| 7 | `parts_used` | Text | Optional | Comma-separated list: `Leaves`, `Roots`, `Bark`, `Seeds`, `Flowers`, `Fruit`, `Bulbs`, `Twigs`, `Sap`, `Whole Plant` | `Leaves, Twigs` |
| 8 | `places_found` | Text | Optional | Natural habitat, eco-zones, or distribution across Zimbabwe | `Open grasslands, rocky slopes, and roadsides across Zimbabwe` |
| 9 | `exotic_status` | Text | Optional | `Indigenous`, `Introduced / Naturalized`, or `Exotic / Cultivated` | `Indigenous` |
| 10 | `description` | Text | Optional | General physical and ecological description of the plant | `Aromatic woody shrub with dense clusters of small white flowers.` |
| 11 | `food_nutrition` | Text | Optional | Edible fruits, teas, wild vegetables, oils, seeds, food preservation | `Herbal tea beverage consumed hot or cold.` |
| 12 | `construction_fencing` | Text | Optional | Poles, thatch, living fences, granary pest protection | `Fresh branches used for pest repellent in granaries.` |
| 13 | `firewood` | Text | Optional | Domestic fuel, charcoal, kindling characteristics | `Dry stems burn easily; used for kindling.` |
| 14 | `cultural_spiritual` | Text | Optional | Traditional folklore, sacred trees, symbolic associations | `Used as a body wash and steam cleanser for spiritual purification.` |
| 15 | `ritual` | Text | Optional | Ceremonial cleansing, incense burning, ancestral offerings | `Burned as incense during cultural cleansing rituals.` |
| 16 | `crafts_tools` | Text | Optional | Fibers, ropes, basketry, dyes, tool handles, water purification | `Natural mosquito and insect repellent.` |
| 17 | `other_uses` | Text | Optional | Veterinary care, commercial cosmetics, perfumes, other practical uses | `Essential oil extraction for perfumes and soaps.` |

---

## 2. Formatting Guidelines for Field Researchers

1. **Header Row (Row 1)**:
   - Must use exact header names as listed above (e.g. `places_found`, `scientific_name`, `food_nutrition`). Header matching is case-insensitive.
2. **Multiple Parts Used**:
   - Separate multiple parts with commas (e.g. `"Leaves, Roots, Bark"`). Wrap in quotation marks if editing raw CSV.
3. **Blank Cells**:
   - If a plant does not have a particular use (e.g. no ritual or firewood use), simply leave the cell blank.
4. **Saving from Excel**:
   - Save as **Excel Workbook (`.xlsx`)** or **CSV UTF-8 (Comma delimited) (`.csv`)**.
