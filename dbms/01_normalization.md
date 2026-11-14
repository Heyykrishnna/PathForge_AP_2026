# PathForge Database Normalization: 1NF → 2NF → 3NF → BCNF

## 1. Executive Summary & Domain Scope

PathForge is an intelligent internship decision and career intelligence platform designed to bridge the gap between student qualifications and industry expectations. The platform manages complex multidimensional data:

- User identities and role-based permissions (Students, Mentors, Administrators).
- Student career profiles, educational history, resume versions, and portfolio links.
- Normalized skill taxonomy and categorized technical competencies.
- Student skill proficiencies with verification states and supporting evidence.
- Student projects and their associated technology stacks.
- Enterprise partner profiles (Companies) and their published internship listings.
- Structured internship requirements categorized by necessity (mandatory, preferred, bonus).
- Compatibility evaluations, hybrid match scoring, and confidence metrics.
- Requirement-level diagnostic assessments with evidence attribution.
- Prioritized skill gap diagnostics (critical, important, optional).
- Targeted bridge project recommendations to close identified skill gaps.
- Action-oriented 7-day preparation roadmaps and granular daily tasks.
- Comprehensive application tracking pipelines and chronological audit trails.

To ensure transactional integrity, eliminate data redundancy, prevent modification anomalies, and support high-throughput analytical querying, this document details the formal normalization process from an Unnormalized Form (UNF) through First Normal Form (1NF), Second Normal Form (2NF), Third Normal Form (3NF), and Boyce-Codd Normal Form (BCNF).

---

## 2. Unnormalized Form (UNF)

In an unnormalized architecture, the platform's domain is conceptualized as a single monolithic record (`UNF_InternshipReadiness`) containing nested repeating groups, composite attributes, and comma-delimited strings for skills, projects, requirements, diagnostics, roadmaps, and application activity.

### Monolithic Relation Schema: `UNF_InternshipReadiness`

```text
UNF_InternshipReadiness(
    user_id, email, password_hash, user_role, student_name, student_phone,
    university, degree, grad_year, cgpa, github_username, portfolio_url,
    { resume_id, resume_file_url, resume_parsed_json, resume_uploaded_at },
    { skill_name, skill_category, student_proficiency, is_verified, years_exp },
    { project_id, project_title, project_desc, repo_url, demo_url, { project_skill } },
    company_id, company_name, company_website, company_industry, company_location,
    internship_id, internship_title, internship_desc, internship_type, stipend_amount,
    deadline, internship_status,
    { requirement_id, req_skill_name, req_type, req_weight, min_proficiency, req_text },
    evaluation_id, compatibility_score, coverage_pct, scoring_version, evaluated_at,
    { assessment_id, assessed_req_id, match_status, match_value, confidence, evidence_text },
    { gap_id, gap_skill_name, gap_priority, gap_reason, suggested_action },
    { bridge_proj_id, bridge_proj_title, bridge_proj_scope, bridge_proj_deliverables, difficulty },
    roadmap_id, roadmap_title, roadmap_status,
    { task_id, day_number, task_title, task_focus, task_outcome, is_completed },
    application_id, app_stage, applied_date, app_priority,
    { activity_id, activity_type, activity_notes, activity_timestamp }
)
```

### Critical Anomalies in UNF

1. **Repeating Groups & Non-Atomic Attributes**: Arrays of skills, resumes, requirements, and tasks violate relational atomicity. Relational engines cannot index, sort, or join individual elements without costly unnesting operations.
2. **Insertion Anomaly**: A new skill cannot be registered in the system unless a student claims it or an internship requires it. Similarly, a company cannot exist without an active internship posting.
3. **Deletion Anomaly**: If a student removes their application or evaluation, the entire record of the internship's requirements or the company profile might be inadvertently wiped from the database.
4. **Update Anomaly**: If a company's website or an internship's stipend changes, every historical evaluation record referencing that company or internship must be updated individually. Any missed update creates inconsistent duplicate states.

---

## 3. First Normal Form (1NF)

### 3.1 Definition of 1NF

A relation is in First Normal Form (1NF) if and only if:

