CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DROP SCHEMA IF EXISTS pathforge CASCADE;
CREATE SCHEMA pathforge;
SET search_path TO pathforge, public;

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_role VARCHAR(20) NOT NULL CHECK (user_role IN ('STUDENT', 'MENTOR', 'ADMIN')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_profiles (
    student_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    full_name VARCHAR(120) NOT NULL,
    phone VARCHAR(20),
    headline VARCHAR(255),
    bio TEXT,
    target_role VARCHAR(100),
    university VARCHAR(255),
    degree VARCHAR(100),
    graduation_year INT CHECK (graduation_year >= 2000 AND graduation_year <= 2100),
    cgpa NUMERIC(4, 2) CHECK (cgpa >= 0.00 AND cgpa <= 10.00),
    github_username VARCHAR(100),
    portfolio_url VARCHAR(500),
    linkedin_url VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE resumes (
    resume_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(student_id) ON DELETE CASCADE,
    file_url VARCHAR(500) NOT NULL,
    raw_text TEXT,
    parsed_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE skills (
    skill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL CHECK (category IN ('LANGUAGE', 'FRAMEWORK', 'DATABASE', 'TOOL', 'CLOUD', 'CONCEPT', 'OTHER')),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_skills (
    student_id UUID NOT NULL REFERENCES student_profiles(student_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills(skill_id) ON DELETE RESTRICT,
    proficiency VARCHAR(20) NOT NULL CHECK (proficiency IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    verification_source VARCHAR(30) NOT NULL CHECK (verification_source IN ('RESUME', 'GITHUB', 'SELF_REPORTED', 'ASSESSMENT')),
    years_experience NUMERIC(3, 1) NOT NULL DEFAULT 0.0 CHECK (years_experience >= 0.0),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (student_id, skill_id)
);

CREATE TABLE projects (
    project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(student_id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    repo_url VARCHAR(500),
    demo_url VARCHAR(500),
    start_date DATE,
    end_date DATE,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_project_dates CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

CREATE TABLE project_skills (
    project_id UUID NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills(skill_id) ON DELETE RESTRICT,
    PRIMARY KEY (project_id, skill_id)
);

CREATE TABLE companies (
    company_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL UNIQUE,
    website VARCHAR(500),
    logo_url VARCHAR(500),
    industry VARCHAR(100),
    location VARCHAR(150),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE internships (
    internship_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE RESTRICT,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(150) NOT NULL,
    internship_type VARCHAR(20) NOT NULL CHECK (internship_type IN ('REMOTE', 'HYBRID', 'ONSITE')),
    stipend_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (stipend_amount >= 0.00),
    deadline DATE NOT NULL,
    source_url VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('DRAFT', 'ACTIVE', 'EXPIRED', 'CLOSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE internship_requirements (
    requirement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    internship_id UUID NOT NULL REFERENCES internships(internship_id) ON DELETE CASCADE,
    skill_id UUID REFERENCES skills(skill_id) ON DELETE SET NULL,
    requirement_type VARCHAR(20) NOT NULL CHECK (requirement_type IN ('MANDATORY', 'PREFERRED', 'BONUS')),
    weight NUMERIC(3, 2) NOT NULL DEFAULT 1.00 CHECK (weight > 0.00 AND weight <= 5.00),
    min_proficiency VARCHAR(20) NOT NULL DEFAULT 'BEGINNER' CHECK (min_proficiency IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    requirement_text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE evaluations (
    evaluation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(student_id) ON DELETE CASCADE,
    internship_id UUID NOT NULL REFERENCES internships(internship_id) ON DELETE CASCADE,
    compatibility_score NUMERIC(5, 2) NOT NULL CHECK (compatibility_score >= 0.00 AND compatibility_score <= 100.00),
    coverage_pct NUMERIC(5, 2) NOT NULL CHECK (coverage_pct >= 0.00 AND coverage_pct <= 100.00),
    scoring_version VARCHAR(30) NOT NULL DEFAULT 'v1.0.0',
    summary_notes TEXT,
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE requirement_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_id UUID NOT NULL REFERENCES evaluations(evaluation_id) ON DELETE CASCADE,
    requirement_id UUID NOT NULL REFERENCES internship_requirements(requirement_id) ON DELETE CASCADE,
    match_status VARCHAR(30) NOT NULL CHECK (match_status IN ('MATCHED', 'PARTIALLY_MATCHED', 'MISSING', 'NEEDS_VERIFICATION')),
    match_value NUMERIC(3, 2) NOT NULL CHECK (match_value >= 0.00 AND match_value <= 1.00),
    confidence_score NUMERIC(4, 2) NOT NULL CHECK (confidence_score >= 0.00 AND confidence_score <= 1.00),
    evidence_source VARCHAR(30) NOT NULL CHECK (evidence_source IN ('RESUME', 'GITHUB', 'PROJECT', 'PROFILE', 'NONE')),
    evidence_text TEXT,
    explanation TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_eval_requirement UNIQUE (evaluation_id, requirement_id)
);

CREATE TABLE skill_gaps (
    gap_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_id UUID NOT NULL REFERENCES evaluations(evaluation_id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills(skill_id) ON DELETE RESTRICT,
    priority VARCHAR(20) NOT NULL CHECK (priority IN ('CRITICAL', 'IMPORTANT', 'OPTIONAL')),
    reason TEXT NOT NULL,
    suggested_action TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_eval_skill_gap UNIQUE (evaluation_id, skill_id)
);

CREATE TABLE bridge_projects (
    bridge_project_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_id UUID NOT NULL REFERENCES evaluations(evaluation_id) ON DELETE CASCADE,
    gap_id UUID REFERENCES skill_gaps(gap_id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    objective TEXT NOT NULL,
    scope_description TEXT NOT NULL,
    expected_deliverables TEXT NOT NULL,
    estimated_effort_hours INT NOT NULL CHECK (estimated_effort_hours > 0),
    difficulty VARCHAR(20) NOT NULL CHECK (difficulty IN ('EASY', 'MEDIUM', 'HARD')),
    status VARCHAR(20) NOT NULL DEFAULT 'RECOMMENDED' CHECK (status IN ('RECOMMENDED', 'IN_PROGRESS', 'COMPLETED', 'DISMISSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE roadmaps (
    roadmap_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evaluation_id UUID NOT NULL REFERENCES evaluations(evaluation_id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES student_profiles(student_id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    total_days INT NOT NULL DEFAULT 7 CHECK (total_days > 0 AND total_days <= 30),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'ARCHIVED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE roadmap_tasks (
    task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roadmap_id UUID NOT NULL REFERENCES roadmaps(roadmap_id) ON DELETE CASCADE,
    day_number INT NOT NULL CHECK (day_number >= 1 AND day_number <= 30),
    task_order INT NOT NULL DEFAULT 1 CHECK (task_order >= 1),
    title VARCHAR(200) NOT NULL,
    focus_area VARCHAR(200) NOT NULL,
    expected_outcome TEXT NOT NULL,
    estimated_minutes INT NOT NULL DEFAULT 60 CHECK (estimated_minutes > 0),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_roadmap_day_order UNIQUE (roadmap_id, day_number, task_order)
);

CREATE TABLE applications (
    application_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES student_profiles(student_id) ON DELETE CASCADE,
    internship_id UUID NOT NULL REFERENCES internships(internship_id) ON DELETE CASCADE,
    evaluation_id UUID REFERENCES evaluations(evaluation_id) ON DELETE SET NULL,
    current_stage VARCHAR(30) NOT NULL DEFAULT 'SAVED' CHECK (current_stage IN ('SAVED', 'RESEARCHING', 'PREPARING', 'READY_TO_APPLY', 'APPLIED', 'ASSESSMENT', 'INTERVIEW', 'OFFER', 'REJECTED', 'WITHDRAWN')),
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH')),
    applied_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_student_internship_app UNIQUE (student_id, internship_id)
);

CREATE TABLE application_activities (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES applications(application_id) ON DELETE CASCADE,
    activity_type VARCHAR(30) NOT NULL CHECK (activity_type IN ('STAGE_CHANGE', 'NOTE_ADDED', 'INTERVIEW_SCHEDULED', 'DEADLINE_ALERT', 'OFFER_RECEIVED')),
    old_stage VARCHAR(30),
    new_stage VARCHAR(30),
    notes TEXT,
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_student_profiles_user ON student_profiles(user_id);
CREATE INDEX idx_resumes_student_active ON resumes(student_id, is_active);
CREATE INDEX idx_skills_category ON skills(category);
CREATE INDEX idx_student_skills_skill ON student_skills(skill_id);
CREATE INDEX idx_projects_student ON projects(student_id);
CREATE INDEX idx_project_skills_skill ON project_skills(skill_id);
CREATE INDEX idx_internships_company ON internships(company_id);
CREATE INDEX idx_internships_status_deadline ON internships(status, deadline);
CREATE INDEX idx_internship_reqs_internship ON internship_requirements(internship_id);
CREATE INDEX idx_internship_reqs_skill ON internship_requirements(skill_id);
CREATE INDEX idx_evaluations_student_internship ON evaluations(student_id, internship_id);
CREATE INDEX idx_req_assessments_eval ON requirement_assessments(evaluation_id);
CREATE INDEX idx_req_assessments_status ON requirement_assessments(match_status);
CREATE INDEX idx_skill_gaps_eval ON skill_gaps(evaluation_id);
CREATE INDEX idx_skill_gaps_priority ON skill_gaps(priority);
CREATE INDEX idx_bridge_projects_eval ON bridge_projects(evaluation_id);
CREATE INDEX idx_roadmaps_student ON roadmaps(student_id);
CREATE INDEX idx_roadmaps_eval ON roadmaps(evaluation_id);
CREATE INDEX idx_roadmap_tasks_roadmap ON roadmap_tasks(roadmap_id, day_number);
CREATE INDEX idx_applications_student ON applications(student_id);
CREATE INDEX idx_applications_internship ON applications(internship_id);
CREATE INDEX idx_applications_stage ON applications(current_stage);
CREATE INDEX idx_app_activities_app ON application_activities(application_id, event_timestamp DESC);

