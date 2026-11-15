# PathForge Entity-Relationship (ER) Diagram & Data Dictionary

## 1. Overview & Architectural Domains

The PathForge relational database schema is structured into 6 interconnected functional domains comprising 18 tables:
1. **Identity & Authentication**: `users`, `student_profiles`, `resumes`
2. **Skills & Competency Taxonomy**: `skills`, `student_skills`, `projects`, `project_skills`
3. **Internship Opportunities**: `companies`, `internships`, `internship_requirements`
4. **Compatibility Engine & Diagnostics**: `evaluations`, `requirement_assessments`, `skill_gaps`
5. **Actionable Preparation**: `bridge_projects`, `roadmaps`, `roadmap_tasks`
6. **Application Tracking**: `applications`, `application_activities`

---

## 2. Mermaid Entity-Relationship Diagram

```mermaid
erDiagram
    users ||--|| student_profiles : "1:1 owns profile"
    student_profiles ||--o{ resumes : "1:N uploads"
    student_profiles ||--o{ student_skills : "1:N possesses"
    skills ||--o{ student_skills : "1:N assigned to"
    student_profiles ||--o{ projects : "1:N develops"
    projects ||--o{ project_skills : "1:N showcases"
    skills ||--o{ project_skills : "1:N tagged in"

    companies ||--o{ internships : "1:N offers"
    internships ||--o{ internship_requirements : "1:N defines"
    skills ||--o{ internship_requirements : "1:N required by"

    student_profiles ||--o{ evaluations : "1:N evaluated in"
    internships ||--o{ evaluations : "1:N evaluated against"
    evaluations ||--o{ requirement_assessments : "1:N produces"
    internship_requirements ||--o{ requirement_assessments : "1:N assessed in"
    evaluations ||--o{ skill_gaps : "1:N diagnoses"
    skills ||--o{ skill_gaps : "1:N missing"

    evaluations ||--o{ bridge_projects : "1:N recommends"
    skill_gaps ||--o{ bridge_projects : "0..1:N resolves"
    evaluations ||--o{ roadmaps : "1:N generates"
    student_profiles ||--o{ roadmaps : "1:N follows"
    roadmaps ||--o{ roadmap_tasks : "1:N contains"

    student_profiles ||--o{ applications : "1:N submits"
    internships ||--o{ applications : "1:N receives"
    evaluations ||--o{ applications : "0..1:N informs"
    applications ||--o{ application_activities : "1:N logs"

    users {
        uuid user_id PK
        varchar email UK
        varchar password_hash
        varchar user_role
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    student_profiles {
        uuid student_id PK
        uuid user_id FK,UK
        varchar full_name
        varchar phone
        varchar headline
        text bio
        varchar target_role
        varchar university
        varchar degree
        int graduation_year
        numeric cgpa
        varchar github_username
        varchar portfolio_url
        varchar linkedin_url
        timestamptz created_at
        timestamptz updated_at
    }

    resumes {
        uuid resume_id PK
        uuid student_id FK
        varchar file_url
        text raw_text
        jsonb parsed_data
        boolean is_active
        timestamptz uploaded_at
    }

    skills {
        uuid skill_id PK
        varchar name UK
        varchar slug UK
        varchar category
        text description
        timestamptz created_at
    }

    student_skills {
        uuid student_id PK,FK
        uuid skill_id PK,FK
        varchar proficiency
        varchar verification_source
        numeric years_experience
        boolean is_verified
        timestamptz created_at
    }

    projects {
        uuid project_id PK
        uuid student_id FK
        varchar title
        text description
        varchar repo_url
        varchar demo_url
        date start_date
        date end_date
        boolean is_featured
        timestamptz created_at
    }

    project_skills {
        uuid project_id PK,FK
        uuid skill_id PK,FK
    }

    companies {
        uuid company_id PK
        varchar name UK
        varchar website
        varchar logo_url
        varchar industry
        varchar location
        timestamptz created_at
    }

    internships {
        uuid internship_id PK
        uuid company_id FK
        varchar title
        text description
        varchar location
        varchar internship_type
        numeric stipend_amount
        date deadline
        varchar source_url
        varchar status
        timestamptz created_at
        timestamptz updated_at
    }

    internship_requirements {
        uuid requirement_id PK
        uuid internship_id FK
        uuid skill_id FK
        varchar requirement_type
        numeric weight
        varchar min_proficiency
        text requirement_text
        timestamptz created_at
    }

    evaluations {
        uuid evaluation_id PK
        uuid student_id FK
        uuid internship_id FK
        numeric compatibility_score
        numeric coverage_pct
        varchar scoring_version
        text summary_notes
        timestamptz evaluated_at
    }

    requirement_assessments {
        uuid assessment_id PK
        uuid evaluation_id FK
        uuid requirement_id FK
        varchar match_status
        numeric match_value
        numeric confidence_score
        varchar evidence_source
        text evidence_text
        text explanation
        timestamptz created_at
    }

    skill_gaps {
        uuid gap_id PK
        uuid evaluation_id FK
        uuid skill_id FK
        varchar priority
        text reason
        suggested_action text
        timestamptz created_at
    }

    bridge_projects {
        uuid bridge_project_id PK
        uuid evaluation_id FK
        uuid gap_id FK
        varchar title
        text objective
        text scope_description
        text expected_deliverables
        int estimated_effort_hours
        varchar difficulty
        varchar status
        timestamptz created_at
    }

    roadmaps {
        uuid roadmap_id PK
        uuid evaluation_id FK
        uuid student_id FK
        varchar title
        int total_days
        varchar status
        timestamptz created_at
        timestamptz updated_at
    }

    roadmap_tasks {
        uuid task_id PK
        uuid roadmap_id FK
        int day_number
        int task_order
        varchar title
        varchar focus_area
        text expected_outcome
        int estimated_minutes
        boolean is_completed
        timestamptz completed_at
        timestamptz created_at
    }

    applications {
        uuid application_id PK
        uuid student_id FK
        uuid internship_id FK
        uuid evaluation_id FK
        varchar current_stage
        varchar priority
        date applied_date
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    application_activities {
        uuid activity_id PK
        uuid application_id FK
        varchar activity_type
        varchar old_stage
        varchar new_stage
        text notes
        timestamptz event_timestamp
    }
```