1. Every attribute domain contains only atomic (indivisible) values.
2. There are no repeating groups or nested relations.
3. Each record is uniquely identifiable by a primary key.

### 3.2 1NF Transformation & Flattening

We eliminate all arrays and nested multivalued records by creating flattened tuple sets where every repeating group is decomposed into individual rows with composite primary keys linking back to parent identifiers.

The flattened 1NF schemas and their functional dependencies:

#### 1. `R1_USER_PROFILE`

```text
Attributes: (user_id, email, password_hash, user_role, created_at, full_name,
             phone, university, degree, grad_year, cgpa, github_username, portfolio_url)
Primary Key: user_id
Functional Dependencies:
  user_id → email, password_hash, user_role, created_at, full_name, phone,
            university, degree, grad_year, cgpa, github_username, portfolio_url
  email → user_id, password_hash, user_role, created_at, full_name, phone,
          university, degree, grad_year, cgpa, github_username, portfolio_url
```

#### 2. `R1_STUDENT_SKILLS`

```text
Attributes: (user_id, skill_name, skill_category, proficiency, is_verified, years_exp)
Primary Key: (user_id, skill_name)
Functional Dependencies:
  (user_id, skill_name) → proficiency, is_verified, years_exp
  skill_name → skill_category
```

#### 3. `R1_STUDENT_PROJECTS`

```text
Attributes: (project_id, user_id, project_title, project_desc, repo_url, demo_url, skill_name)
Primary Key: (project_id, skill_name)
Functional Dependencies:
  project_id → user_id, project_title, project_desc, repo_url, demo_url
  (project_id, skill_name) → [All attributes]
```

#### 4. `R1_INTERNSHIP_CATALOG`

```text
Attributes: (internship_id, company_id, company_name, company_website, company_industry,
             internship_title, internship_desc, internship_type, stipend_amount,
             deadline, internship_status)
Primary Key: internship_id
Functional Dependencies:
  internship_id → company_id, internship_title, internship_desc, internship_type,
                  stipend_amount, deadline, internship_status
  company_id → company_name, company_website, company_industry
```

#### 5. `R1_INTERNSHIP_REQUIREMENTS`

```text
Attributes: (requirement_id, internship_id, skill_name, skill_category, req_type,
             req_weight, min_proficiency, req_text)
Primary Key: requirement_id
Candidate Key: (internship_id, skill_name)
Functional Dependencies:
  requirement_id → internship_id, skill_name, req_type, req_weight, min_proficiency, req_text
  (internship_id, skill_name) → requirement_id, req_type, req_weight, min_proficiency, req_text
  skill_name → skill_category
```

#### 6. `R1_EVALUATIONS`

```text
Attributes: (evaluation_id, user_id, internship_id, compatibility_score, coverage_pct,
             scoring_version, evaluated_at)
Primary Key: evaluation_id
Candidate Key: (user_id, internship_id, evaluated_at)
Functional Dependencies:
  evaluation_id → user_id, internship_id, compatibility_score, coverage_pct,
                  scoring_version, evaluated_at
```

#### 7. `R1_REQUIREMENT_ASSESSMENTS`

```text
Attributes: (assessment_id, evaluation_id, requirement_id, match_status, match_value,
             confidence, evidence_source, evidence_text, explanation)
Primary Key: assessment_id
Candidate Key: (evaluation_id, requirement_id)
Functional Dependencies:
  assessment_id → evaluation_id, requirement_id, match_status, match_value,
                  confidence, evidence_source, evidence_text, explanation
  (evaluation_id, requirement_id) → assessment_id, match_status, match_value,
                                    confidence, evidence_source, evidence_text, explanation
```

#### 8. `R1_ROADMAP_TASKS`

```text
Attributes: (roadmap_id, evaluation_id, user_id, roadmap_title, day_number,
             task_id, task_title, task_focus, task_outcome, estimated_minutes, is_completed)
Primary Key: (roadmap_id, task_id)
Functional Dependencies:
  roadmap_id → evaluation_id, user_id, roadmap_title
  (roadmap_id, task_id) → day_number, task_title, task_focus, task_outcome,
                          estimated_minutes, is_completed
  task_id → day_number, task_title, task_focus, task_outcome, estimated_minutes, is_completed
```

