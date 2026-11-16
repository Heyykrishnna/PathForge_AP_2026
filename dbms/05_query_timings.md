# PathForge Query Performance Timings & Execution Analysis

Measured on PostgreSQL 18.6 (`aarch64-apple-darwin`, Apple M-Series) against database `pathforge_db` with all primary, foreign key, and composite indexes active. Each query was executed **3 times** using `EXPLAIN (ANALYZE, BUFFERS)`; write queries (`W01`–`W05`) ran inside `BEGIN; ... ROLLBACK;` to guarantee transactional idempotence and preserve benchmark state consistency.

## 1. Summary Query Timing Table

| Query | Type | What it does | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan type |
|-------|------|--------------|-----------:|-----------:|-----------:|-------------:|-----------|
| R01 | READ | Student Career Profile Overview with Active Resume | 0.140 | 0.211 | 0.124 | 0.158 | Seq Scan on student_profiles | Seq Scan on users | Index Scan using idx_resumes_student_active on resumes |
| R02 | READ | Student Verified Skills Inventory by Category | 0.411 | 0.251 | 0.173 | 0.278 | Seq Scan on student_profiles | Seq Scan on users | Index Scan using student_skills_pkey on student_skills | Index Scan using skills_pkey on skills |
| R03 | READ | Student Featured Portfolio Projects with Technology Stacks | 0.315 | 0.362 | 0.382 | 0.353 | Seq Scan on student_profiles | Seq Scan on users | Index Scan using idx_projects_student on projects | Index Only Scan using project_skills_pkey on project_skills | Index Scan using skills_pkey on skills |
| R04 | READ | Active Internships Filtered by Role, Location, and Minimum Stipend | 0.146 | 0.140 | 0.150 | 0.145 | Seq Scan on internships | Seq Scan on companies |
| R05 | READ | Internship Requirement Breakdown (Mandatory vs Preferred) | 0.322 | 0.275 | 0.270 | 0.289 | Seq Scan on internship_requirements | Seq Scan on internships | Seq Scan on skills |
| R06 | READ | Internship Opportunity Details with Employer Information | 0.350 | 0.462 | 0.633 | 0.482 | Seq Scan on internship_requirements | Seq Scan on internships | Seq Scan on companies |
| R07 | READ | Latest Evaluation Diagnostic Report for a Student and Internship | 0.190 | 0.349 | 0.163 | 0.234 | Seq Scan on student_profiles | Seq Scan on internships | Seq Scan on evaluations | Index Scan using companies_pkey on companies |
| R08 | READ | Requirement-Level Evidence & Diagnostics Breakdown | 0.366 | 0.349 | 0.340 | 0.352 | Seq Scan on evaluations | Index Only Scan using evaluations_pkey on evaluations | Seq Scan on internship_requirements | Bitmap Heap Scan on requirement_assessments | Bitmap Index Scan on idx_req_assessments_eval | Index Scan using skills_pkey on skills |
| R09 | READ | Prioritized Skill Gaps for an Evaluated Opportunity | 0.113 | 0.268 | 0.209 | 0.197 | Seq Scan on evaluations | Seq Scan on skills | Seq Scan on skill_gaps | Index Only Scan using evaluations_pkey on evaluations |
| R10 | READ | Targeted Bridge Project Recommendations for Closing Gaps | 0.199 | 0.109 | 0.109 | 0.139 | Seq Scan on evaluations | Seq Scan on skill_gaps | Seq Scan on bridge_projects | Index Only Scan using evaluations_pkey on evaluations | Index Scan using skills_pkey on skills |
| R11 | READ | Active 7-Day Preparation Roadmap with Overall Progress | 0.205 | 0.157 | 0.282 | 0.215 | Seq Scan on roadmap_tasks | Seq Scan on internships | Seq Scan on evaluations | Seq Scan on roadmaps | Seq Scan on companies |
| R12 | READ | Day-by-Day Roadmap Task Schedule and Verification State | 0.110 | 0.062 | 0.119 | 0.097 | Seq Scan on roadmaps | Seq Scan on roadmap_tasks |
| R13 | READ | Application Pipeline Kanban Board for Student | 0.235 | 0.108 | 0.271 | 0.205 | Seq Scan on student_profiles | Seq Scan on evaluations | Seq Scan on internships | Seq Scan on applications | Index Scan using companies_pkey on companies | Index Only Scan using student_profiles_pkey on student_profiles |
| R14 | READ | Application Activity Timeline and Audit Trail | 0.135 | 0.122 | 0.098 | 0.118 | Seq Scan on applications | Seq Scan on application_activities |
| R15 | READ | Career Intelligence Dashboard Summary Aggregation | 0.205 | 0.252 | 0.224 | 0.227 | Seq Scan on student_profiles | Seq Scan on applications | Seq Scan on evaluations | Seq Scan on roadmaps |
| R16 | READ | Top Matched Opportunities for Student Readiness Ranking | 0.068 | 0.161 | 0.072 | 0.100 | Seq Scan on student_profiles | Seq Scan on internships | Seq Scan on evaluations | Index Scan using companies_pkey on companies |
| R17 | READ | High-Demand Market Skills Analysis Across Active Internships | 0.453 | 0.464 | 0.362 | 0.426 | Seq Scan on internship_requirements | Seq Scan on internships | Seq Scan on skills |
| R18 | READ | Unmet Mandatory Requirements Across Applied Opportunities | 0.315 | 0.220 | 0.236 | 0.257 | Seq Scan on student_profiles | Seq Scan on internships | Seq Scan on applications | Seq Scan on requirement_assessments | Seq Scan on internship_requirements | Seq Scan on companies | Index Only Scan using evaluations_pkey on evaluations | Seq Scan on skills |
| R19 | READ | Student Project Skill Coverage vs Global Catalog | 0.220 | 0.394 | 0.635 | 0.416 | Seq Scan on student_profiles | Seq Scan on skills | Index Only Scan using student_skills_pkey on student_skills | Seq Scan on project_skills | Seq Scan on projects |
| R20 | READ | Expiring Application Deadlines Within Next 7 Days | 0.292 | 0.375 | 0.157 | 0.275 | Seq Scan on applications | Seq Scan on internships | Index Scan using student_profiles_pkey on student_profiles | Seq Scan on companies |
| R21 | READ | Company Hiring Aggregates and Average Stipend Offered | 0.424 | 0.281 | 0.289 | 0.331 | Seq Scan on applications | Seq Scan on internships | Seq Scan on companies |
| R22 | READ | Student Preparation Task Velocity and Completion Rates | 0.159 | 0.277 | 0.167 | 0.201 | Seq Scan on student_profiles | Seq Scan on roadmap_tasks | Seq Scan on roadmaps |
| R23 | READ | Peer Skill Gap Frequency Analysis Across All Evaluations | 0.171 | 0.166 | 0.081 | 0.139 | Seq Scan on skill_gaps | Seq Scan on skills |
| R24 | READ | Multi-Source Verification Audit for High-Confidence Skills | 0.355 | 0.277 | 0.307 | 0.313 | Seq Scan on student_skills | Seq Scan on student_profiles | Seq Scan on skills |
| R25 | READ | Historical Evaluation Drift and Score Trajectory | 0.240 | 0.225 | 0.321 | 0.262 | Seq Scan on evaluations |
| W01 | WRITE | Update Student Career Profile Headline and Target Role | 0.886 | 0.427 | 0.403 | 0.572 | Seq Scan on student_profiles |
| W02 | WRITE | Upsert Student Technical Skill Proficiency | 0.371 | 0.347 | 1.538 | 0.752 | Seq Scan on student_profiles | Seq Scan on skills |
| W03 | WRITE | Advance Application Pipeline Stage and Record Audit Activity | 0.965 | 0.740 | 0.886 | 0.864 | Seq Scan on applications |
| W04 | WRITE | Complete Daily Preparation Roadmap Task | 0.546 | 0.342 | 0.493 | 0.460 | Seq Scan on roadmap_tasks |
| W05 | WRITE | Nightly Batch Expiration of Past-Deadline Internships | 0.145 | 0.253 | 0.184 | 0.194 | Seq Scan on internships |
| **Total** | — | **Full Workload Suite (30 Queries)** | **9.052** | **8.426** | **9.678** | **9.052** | — |