---

## 3. Detailed Data Dictionary

### 3.1 Entity Cardinalities & Foreign Key Relationships

| Parent Entity | Relationship | Child Entity | Cardinality | Foreign Key Column | On Delete Action |
| :--- | :---: | :--- | :---: | :--- | :--- |
| `users` | 1:1 | `student_profiles` | One to Exactly One | `student_profiles.user_id` | `CASCADE` |
| `student_profiles` | 1:N | `resumes` | One to Zero-or-Many | `resumes.student_id` | `CASCADE` |
| `student_profiles` | M:N | `skills` (via `student_skills`) | Many to Many | `student_skills.student_id` | `CASCADE` |
| `skills` | M:N | `student_profiles` | Many to Many | `student_skills.skill_id` | `RESTRICT` |
| `student_profiles` | 1:N | `projects` | One to Zero-or-Many | `projects.student_id` | `CASCADE` |
| `projects` | M:N | `skills` (via `project_skills`) | Many to Many | `project_skills.project_id` | `CASCADE` |
| `skills` | M:N | `projects` | Many to Many | `project_skills.skill_id` | `RESTRICT` |
| `companies` | 1:N | `internships` | One to Zero-or-Many | `internships.company_id` | `RESTRICT` |
| `internships` | 1:N | `internship_requirements` | One to One-or-Many | `internship_requirements.internship_id` | `CASCADE` |
| `skills` | 1:N | `internship_requirements` | One to Zero-or-Many | `internship_requirements.skill_id` | `SET NULL` |
| `student_profiles` | 1:N | `evaluations` | One to Zero-or-Many | `evaluations.student_id` | `CASCADE` |
| `internships` | 1:N | `evaluations` | One to Zero-or-Many | `evaluations.internship_id` | `CASCADE` |
| `evaluations` | 1:N | `requirement_assessments` | One to One-or-Many | `requirement_assessments.evaluation_id` | `CASCADE` |
| `internship_requirements`| 1:N | `requirement_assessments` | One to Zero-or-Many | `requirement_assessments.requirement_id` | `CASCADE` |
| `evaluations` | 1:N | `skill_gaps` | One to Zero-or-Many | `skill_gaps.evaluation_id` | `CASCADE` |
| `skills` | 1:N | `skill_gaps` | One to Zero-or-Many | `skill_gaps.skill_id` | `RESTRICT` |
| `evaluations` | 1:N | `bridge_projects` | One to Zero-or-Many | `bridge_projects.evaluation_id` | `CASCADE` |
| `skill_gaps` | 1:N | `bridge_projects` | Zero-or-One to Many | `bridge_projects.gap_id` | `SET NULL` |
| `evaluations` | 1:N | `roadmaps` | One to Zero-or-Many | `roadmaps.evaluation_id` | `CASCADE` |
| `student_profiles` | 1:N | `roadmaps` | One to Zero-or-Many | `roadmaps.student_id` | `CASCADE` |
| `roadmaps` | 1:N | `roadmap_tasks` | One to Exactly 7 | `roadmap_tasks.roadmap_id` | `CASCADE` |
| `student_profiles` | 1:N | `applications` | One to Zero-or-Many | `applications.student_id` | `CASCADE` |
| `internships` | 1:N | `applications` | One to Zero-or-Many | `applications.internship_id` | `CASCADE` |
| `evaluations` | 1:N | `applications` | Zero-or-One to Many | `applications.evaluation_id` | `SET NULL` |
| `applications` | 1:N | `application_activities` | One to One-or-Many | `application_activities.application_id` | `CASCADE` |