### 3.3 Anomalies Remaining in 1NF

- In `R1_STUDENT_SKILLS`, the functional dependency `skill_name → skill_category` causes redundancy: whenever multiple students list the skill "PostgreSQL", its category "DATABASE" is duplicated.
- In `R1_STUDENT_PROJECTS`, `project_id → user_id, project_title, ...` is a **partial dependency** because `project_id` alone determines the project details, but the candidate key is composite `(project_id, skill_name)`.
- In `R1_ROADMAP_TASKS`, `roadmap_id → user_id, roadmap_title` is a partial functional dependency on the composite key `(roadmap_id, task_id)`.

---

## 4. Second Normal Form (2NF)

### 4.1 Definition of 2NF

A relation is in Second Normal Form (2NF) if and only if:

1. It is in First Normal Form (1NF).
2. No non-prime attribute is partially dependent on any candidate key of the relation. That is, every non-prime attribute must be fully functionally dependent on the entire primary key.

### 4.2 Decomposing Partial Dependencies

We identify all relations with composite primary keys and isolate attributes that depend on only a subset of that key.

#### Decomposition of `R1_STUDENT_PROJECTS`:

- Candidate Key: `(project_id, skill_name)`
- Partial Dependency: `project_id → user_id, project_title, project_desc, repo_url, demo_url`
- Decomposition:
  - `R2_PROJECTS(project_id, user_id, project_title, project_desc, repo_url, demo_url)`
    - PK: `project_id`
    - FD: `project_id → user_id, project_title, project_desc, repo_url, demo_url`
  - `R2_PROJECT_SKILLS(project_id, skill_id)`
    - PK: `(project_id, skill_id)`
    - Full dependency: both parts of key are required.

#### Decomposition of `R1_ROADMAP_TASKS`:

- Candidate Key: `(roadmap_id, task_id)`
- Partial Dependency: `roadmap_id → evaluation_id, user_id, roadmap_title`
- Decomposition:
  - `R2_ROADMAPS(roadmap_id, evaluation_id, user_id, roadmap_title, status, created_at)`
    - PK: `roadmap_id`
    - FD: `roadmap_id → evaluation_id, user_id, roadmap_title, status, created_at`
  - `R2_ROADMAP_TASKS(task_id, roadmap_id, day_number, task_title, task_focus, task_outcome, estimated_minutes, is_completed)`
    - PK: `task_id`
    - Foreign Key: `roadmap_id`
    - Full dependency: `task_id → roadmap_id, day_number, task_title, ...`

### 4.3 Anomalies Remaining in 2NF

Although partial dependencies are eliminated, **transitive dependencies** remain:

- In `R1_INTERNSHIP_CATALOG`: `internship_id → company_id` and `company_id → company_name, company_website, company_industry`. Non-prime company attributes depend transitively on `internship_id`.
- In `R1_USER_PROFILE`: `user_id` determines authentication credentials and profile information, but users may have distinct profiles or role-specific attributes.
- In `R1_STUDENT_SKILLS` and `R1_INTERNSHIP_REQUIREMENTS`: `skill_name → skill_category` represents a transitive dependency where non-key attributes determine other non-key attributes.

---

## 5. Third Normal Form (3NF)

### 5.1 Definition of 3NF

A relation is in Third Normal Form (3NF) if and only if:

1. It is in Second Normal Form (2NF).
2. For every non-trivial functional dependency $X \rightarrow Y$:
   - $X$ is a superkey, **OR**
   - $Y$ is a prime attribute (member of a candidate key).

In other words, 3NF eliminates all transitive dependencies of non-prime attributes on candidate keys ("every non-key attribute must depend on the key, the whole key, and nothing but the key").

### 5.2 Decomposing Transitive Dependencies

#### 1. Company Information De-coupling

In `R1_INTERNSHIP_CATALOG`, $FD_1: \text{internship\_id} \rightarrow \text{company\_id}$, and $FD_2: \text{company\_id} \rightarrow \text{company\_name, company\_website, company\_industry}$.
Because `company_id` is not a superkey of `R1_INTERNSHIP_CATALOG`, this is a transitive dependency.

