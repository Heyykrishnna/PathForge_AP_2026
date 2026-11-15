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
