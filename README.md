# PathForge

## Intelligent Internship Decision & Career Intelligence Platform

> **From guessing eligibility to achieving verifiable application readiness.**

PathForge is an intelligent internship decision and career intelligence platform that helps students understand how well they align with real internship requirements and, more importantly, what they need to do to become stronger applicants.

Unlike conventional job portals that primarily list opportunities and rely on basic keyword matching, PathForge evaluates a student's resume, GitHub repositories, and technical competencies against internship criteria. It combines deterministic scoring with semantic analysis to produce explainable compatibility diagnostics, identify skill gaps, recommend practical bridge projects, and create focused preparation plans.

The platform turns an opaque match score into a clear, actionable path toward application readiness.

---

## 1. Problem Statement

Students often struggle to determine whether they are genuinely prepared for an internship. Existing job platforms typically focus on discovering and listing opportunities, while leaving students to interpret job descriptions, assess their own qualifications, and decide how to close gaps.

This creates several problems:
- **Unclear eligibility:** Students cannot easily tell how closely their skills and experience match an internship's actual requirements.
- **Keyword-based matching:** A simple keyword overlap can miss equivalent skills, relevant project experience, and contextual evidence.
- **No actionable gap analysis:** Platforms rarely explain which requirements are missing or how important each gap is.
- **Lack of direction:** Students may know they need to improve but not know which skills or projects would make the biggest difference.
- **Unstructured preparation:** Preparation is often disconnected from a specific role and lacks a practical timeline.
- **Fragmented applications:** Students track applications, deadlines, and follow-ups across multiple tools or spreadsheets.

PathForge addresses these problems by connecting opportunity analysis with personalized preparation and application tracking.

---

## 2. Vision

To make internship preparation measurable, explainable, and accessible by giving every student a clear understanding of where they stand, what they are missing, and what they should do next.

---

## 3. Product Objectives

1. Evaluate student profiles against internship requirements using structured and semantic analysis.
2. Explain compatibility results through requirement-level evidence instead of presenting an unexplained percentage.
3. Identify critical, important, and optional skill gaps.
4. Recommend targeted bridge projects that help students demonstrate missing competencies.
5. Generate practical, role-specific 7-day preparation roadmaps.
6. Provide a centralized workflow to track internship applications from discovery to final outcome.
7. Help students make informed decisions about which opportunities to prioritize.

---

## 4. Target Users

### Primary users
- University and college students seeking internships.
- First-time applicants who need help understanding role expectations.
- Students transitioning into a new technical domain.
- Self-taught developers who want to validate their skills against market requirements.

### Secondary users
- Career development cells and placement teams.
- Student communities and technical clubs.
- Mentors helping students prepare for internship applications.

---

## 5. Core Value Proposition

PathForge does not simply tell a student that an internship is a 72% match. It explains:
- Which requirements the student already satisfies.
- What evidence supports each matched requirement.
- Which requirements are partially satisfied or missing.
- Which gaps are most important to address.
- What projects or learning activities can help close those gaps.
- What the student should complete over the next seven days.
- How to track the opportunity and its application progress.

**Core promise:** Every compatibility result should lead to a practical next step.

---

## 6. Core Features

### 6.1 Student Career Profile
A centralized profile that represents a student's qualifications and technical experience.
- Resume upload and parsed experience.
- Technical skills and proficiency levels.
- Education and academic information.
- Projects, achievements, and certifications.
- GitHub profile and repository information.
- Relevant links such as portfolio and LinkedIn.
- Student-provided interests and preferred roles.

### 6.2 Internship Requirement Analysis
PathForge evaluates internship descriptions and converts them into structured requirements.
- Required technical skills.
- Preferred or bonus skills.
- Tools, frameworks, and technologies.
- Experience expectations.
- Project and portfolio expectations.
- Role responsibilities.
- Eligibility constraints, when explicitly provided.

### 6.3 Hybrid Compatibility Engine
Combines deterministic scoring and semantic analysis to produce compatibility assessments with supporting evidence, confidence indicators, and requirement-level explanations.

### 6.4 Explainable Compatibility Diagnostics
Requirement-level match evaluation categorizing competencies as `Matched`, `Partially matched`, `Missing`, or `Needs verification`.

### 6.5 Skill Gap Identification
Prioritizes missing competencies into `Critical gaps`, `Important gaps`, and `Optional gaps`.

### 6.6 Targeted Bridge Project Recommendations
Recommends focused engineering projects designed to build and showcase missing competencies.

### 6.7 7-Day Preparation Roadmap
Generates structured day-by-day sprint roadmaps to bridge critical gaps before applying.

### 6.8 Application Tracking
Centralized pipeline tracking opportunities across standard stages (`SAVED` to `OFFER`/`REJECTED`).

### 6.9 Career Intelligence Dashboard
Unified overview of readiness, target skill gaps, and application velocity.

---

## 7. Database & Systems Engineering Deliverables (`dbms/`)

The database tier of PathForge is designed, normalized, and benchmarked against PostgreSQL 18:

| Document / Artifact | Location | Description |
| :--- | :--- | :--- |
| **Normalization Report** | [01_normalization.md](file:///Users/Yatharth/Documents/Project-Code/PathForge_AP_2026/dbms/01_normalization.md) | Formal normalization from UNF → 1NF → 2NF → 3NF → BCNF with functional dependencies and proofs. |
| **ER Diagram (Markdown)** | [02_er_diagram.md](file:///Users/Yatharth/Documents/Project-Code/PathForge_AP_2026/dbms/02_er_diagram.md) | Full data dictionary, entity definitions, constraints, and Mermaid diagram. |
| **ER Diagram (Image)** | [02_er_diagram.png](file:///Users/Yatharth/Documents/Project-Code/PathForge_AP_2026/dbms/02_er_diagram.png) | High-resolution visual schema diagram. |
| **ER Diagram (Vector)** | [02_er_diagram.svg](file:///Users/Yatharth/Documents/Project-Code/PathForge_AP_2026/dbms/02_er_diagram.svg) | Scalable vector graphic diagram of all 18 tables and relationships. |
| **Relational DDL Schema** | [03_schema.sql](file:///Users/Yatharth/Documents/Project-Code/PathForge_AP_2026/dbms/03_schema.sql) | Production PostgreSQL 18 schema with primary/foreign keys, checks, and performance indexes. |
| **Workload SQL Queries** | [04_queries.sql](file:///Users/Yatharth/Documents/Project-Code/PathForge_AP_2026/dbms/04_queries.sql) | 30 production queries (25 READ, 5 WRITE) tagged with `-- @R01`..`-- @W05`. |
| **Query Timings & Analysis**| [05_query_timings.md](file:///Users/Yatharth/Documents/Project-Code/PathForge_AP_2026/dbms/05_query_timings.md) | 3-run timing benchmark table, average latencies, and scan type bottleneck analysis. |
| **Raw Execution Plans** | [plans/](file:///Users/Yatharth/Documents/Project-Code/PathForge_AP_2026/dbms/plans) | Raw `EXPLAIN (ANALYZE, BUFFERS)` execution plans for each query (R01.txt to W05.txt). |