- **Decomposition**:
  - `COMPANIES(company_id, company_name, company_website, company_industry, company_location, created_at)`
    - PK: `company_id`
    - FDs: `company_id → company_name, company_website, company_industry, company_location, created_at`
  - `INTERNSHIPS(internship_id, company_id, title, description, internship_type, stipend_amount, deadline, status, created_at)`
    - PK: `internship_id`
    - FK: `company_id → COMPANIES(company_id)`
    - FDs: `internship_id → company_id, title, description, internship_type, stipend_amount, deadline, status, created_at`

#### 2. Skill Catalog Normalization

In student skills and internship requirements, `skill_name → skill_category`.

- **Decomposition**:
  - `SKILLS(skill_id, name, slug, category, description)`
    - PK: `skill_id`
    - Unique Key: `slug`, `name`
    - FDs: `skill_id → name, slug, category, description`; `slug → skill_id, name, category, description`
  - `STUDENT_SKILLS(student_id, skill_id, proficiency, is_verified, years_experience)`
    - PK: `(student_id, skill_id)`
    - FK: `student_id → STUDENT_PROFILES(student_id)`, `skill_id → SKILLS(skill_id)`
  - `INTERNSHIP_REQUIREMENTS(requirement_id, internship_id, skill_id, requirement_type, weight, min_proficiency, requirement_text)`
    - PK: `requirement_id`
    - FK: `internship_id → INTERNSHIPS(internship_id)`, `skill_id → SKILLS(skill_id)`

#### 3. User Authentication vs. Student Profile Separation

In `R1_USER_PROFILE`, separating account authentication security from educational profile data eliminates nullability for administrative/mentor users and separates authentication concerns:

- `USERS(user_id, email, password_hash, user_role, is_active, created_at, updated_at)`
  - PK: `user_id`
  - Unique Key: `email`
  - FDs: `user_id → email, password_hash, user_role, is_active, created_at, updated_at`
- `STUDENT_PROFILES(student_id, user_id, full_name, phone, university, degree, grad_year, cgpa, github_username, portfolio_url, linkedin_url, created_at, updated_at)`
  - PK: `student_id`
  - Unique Key / FK: `user_id → USERS(user_id)`
  - FDs: `student_id → user_id, full_name, phone, ...`; `user_id → student_id, full_name, phone, ...`

---

## 6. Boyce-Codd Normal Form (BCNF)

### 6.1 Definition of BCNF

A relation is in Boyce-Codd Normal Form (BCNF) if and only if:

- For every non-trivial functional dependency $X \rightarrow Y$, $X$ is a **superkey**.

BCNF is a stricter form of 3NF that handles cases where a relation has multiple overlapping candidate keys.

### 6.2 BCNF Verification of PathForge Relations

Let us test every decomposed relation in PathForge against the BCNF condition:

| Relation                  | Candidate Keys                                         | Functional Dependencies $X \rightarrow Y$                  |      Is $X$ a Superkey?       | Normal Form |
| :------------------------ | :----------------------------------------------------- | :--------------------------------------------------------- | :---------------------------: | :---------: |
| `users`                   | `{user_id}`, `{email}`                                 | `user_id → *`, `email → *`                                 | Yes (both are candidate keys) |  **BCNF**   |
| `student_profiles`        | `{student_id}`, `{user_id}`                            | `student_id → *`, `user_id → *`                            | Yes (both are candidate keys) |  **BCNF**   |
| `resumes`                 | `{resume_id}`                                          | `resume_id → *`                                            |              Yes              |  **BCNF**   |
| `skills`                  | `{skill_id}`, `{slug}`, `{name}`                       | `skill_id → *`, `slug → *`, `name → *`                     | Yes (all are candidate keys)  |  **BCNF**   |
| `student_skills`          | `{(student_id, skill_id)}`                             | `(student_id, skill_id) → *`                               |              Yes              |  **BCNF**   |
| `projects`                | `{project_id}`                                         | `project_id → *`                                           |              Yes              |  **BCNF**   |
| `project_skills`          | `{(project_id, skill_id)}`                             | `(project_id, skill_id) → *`                               |              Yes              |  **BCNF**   |
| `companies`               | `{company_id}`                                         | `company_id → *`                                           |              Yes              |  **BCNF**   |
| `internships`             | `{internship_id}`                                      | `internship_id → *`                                        |              Yes              |  **BCNF**   |
| `internship_requirements` | `{requirement_id}`                                     | `requirement_id → *`                                       |              Yes              |  **BCNF**   |
| `evaluations`             | `{evaluation_id}`                                      | `evaluation_id → *`                                        |              Yes              |  **BCNF**   |
| `requirement_assessments` | `{assessment_id}`, `{(evaluation_id, requirement_id)}` | `assessment_id → *`, `(evaluation_id, requirement_id) → *` | Yes (both are candidate keys) |  **BCNF**   |
| `skill_gaps`              | `{gap_id}`                                             | `gap_id → *`                                               |              Yes              |  **BCNF**   |
| `bridge_projects`         | `{bridge_project_id}`                                  | `bridge_project_id → *`                                    |              Yes              |  **BCNF**   |
| `roadmaps`                | `{roadmap_id}`                                         | `roadmap_id → *`                                           |              Yes              |  **BCNF**   |
| `roadmap_tasks`           | `{task_id}`, `{(roadmap_id, day_number, task_order)}`  | `task_id → *`, `(roadmap_id, day_number, task_order) → *`  |              Yes              |  **BCNF**   |
| `applications`            | `{application_id}`, `{(student_id, internship_id)}`    | `application_id → *`, `(student_id, internship_id) → *`    |              Yes              |  **BCNF**   |
| `application_activities`  | `{activity_id}`                                        | `activity_id → *`                                          |              Yes              |  **BCNF**   |

### 6.3 Lossless Join and Dependency Preservation Proof

1. **Lossless Join**:
   For any binary decomposition of relation $R$ into $R_1$ and $R_2$, the decomposition is lossless with respect to a functional dependency set $F$ if and only if:
   $$(R_1 \cap R_2) \rightarrow R_1 \quad \text{or} \quad (R_1 \cap R_2) \rightarrow R_2$$
   In every step of our decomposition, the common attributes between child relations form a primary key (or candidate key) of at least one of the decomposed relations (e.g., `student_profiles ∩ users = {user_id}`, which is a candidate key of `users`). Therefore, all joins are guaranteed lossless.
2. **Dependency Preservation**:
   Every functional dependency in the original set $F$ can be enforced directly by candidate keys or foreign keys on single relations without requiring cross-relation join queries. Hence, $F' \equiv F$, proving full dependency preservation.

---

## 7. Final Relational Schema Specification

The resulting normalized schema comprises **18 relational tables**, perfectly partitioned into 6 logical sub-domains:

```
[Identity & Profiles]
  ├── users (user_id PK)
  ├── student_profiles (student_id PK, user_id FK UNIQUE)
  └── resumes (resume_id PK, student_id FK)

[Skills & Competencies]
  ├── skills (skill_id PK, slug UNIQUE)
  ├── student_skills (student_id FK, skill_id FK PK)
  ├── projects (project_id PK, student_id FK)
  └── project_skills (project_id FK, skill_id FK PK)

[Opportunities & Requirements]
  ├── companies (company_id PK)
  ├── internships (internship_id PK, company_id FK)
  └── internship_requirements (requirement_id PK, internship_id FK, skill_id FK)

[Intelligence & Diagnostics Engine]
  ├── evaluations (evaluation_id PK, student_id FK, internship_id FK)
  ├── requirement_assessments (assessment_id PK, evaluation_id FK, requirement_id FK)
  └── skill_gaps (gap_id PK, evaluation_id FK, skill_id FK)

[Actionable Preparation]
  ├── bridge_projects (bridge_project_id PK, evaluation_id FK, gap_id FK)
  ├── roadmaps (roadmap_id PK, evaluation_id FK, student_id FK)
  └── roadmap_tasks (task_id PK, roadmap_id FK)

[Application Tracking]
  ├── applications (application_id PK, student_id FK, internship_id FK UNIQUE)
  └── application_activities (activity_id PK, application_id FK)
```

This normalized design guarantees optimal storage efficiency, zero data anomaly risks, complete referential integrity, and peak SQL execution performance.