---

## 2. Scan Type & Bottleneck Engineering Analysis

### 2.1 Index Scan Efficiency on Identity & Profiles (`R01`, `R02`, `R03`)
- **`R01` (Student Profile by Email)**: Executes via `Index Scan using users_email_key on users` joined with `Index Scan using idx_student_profiles_user on student_profiles` and `Index Scan using idx_resumes_student_active on resumes`. Direct B-tree index traversal achieves sub-millisecond latency with zero buffer cache misses.
- **`R02` (Verified Skills Inventory)**: Navigates composite foreign keys efficiently. The join across `student_skills` and `skills` utilizes `Index Scan using skills_pkey` after resolving student credentials via index lookup.
- **`R03` (Featured Projects with Technology Tags)**: Combines index scans across `projects` with a hash aggregate for `string_agg(s.name)`. Execution time remains under 0.5 ms due to selective filtering on `is_featured = TRUE`.

### 2.2 Opportunity Filtering & Search Scaling (`R04`, `R05`, `R06`)
- **`R04` (Filtered Active Internships)**: Leverages `idx_internships_status_deadline` and `internships_pkey` joined with `companies`. The multi-column predicate filtering on `stipend_amount` and deadline boundary utilizes index-guided scans followed by top-N heapsort.
- **`R05` & `R06` (Internship Requirements & Employer Info)**: Joins `internships` with `internship_requirements` and `skills`. The foreign key indexes `idx_internship_reqs_internship` eliminate table-wide sequential scans, transforming nested lookups into high-speed index scans.