---

## 4. Entity Attribute Constraints & Domain Rules

1. **User Authentication (`users`)**:
   - `email`: Enforces format consistency, guaranteed unique across the platform.
   - `user_role`: Restricts authorization scope to `STUDENT`, `MENTOR`, or `ADMIN`.
2. **Student Profile (`student_profiles`)**:
   - `user_id`: Unique foreign key enforcing strict 1:1 relationship with `users`.
   - `cgpa`: Constrained between $0.00$ and $10.00$.
   - `graduation_year`: Constrained between $2000$ and $2100$.
3. **Requirement Assessment (`requirement_assessments`)**:
   - `match_status`: Discriminates between `MATCHED`, `PARTIALLY_MATCHED`, `MISSING`, `NEEDS_VERIFICATION`.
   - `match_value`: Quantified contribution ($1.00$ for matched, $0.50$ for partial, $0.00$ for missing).
   - Composite uniqueness constraint: `UNIQUE (evaluation_id, requirement_id)` prevents duplicate assessments.
4. **Roadmap Structure (`roadmap_tasks`)**:
   - `day_number`: Constrained between $1$ and $30$ (standard default 7-day preparation sprint).
   - `task_order`: Sequential task index per day.
   - Composite uniqueness: `UNIQUE (roadmap_id, day_number, task_order)`.
5. **Application Lifecycle (`applications`)**:
   - `current_stage`: Strict state machine (`SAVED` → `RESEARCHING` → `PREPARING` → `READY_TO_APPLY` → `APPLIED` → `ASSESSMENT` → `INTERVIEW` → `OFFER` / `REJECTED` / `WITHDRAWN`).
   - `UNIQUE (student_id, internship_id)`: A student cannot duplicate active tracking entries for the same opportunity.

