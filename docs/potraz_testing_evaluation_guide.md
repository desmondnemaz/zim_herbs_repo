# Zim Herbs: National Indigenous Herbal Knowledge Repository
## POTRAZ Evaluation & Technical Testing Guide (Web Platform)

**Prepared for:** Postal and Telecommunications Regulatory Authority of Zimbabwe (POTRAZ)  
**Evaluation Scope:** Phase 1 Digital Herbarium & Ethnobotanical Repository  
**Live Platform URL:** [https://desmondnemaz.github.io/zim_herbs_repo/](https://desmondnemaz.github.io/zim_herbs_repo/)  
**Access Method:** Web Application (Accessible on any modern PC, Mac, tablet, or smartphone browser)

---

## 1. Executive Summary & National Strategic Alignment

The **Zim Herbs Digital Repository** is an indigenous digital health and ethnobotanical platform built to systematically document, preserve, and scientifically classify Zimbabwe’s rich traditional botanical knowledge.

### Strategic Alignment with National Mandates:
* **NDS1 (National Development Strategy 1) & Vision 2030:** Accelerating digital economy transformation and preserving indigenous intellectual property.
* **POTRAZ Universal Service Fund (USF) Alignment:** Bridging the health information divide by providing rural and marginalized communities with verified traditional remedy knowledge, toxicity cautions, and emergency preparations.
* **Indigenous Knowledge Systems (IKS) Protection:** Digitizing oral ethnobotanical heritage into scientific, dual-language (Shona, Ndebele, English, and Latin) taxonomies.

---

## 2. Pre-Configured Evaluation Test Accounts

Evaluators do not need to register personal details. Three dedicated test personas with distinct governance levels are pre-configured:

| Evaluation Persona | Email Address | Password | Role & Scope of Authority |
| :--- | :--- | :--- | :--- |
| **Administrator** | `admin@zimherbs.co.zw` | `ZimHerbs2026!` | **Full Administrative Governance:** Platform dashboard, 14-column spreadsheet bulk import/export, user role management, system analytics. |
| **Moderator** | `moderator@zimherbs.co.zw` | `ZimHerbs2026!` | **Quality & Research Control:** Verifying unapproved community submissions, auditing botanical claims, and validating ethnopharmacological data. |
| **Citizen (Public)** | `user@zimherbs.co.zw` | `ZimHerbs2026!` | **Public Educational Experience:** Vernacular plant lookup, illness and ailment browsing, safety contraindications, and traditional preparation guidance. |

> **Browser Recommendation:** To ensure your browser loads the newest version rather than a cached service worker, open the test URL in an **Incognito / Private tab** or press **`Ctrl + F5`** (hard refresh).

---

## 3. Four Core Test Workflows for Evaluators

### Workflow 1: Vernacular Indigenous Search (Citizen Experience)
* **Objective:** Test natural language discovery across Zimbabwe's national languages.
* **Steps:**
  1. Log in as `user@zimherbs.co.zw` (or test unauthenticated).
  2. In the search bar, type local Shona names (e.g. **"Zumbani"**, **"Mugan'acha"**, **"Mupfura"**, **"Gavakava"**) or Ndebele names (e.g. **"Insuzwane"**, **"Inhlaba"**, **"Umganu"**).
  3. Verify that the system retrieves the botanical record, matching common English names (*Fever tea, Live-long, Marula, Aloe*) and Latin families (*Verbenaceae, Anacardiaceae*).

### Workflow 2: Ethnobotanical Safety & Dosage Cautions
* **Objective:** Verify patient and public safety protocols.
* **Steps:**
  1. Open plant detail records such as *Catharanthus roseus* (*Chirindamatongo*) or *Schkuhria pinnata* (*Ruhwahwa*).
  2. Inspect the **Caution & Warning Card**: Verify explicit contraindications (e.g., toxicity risks, pregnancy warnings, or dosage limitations).
  3. Inspect the harvested parts breakdown (Leaves, Roots, Bark, Seeds) and geographic distribution across provinces.

### Workflow 3: Fast Ethnobotanical Documentation (Image Pasting)
* **Objective:** Test modern researcher productivity and desktop ergonomics.
* **Steps:**
  1. Log in as `admin@zimherbs.co.zw` or `moderator@zimherbs.co.zw`.
  2. Navigate to **Herb Management** $\rightarrow$ **Add Herb** (or edit an existing plant).
  3. Capture a snip (`Win + Shift + S`) or right-click any botanical photo in a web browser and choose **Copy Image**.
  4. Return to the app and press **`Ctrl + V`** or click the green **"Paste Image"** card.
  5. Observe the image instantly attach to the plant's photo gallery. Test the red **`X`** delete button to remove unwanted images prior to saving.

### Workflow 4: Scientific 14-Column Bulk Ingestion
* **Objective:** Test institutional data ingestion for universities (UZ, NUST, MSU) and research bodies (SIRDC).
* **Steps:**
  1. In the Administrator portal, navigate to **Import Excel / CSV**.
  2. **Step 1 (Rules):** Review the streamlined 4-guideline import policy and 3-step workflow.
  3. **Step 2 (Template):** Click **Download Excel (.xlsx)** or **Download CSV** to inspect the 14 standardized columns and sample plants (*Live-long, Wild grape, Mango, Marula*).
  4. **Step 3 & 4 (Validation & Ingestion):** Select a spreadsheet file, review live automated validation checks, and execute batch database publishing.

---

## 5. Phased Strategic Development Roadmap

POTRAZ evaluators are invited to review the planned phased rollout:

```
┌────────────────────────────────────────────────────────┐
│ PHASE 1: CORE REPOSITORY & HERBARIUM (LIVE - READY)    │
│ • 111+ Verified Zimbabwean Botanical Records           │
│ • Shona, Ndebele, English, and Botanical Search        │
│ • Safety Warnings, Contraindications & Preparations     │
│ • High-Speed Clipboard Herbarium Pasting (Ctrl+V)       │
│ • Standardized 14-Column Scientific Bulk Ingestion     │
│ • Role-Based Governance (Admin, Moderator, Citizen)    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ PHASE 2: TELEMEDICINE & MARKETPLACE (UNDER DEV)       │
│ • Licensed Traditional Practitioner Tele-Consultations │
│ • Quality-Verified Herbal Remedy Marketplace           │
│ • Low-Bandwidth Offline Sync for Rural Clinics         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ PHASE 3: AI INNOVATION & COMPUTER VISION (FUTURE)      │
│ • Multilingual AI Herbal Health Assistant              │
│ • Mobile Leaf & Bark Botanical Camera Classifier       │
└────────────────────────────────────────────────────────┘
```

---

## 6. Summary Technical Architecture

* **Client Architecture:** Flutter Web (Responsive design for mobile, tablet, and desktop).
* **Backend Infrastructure:** Supabase PostgreSQL with Row Level Security (RLS) policies.
* **Storage Layer:** Encrypted Cloud Object Storage (`herb-images` bucket).
* **Audit & Attribution:** Immutable `created_by`, `updated_by`, `verified_by` database timestamps on all botanical records.
* **Hosting & CI/CD:** Automated GitHub Actions continuous deployment pipeline.