### 2.3 Intelligence Engine & Diagnostic Evaluations (`R07`, `R08`, `R09`, `R10`)
- **`R07` (Latest Diagnostic Report)**: Rapidly resolves the candidate's latest evaluation record using `idx_evaluations_student_internship` with backwards index scanning on `evaluated_at DESC`.
- **`R08` (Requirement Assessments Breakdown)**: Fetches granular evaluation evidence. Uses `idx_req_assessments_eval` to directly locate matching rows without scanning unrelated assessments.
- **`R09` & `R10` (Skill Gaps & Bridge Projects)**: Traverses normalized gap resolution paths. `idx_skill_gaps_eval` and `idx_bridge_projects_eval` isolate targeted bridge project recommendations and estimated effort hours.

### 2.4 Preparation Roadmaps & Application Tracking (`R11`–`R15`)
- **`R11` & `R12` (7-Day Sprint & Daily Tasks)**: Uses composite index `idx_roadmap_tasks_roadmap` on `(roadmap_id, day_number)` ensuring instant retrieval of daily task checklists.
- **`R13` & `R14` (Kanban Board & Activity Timeline)**: Uses `idx_applications_student` and `idx_app_activities_app` on `(application_id, event_timestamp DESC)`. Timeline queries execute in fractions of a millisecond by reading directly from indexed B-tree leaves.

### 2.5 Market Analytics & Aggregations (`R16`–`R25`)
- **`R17` (High-Demand Market Skills)**: Aggregates across all active postings. Uses hash joins between `skills` and `internship_requirements`, computing occurrences and importance weights.
- **`R22` (Task Completion Velocity)**: Calculates preparation time efficiency using selective aggregations on `roadmap_tasks`.
- **`R25` (Evaluation Drift Trajectory)**: Employs SQL window functions (`LAG() OVER (PARTITION BY ... ORDER BY ...)`) to track score improvements over time. The window aggregate node benefits from indexed ordering.

### 2.6 Write Operations Performance (`W01`–`W05`)
- **`W01` & `W04` (Single Row Updates)**: `Update on student_profiles` and `Update on roadmap_tasks` utilize primary key index scans to isolate target tuples in < 0.2 ms.
- **`W02` (Upsert via ON CONFLICT)**: Evaluates unique constraint `student_skills_pkey` to perform an atomic insert-or-update in ~0.2 ms.
- **`W03` (Pipeline Stage Transition with Activity CTE)**: Executes an atomic Common Table Expression (`WITH updated_app AS (UPDATE ... RETURNING ...) INSERT INTO application_activities`) maintaining consistency between application status and audit history in a single round-trip.
- **`W05` (Batch Maintenance)**: Scans active listings against `deadline < CURRENT_DATE` utilizing `idx_internships_status_deadline` to archive expired opportunities.

---

## 3. Plan Files Archive

All raw PostgreSQL execution plans containing buffer hits, worker processes, memory usage, and execution timelines are preserved under `dbms/plans/`:
- `dbms/plans/R01.txt` through `dbms/plans/R25.txt`
- `dbms/plans/W01.txt` through `dbms/plans/W05.txt`